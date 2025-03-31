import SwiftUI

struct ControllerStatusView: View {
    @ObservedObject var controllerManager: ControllerManager

    var body: some View {
        VStack {
            HStack {
                Text("Last Button Pressed:")
                VStack {
                    Image(systemName: buttonIcon(for: controllerManager.lastButtonPressed))
                        .font(.largeTitle)
                        .foregroundColor(.blue)
                    Text(controllerManager.lastButtonPressed)
                        .font(.headline)
                        .foregroundColor(.primary)
                    if let duration = controllerManager.currentButtonDuration {
                        Text("Duration: \(String(format: "%.2f", duration))s")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Duration: 0.00s") // Placeholder to prevent jittering
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()

            VStack(alignment: .leading) {
                Text("Currently Pressed:")
                    .font(.headline)
                ZStack {
                    if controllerManager.currentPressedButtons.isEmpty {
                        Text("None")
                            .foregroundColor(.secondary)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(Array(controllerManager.currentPressedButtons).sorted(), id: \.self) { button in
                                    HStack {
                                        Image(systemName: buttonIcon(for: button))
                                            .foregroundColor(.blue)
                                        Text(button)
                                            .padding(.trailing, 4)
                                    }
                                    .padding(6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.blue.opacity(0.1))
                                    )
                                }
                            }
                        }
                    }
                }
                .frame(height: 40)
            }
            .padding(.horizontal)
        }
    }

    private func buttonIcon(for button: String) -> String {
        controllerManager.buttonState[button] ?? "questionmark.circle.fill"
    }
}
