import OpenCamera
import SwiftUI

struct FilterPickerView: View {
    @ObservedObject var model: CameraViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(model.availableFilters.enumerated()), id: \.offset) { index, filter in
                    Button {
                        model.setSelectedFilter(index)
                    } label: {
                        Text(filter.name)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(model.selectedFilterIndex == index ? Color.yellow : Color.white.opacity(0.2),
                                        in: Capsule())
                            .foregroundStyle(model.selectedFilterIndex == index ? .black : .white)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
