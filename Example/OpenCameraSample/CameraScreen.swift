import OpenCamera
import SwiftUI

struct CameraScreen: View {
    @ObservedObject var model: CameraViewModel
    @State private var showManualPanel = false
    @State private var showFilters = true
    @State private var showSettings = false
    @State private var showGallery = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                preview(in: geo.size)
                    .ignoresSafeArea()

                if let point = model.focusIndicator {
                    FocusReticle()
                        .position(point)
                        .allowsHitTesting(false)
                }

                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal)
                        .padding(.top, 8)

                    if model.isRecording {
                        recordingPill
                            .padding(.top, 8)
                    }

                    Spacer()

                    VStack(spacing: 14) {
                        if showManualPanel {
                            ManualControlsView(model: model)
                                .padding(.horizontal)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        if showFilters {
                            FilterPickerView(model: model)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        bottomBar
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                    }
                    .background(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.5)],
                            startPoint: .top, endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    )
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(model: model)
        }
        .sheet(isPresented: $showGallery) {
            GalleryView(model: model)
        }
        .alert("Camera error", isPresented: errorBinding) {
            Button("OK") { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )
    }

    @ViewBuilder
    private func preview(in size: CGSize) -> some View {
        ZStack {
            CameraPreview(
                session: model.session,
                videoGravity: .resizeAspectFill,
                onTapToFocus: { tap in
                    model.handleTapToFocus(tap.devicePoint, viewPoint: tap.viewPoint)
                },
                onPinchZoom: { scale in
                    model.handlePinchZoom(scale)
                }
            )

            if model.hasActiveFilter {
                FilteredCameraPreview(session: model.session)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            CircleButton(systemName: flashIcon, tint: model.flashMode == .on ? .yellow : .white) {
                model.toggleFlash()
            }
            CircleButton(systemName: model.torchOn ? "flashlight.on.fill" : "flashlight.off.fill",
                         tint: model.torchOn ? .yellow : .white) {
                model.toggleTorch()
            }
            Spacer()
            Text(String(format: "%.1f×", model.zoom))
                .font(.callout.weight(.semibold).monospacedDigit())
                .foregroundStyle(.white)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
            Spacer()
            CircleButton(systemName: "slider.horizontal.3",
                         tint: showManualPanel ? .yellow : .white) {
                withAnimation(.spring(response: 0.35)) { showManualPanel.toggle() }
            }
            CircleButton(systemName: "gearshape.fill", tint: .white) {
                showSettings = true
            }
        }
    }

    private var recordingPill: some View {
        HStack(spacing: 8) {
            Circle().fill(.red).frame(width: 10, height: 10)
                .opacity(model.recordingDuration.truncatingRemainder(dividingBy: 1) > 0.5 ? 1 : 0.4)
            Text(formatDuration(model.recordingDuration))
                .font(.callout.monospacedDigit().weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.red.opacity(0.6), lineWidth: 1))
    }

    private var bottomBar: some View {
        VStack(spacing: 14) {
            if !model.availableLenses.isEmpty {
                LensPicker(model: model)
            }
            HStack(spacing: 24) {
                galleryThumbnail
                Spacer()
                shutterButton
                Spacer()
                CircleButton(systemName: "arrow.triangle.2.circlepath.camera", tint: .white) {
                    Task { await model.switchCamera() }
                }
            }
            modeSelector
        }
    }

    private var modeSelector: some View {
        HStack(spacing: 28) {
            ForEach([CameraMode.photo, CameraMode.video], id: \.self) { value in
                Button {
                    Task {
                        if model.mode != value { await model.toggleMode() }
                    }
                } label: {
                    Text(label(for: value))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(model.mode == value ? .yellow : .white.opacity(0.7))
                        .padding(.vertical, 4)
                        .overlay(alignment: .bottom) {
                            if model.mode == value {
                                Circle().fill(.yellow).frame(width: 4, height: 4).offset(y: 4)
                            }
                        }
                }
            }
            Button {
                withAnimation(.spring(response: 0.35)) { showFilters.toggle() }
            } label: {
                Text("FILTERS")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(showFilters ? .yellow : .white.opacity(0.7))
                    .padding(.vertical, 4)
            }
        }
    }

    private var shutterButton: some View {
        Button {
            Task {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                if model.mode == .photo {
                    await model.capturePhoto()
                } else {
                    await model.toggleRecording()
                }
            }
        } label: {
            ZStack {
                Circle().stroke(.white, lineWidth: 4).frame(width: 78, height: 78)
                if model.mode == .video && model.isRecording {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.red)
                        .frame(width: 30, height: 30)
                } else {
                    Circle()
                        .fill(model.mode == .video ? Color.red : Color.white)
                        .frame(width: 64, height: 64)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: model.isRecording)
        }
    }

    private var galleryThumbnail: some View {
        Button {
            showGallery = true
        } label: {
            ZStack {
                if let image = model.captures.first?.thumbnail {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white, lineWidth: 1.5))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: "photo.on.rectangle")
                                .foregroundStyle(.white.opacity(0.7))
                        )
                }
                if model.captures.count > 1 {
                    Text("\(model.captures.count)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(.yellow, in: Capsule())
                        .offset(x: 22, y: -22)
                }
            }
        }
    }

    private var flashIcon: String {
        switch model.flashMode {
        case .auto: return "bolt.badge.a.fill"
        case .on: return "bolt.fill"
        case .off: return "bolt.slash.fill"
        }
    }

    private func label(for mode: CameraMode) -> String {
        switch mode {
        case .photo: return "PHOTO"
        case .video: return "VIDEO"
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let total = Int(duration)
        let minutes = total / 60
        let seconds = total % 60
        let tenths = Int((duration - Double(total)) * 10)
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }
}

private struct CircleButton: View {
    let systemName: String
    var tint: Color = .white
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial, in: Circle())
        }
    }
}

private struct FocusReticle: View {
    @State private var animate = false
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .stroke(.yellow, lineWidth: 1.5)
            .frame(width: 70, height: 70)
            .scaleEffect(animate ? 1.0 : 1.4)
            .opacity(animate ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.25)) { animate = true }
            }
    }
}

private struct LensPicker: View {
    @ObservedObject var model: CameraViewModel

    var body: some View {
        HStack(spacing: 8) {
            ForEach(model.availableLenses, id: \.self) { lens in
                Button {
                    Task { await model.setLens(lens) }
                } label: {
                    Text(label(for: lens))
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private func label(for lens: CameraLens) -> String {
        switch lens {
        case .ultraWide: return ".5×"
        case .wide: return "1×"
        case .telephoto: return "3×"
        case .dual: return "DUAL"
        case .dualWide: return "DUAL-W"
        case .triple: return "TRI"
        case .trueDepth: return "TD"
        }
    }
}
