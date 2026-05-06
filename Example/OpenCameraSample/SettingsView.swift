import OpenCamera
import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: CameraViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Photo") {
                    Picker("Format", selection: $model.settings.photoFormat) {
                        ForEach(CameraSettings.photoFormats, id: \.0) { item in
                            Text(item.1).tag(item.0)
                        }
                    }
                    Toggle("Live Photos", isOn: $model.settings.enableLivePhotos)
                    Toggle("Depth data", isOn: $model.settings.enableDepthData)
                    Toggle("Portrait matte", isOn: $model.settings.enablePortraitMatte)
                }

                Section("Video") {
                    Picker("Codec", selection: $model.settings.videoCodec) {
                        ForEach(CameraSettings.codecOptions, id: \.0) { item in
                            Text(item.1).tag(item.0)
                        }
                    }
                    Picker("Resolution", selection: $model.settings.sessionPreset) {
                        ForEach(CameraSettings.presetOptions, id: \.0) { item in
                            Text(item.1).tag(item.0)
                        }
                    }
                    Picker("Frame rate", selection: $model.settings.frameRate) {
                        ForEach(CameraSettings.frameRateOptions, id: \.self) { fps in
                            Text("\(fps) fps").tag(fps)
                        }
                    }
                    Picker("Stabilization", selection: $model.settings.stabilization) {
                        ForEach(CameraSettings.stabilizationOptions, id: \.0) { item in
                            Text(item.1).tag(item.0)
                        }
                    }
                    Toggle("Audio", isOn: $model.settings.enableAudio)
                    Toggle("Convert to MP4", isOn: $model.settings.convertVideoToMP4)
                }

                Section("Image") {
                    Toggle("HDR", isOn: $model.settings.enableHDR)
                }

                Section {
                    Button {
                        Task {
                            await model.applySettings()
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Apply").bold()
                            Spacer()
                        }
                    }
                    .tint(.yellow)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
