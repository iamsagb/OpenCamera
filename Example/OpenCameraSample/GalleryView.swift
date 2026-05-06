import AVKit
import SwiftUI

struct GalleryView: View {
    @ObservedObject var model: CameraViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selected: CapturedItem?

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 4)]

    var body: some View {
        NavigationStack {
            Group {
                if model.captures.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 64))
                            .foregroundStyle(.tertiary)
                        Text("No captures yet")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 4) {
                            ForEach(model.captures) { item in
                                Button {
                                    selected = item
                                } label: {
                                    GalleryThumb(item: item)
                                }
                            }
                        }
                        .padding(4)
                    }
                }
            }
            .navigationTitle("Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .fullScreenCover(item: $selected) { item in
            MediaPreviewView(item: item)
        }
    }
}

private struct GalleryThumb: View {
    let item: CapturedItem

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if let image = item.thumbnail {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 110)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 110)
            }
            if item.isVideo {
                Image(systemName: "play.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(.black.opacity(0.4), in: Circle())
                    .padding(6)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct MediaPreviewView: View {
    let item: CapturedItem
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch item.media {
            case .photo(let image):
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { scale = max(1, min(5, $0)) }
                            .onEnded { _ in withAnimation(.spring()) { scale = 1 } }
                    )
            case .video(let url):
                VideoPlayer(player: AVPlayer(url: url))
                    .ignoresSafeArea()
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                Spacer()
                infoBar
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }

    private var infoBar: some View {
        HStack {
            Image(systemName: item.isVideo ? "video.fill" : "photo.fill")
            Text(item.date, style: .time)
            Spacer()
            if case .video(let url) = item.media {
                Text(url.pathExtension.uppercased())
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
            }
        }
        .font(.subheadline)
        .foregroundStyle(.white)
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
