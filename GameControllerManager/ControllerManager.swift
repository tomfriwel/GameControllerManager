import SwiftUI
import GameController

class ControllerManager: ObservableObject {
    @Published var connectedController: GCController?
    @Published var lastButtonPressed: String = "None"
    @Published var buttonHistory: [(button: String, timestamp: Date, duration: TimeInterval?)] = []
    @Published var buttonPressStartTimes: [String: Date] = [:]
    @Published var currentButtonDuration: TimeInterval? = nil
    @Published var dpadState: String = "dpad"
    @Published var buttonState: [String: String] = [
        "A": "circle",
        "B": "circle",
        "X": "circle",
        "Y": "circle"
    ]
    @Published var shoulderButtonState: [String: String] = [
        "L1": "l1.button.roundedbottom.horizontal",
        "R1": "r1.button.roundedbottom.horizontal",
        "L2": "l2.button.roundedtop.horizontal",
        "R2": "r2.button.roundedtop.horizontal"
    ]
    @Published var leftThumbstickPosition: CGPoint = .zero
    @Published var rightThumbstickPosition: CGPoint = .zero
    @Published var currentPressedButtons: Set<String> = []
    @Published var thumbstickPressed: [String: Bool] = [
        "L": false,
        "R": false
    ]
    @Published var supportedButtons: [String] = [] // 新增属性

    private var timer: Timer?

    func setupGameController() {
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self, let controller = notification.object as? GCController else { return }
            self.connectedController = controller
            self.setupControllerInput(controller)
        }

        NotificationCenter.default.addObserver(
            forName: .GCControllerDidDisconnect,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.connectedController = nil
            self?.lastButtonPressed = "None"
        }

