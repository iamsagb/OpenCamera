import OpenCamera
import SwiftUI

struct ManualControlsView: View {
    @ObservedObject var model: CameraViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Manual mode", isOn: Binding(
                get: { model.manualMode },
                set: { model.setManualMode($0) }
            ))
            .tint(.yellow)

            slider(label: "Exposure bias",
                   value: Binding(get: { model.exposureBias },
                                  set: { model.setExposureBias($0) }),
                   range: -3...3,
                   format: "%.1f EV")

            if model.manualMode {
                slider(label: "ISO",
                       value: Binding(get: { model.iso },
                                      set: { model.iso = $0; model.applyManualValues() }),
                       range: 25...3200,
                       format: "%.0f")

                slider(label: "Shutter (ms)",
                       value: Binding(get: { model.exposureDurationMillis },
                                      set: { model.exposureDurationMillis = $0; model.applyManualValues() }),
                       range: 1...500,
                       format: "%.0f ms")

                slider(label: "WB Temp",
                       value: Binding(get: { model.whiteBalanceTemperature },
                                      set: { model.whiteBalanceTemperature = $0; model.applyManualValues() }),
                       range: 2500...8000,
                       format: "%.0f K")

                slider(label: "WB Tint",
                       value: Binding(get: { model.whiteBalanceTint },
                                      set: { model.whiteBalanceTint = $0; model.applyManualValues() }),
                       range: -150...150,
                       format: "%.0f")
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .foregroundStyle(.white)
    }

    private func slider(label: String, value: Binding<Float>, range: ClosedRange<Float>, format: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label).font(.caption.weight(.medium))
                Spacer()
                Text(String(format: format, value.wrappedValue)).font(.caption.monospaced())
            }
            Slider(value: value, in: range)
                .tint(.yellow)
        }
    }
}
