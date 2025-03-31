import SwiftUI

struct ControllerLayoutView: View {
    @ObservedObject var controllerManager: ControllerManager

    var body: some View {
        VStack {
            // 肩部按键布局
            HStack {
                Image(systemName: controllerManager.shoulderButtonState["L2"] ?? "l2.button.roundedtop.horizontal")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                Spacer()
                Image(systemName: controllerManager.shoulderButtonState["R2"] ?? "r2.button.roundedtop.horizontal")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
            }
            HStack {
                Image(systemName: controllerManager.shoulderButtonState["L1"] ?? "l1.button.roundedbottom.horizontal")
                    .font(.system(size: 40))
                    .foregroundColor(.purple)
                Spacer()
                Image(systemName: controllerManager.shoulderButtonState["R1"] ?? "r1.button.roundedbottom.horizontal")
                    .font(.system(size: 40))
                    .foregroundColor(.purple)
            }
            Divider()
            // D-Pad 和按键布局
            HStack {
                Image(systemName: controllerManager.dpadState)
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                Spacer()
                ZStack {
                    Image(systemName: controllerManager.buttonState["Y"] ?? "circle")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                        .offset(y: -40)
                    Image(systemName: controllerManager.buttonState["X"] ?? "circle")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                        .offset(x: -35)
                    Image(systemName: controllerManager.buttonState["B"] ?? "circle")
                        .font(.system(size: 40))
                        .foregroundColor(.yellow)
                        .offset(x: 40) // Slightly increased offset for better visibility
                    Image(systemName: controllerManager.buttonState["A"] ?? "circle")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                        .offset(y: 40)
                }
                .padding(.trailing, 40) // Increased padding to prevent clipping
                .frame(maxWidth: .infinity, alignment: .trailing) // Align the group to the right
            }
            Divider()
            // 摇杆显示
            HStack(spacing: 40) {
                ThumbstickView(position: controllerManager.leftThumbstickPosition, label: "L", color: .blue)
                ThumbstickView(position: controllerManager.rightThumbstickPosition, label: "R", color: .red)
            }
            .padding()
        }
    }
}

struct ThumbstickView: View {
    let position: CGPoint
    let label: String
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 2)
                .frame(width: 80, height: 80)
                .foregroundColor(.gray)
            Circle()
                .frame(width: 30, height: 30)
                .foregroundColor(color)
                .offset(x: position.x * 25, y: position.y * 25)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .offset(y: 45)
            VStack {
                Text("x: \(String(format: "%.2f", position.x))")
                Text("y: \(String(format: "%.2f", position.y))")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .offset(y: -45)
        }
    }
}