        if let controller = GCController.controllers().first {
            connectedController = controller
            setupControllerInput(controller)
        }
    }

    func setupControllerInput(_ controller: GCController) {
        controller.extendedGamepad?.valueChangedHandler = { [weak self] gamepad, element in
            guard let self = self else { return }
            self.leftThumbstickPosition = CGPoint(
                x: CGFloat(gamepad.leftThumbstick.xAxis.value),
                y: -CGFloat(gamepad.leftThumbstick.yAxis.value)
            )
            self.rightThumbstickPosition = CGPoint(
                x: CGFloat(gamepad.rightThumbstick.xAxis.value),
                y: -CGFloat(gamepad.rightThumbstick.yAxis.value)
            )
            // Handle thumbstick press
            self.thumbstickPressed["L"] = gamepad.leftThumbstickButton?.isPressed ?? false
            self.thumbstickPressed["R"] = gamepad.rightThumbstickButton?.isPressed ?? false
            // 按键和D-Pad处理逻辑
            if let button = element as? GCControllerButtonInput {
                let buttonName = self.buttonName(for: button, in: gamepad)
                if button.isPressed {
                    self.lastButtonPressed = buttonName
                    self.startTrackingButtonPress(buttonName)
                    self.startTimer(for: buttonName)
                    self.updateButtonState(buttonName, isPressed: true)
                    self.currentPressedButtons.insert(buttonName)
                } else {
                    if self.lastButtonPressed == buttonName {
                        self.lastButtonPressed = "None"
                    }
                    self.stopTrackingButtonPress(buttonName)
                    if self.currentPressedButtons.contains(buttonName) {
                        self.currentPressedButtons.remove(buttonName)
                    }
                    self.updateButtonState(buttonName, isPressed: false)
                    if self.lastButtonPressed == "None" {
                        self.stopTimer()
                    }
                }
            } else if let dpad = element as? GCControllerDirectionPad {
                if dpad == gamepad.dpad {
                    self.handleDPadInput(dpad)
                }
            }
        }
        fetchSupportedButtons(for: controller) // 初始化支持的按键列表
    }

    private func fetchSupportedButtons(for controller: GCController) {
        supportedButtons.removeAll()
        if let gamepad = controller.extendedGamepad {
            if gamepad.buttonA != nil { supportedButtons.append("Button A") }
            if gamepad.buttonB != nil { supportedButtons.append("Button B") }
            if gamepad.buttonX != nil { supportedButtons.append("Button X") }
            if gamepad.buttonY != nil { supportedButtons.append("Button Y") }
            if gamepad.leftShoulder != nil { supportedButtons.append("Left Shoulder") }
            if gamepad.rightShoulder != nil { supportedButtons.append("Right Shoulder") }
            if gamepad.leftTrigger != nil { supportedButtons.append("Left Trigger") }
            if gamepad.rightTrigger != nil { supportedButtons.append("Right Trigger") }
            if gamepad.leftThumbstickButton != nil { supportedButtons.append("Left Thumbstick") }
            if gamepad.rightThumbstickButton != nil { supportedButtons.append("Right Thumbstick") }
            if gamepad.dpad != nil {
                supportedButtons.append(contentsOf: ["D-Pad Up", "D-Pad Down", "D-Pad Left", "D-Pad Right"])
            }
            if gamepad.buttonOptions != nil { supportedButtons.append("Options Button") }
            if gamepad.buttonMenu != nil { supportedButtons.append("PS Button") }
            if gamepad.buttonHome != nil { supportedButtons.append("Create Button") }
        }
    }

    private func handleDPadInput(_ dpad: GCControllerDirectionPad) {
        if dpad.up.isPressed {
            self.lastButtonPressed = "D-Pad Up"
            self.startTrackingButtonPress("D-Pad Up")
            self.startTimer(for: "D-Pad Up")
            self.dpadState = "dpad.up.filled"
            self.currentPressedButtons.insert("D-Pad Up")
        } else if dpad.up.value == 0 && currentPressedButtons.contains("D-Pad Up") {
            self.stopTrackingButtonPress("D-Pad Up")
            self.currentPressedButtons.remove("D-Pad Up")
            if self.lastButtonPressed == "D-Pad Up" {
                self.lastButtonPressed = "None"
                self.stopTimer()
            }
        }

        if dpad.down.isPressed {
            self.lastButtonPressed = "D-Pad Down"
            self.startTrackingButtonPress("D-Pad Down")
            self.startTimer(for: "D-Pad Down")
            self.dpadState = "dpad.down.filled"
            self.currentPressedButtons.insert("D-Pad Down")
        } else if dpad.down.value == 0 && currentPressedButtons.contains("D-Pad Down") {
            self.stopTrackingButtonPress("D-Pad Down")
            self.currentPressedButtons.remove("D-Pad Down")
            if self.lastButtonPressed == "D-Pad Down" {
                self.lastButtonPressed = "None"
                self.stopTimer()
            }
        }

        if dpad.left.isPressed {
            self.lastButtonPressed = "D-Pad Left"
            self.startTrackingButtonPress("D-Pad Left")
            self.startTimer(for: "D-Pad Left")
            self.dpadState = "dpad.left.filled"
            self.currentPressedButtons.insert("D-Pad Left")
        } else if dpad.left.value == 0 && currentPressedButtons.contains("D-Pad Left") {
            self.stopTrackingButtonPress("D-Pad Left")
            self.currentPressedButtons.remove("D-Pad Left")
            if self.lastButtonPressed == "D-Pad Left" {
                self.lastButtonPressed = "None"
                self.stopTimer()
            }
        }

        if dpad.right.isPressed {
            self.lastButtonPressed = "D-Pad Right"
            self.startTrackingButtonPress("D-Pad Right")
            self.startTimer(for: "D-Pad Right")
            self.dpadState = "dpad.right.filled"
            self.currentPressedButtons.insert("D-Pad Right")
        } else if dpad.right.value == 0 && currentPressedButtons.contains("D-Pad Right") {
            self.stopTrackingButtonPress("D-Pad Right")
            self.currentPressedButtons.remove("D-Pad Right")
            if self.lastButtonPressed == "D-Pad Right" {
                self.lastButtonPressed = "None"
                self.stopTimer()
            }
        }

        if !dpad.up.isPressed && !dpad.down.isPressed && !dpad.left.isPressed && !dpad.right.isPressed {
            self.dpadState = "dpad"
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func startTimer(for button: String) {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateCurrentButtonDuration(button)
        }
    }

    private func updateCurrentButtonDuration(_ button: String) {
        if let startTime = buttonPressStartTimes[button] {
            currentButtonDuration = Date().timeIntervalSince(startTime)
        }
    }

    private func buttonName(for button: GCControllerButtonInput, in gamepad: GCExtendedGamepad) -> String {
        if button == gamepad.buttonA {
            return "Button A"
        } else if button == gamepad.buttonB {
            return "Button B"
        } else if button == gamepad.buttonX {
            return "Button X"
        } else if button == gamepad.buttonY {
            return "Button Y"
        } else if button == gamepad.leftShoulder {
            return "Left Shoulder"
        } else if button == gamepad.rightShoulder {
            return "Right Shoulder"
        } else if button == gamepad.leftTrigger {
            return "Left Trigger"
        } else if button == gamepad.rightTrigger {
            return "Right Trigger"
        } else if button == gamepad.leftThumbstickButton {
            return "Left Thumbstick"
        } else if button == gamepad.rightThumbstickButton {
            return "Right Thumbstick"
        } else if button == gamepad.buttonOptions {
            return "Create Button"
        } else if button == gamepad.buttonMenu {
            return "Options Button"
        } else if button == gamepad.buttonHome {
            return "PS Button"
        } else if let touchpad = gamepad.allButtons.first(where: { $0 == button }) {
            return "Touchpad Button" // Handle touchpad button dynamically
        } else {
            return "Unknown Button" // Ensure a return value for all cases
        }
    }

    private func startTrackingButtonPress(_ button: String) {
        if buttonPressStartTimes[button] == nil {
            buttonPressStartTimes[button] = Date()
        }
    }

    private func stopTrackingButtonPress(_ button: String) {
        if let startTime = buttonPressStartTimes[button] {
            let duration = Date().timeIntervalSince(startTime)
            buttonHistory.append((button: button, timestamp: startTime, duration: duration))
            if buttonHistory.count > 10 {
                buttonHistory.removeFirst()
            }
            buttonPressStartTimes[button] = nil
        }
    }

    private func updateButtonState(_ button: String, isPressed: Bool) {
        switch button {
        case "Button A":
            buttonState["A"] = isPressed ? "circle.fill" : "circle"
        case "Button B":
            buttonState["B"] = isPressed ? "circle.fill" : "circle"
        case "Button X":
            buttonState["X"] = isPressed ? "circle.fill" : "circle"
        case "Button Y":
            buttonState["Y"] = isPressed ? "circle.fill" : "circle"
        case "Left Shoulder":
            shoulderButtonState["L1"] = isPressed ? "l1.button.roundedbottom.horizontal.fill" : "l1.button.roundedbottom.horizontal"
        case "Right Shoulder":
            shoulderButtonState["R1"] = isPressed ? "r1.button.roundedbottom.horizontal.fill" : "r1.button.roundedbottom.horizontal"
        case "Left Trigger":
            shoulderButtonState["L2"] = isPressed ? "l2.button.roundedtop.horizontal.fill" : "l2.button.roundedtop.horizontal"
        case "Right Trigger":
            shoulderButtonState["R2"] = isPressed ? "r2.button.roundedtop.horizontal.fill" : "r2.button.roundedtop.horizontal"
        default:
            break
        }
    }
}