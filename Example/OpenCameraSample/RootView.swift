import SwiftUI
import OpenCamera

struct RootView: View {
    @StateObject private var model = CameraViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if model.isReady {
                CameraScreen(model: model)
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Preparing camera…")
                        .foregroundStyle(.secondary)
                    if let error = model.errorMessage {
                        Text(error).foregroundStyle(.red).multilineTextAlignment(.center).padding()
                    }
                }
            }
        }
        .task {
            await model.prepare()
        }
    }
}
