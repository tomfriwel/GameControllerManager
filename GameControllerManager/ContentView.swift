//
//  ContentView.swift
//  GameControllerManager
//
//  Created by tom on 2025/3/28.
//

import SwiftUI
import SwiftData
import GameController // 添加 GameController 框架，用于处理游戏手柄输入

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext // 数据模型上下文，用于管理数据
    @Query private var items: [Item] // 查询数据模型中的 Item 列表
    
    @State private var connectedController: GCController? // 当前连接的游戏手柄
    @State private var lastButtonPressed: String = "None" // 最近按下的按键名称
    @State private var buttonHistory: [(button: String, timestamp: Date, duration: TimeInterval?)] = [] // 按键历史记录
    @State private var buttonPressStartTimes: [String: Date] = [:] // 按键按下的开始时间
    @State private var currentButtonDuration: TimeInterval? = nil // 当前按键的持续时间
    @State private var timer: Timer? // 定时器，用于实时更新持续时间

    @State private var dpadState: String = "dpad" // D-Pad 的初始状态
    @State private var buttonState: [String: String] = [ // 按键的初始状态
        "A": "circle",
        "B": "circle",
        "X": "circle",
        "Y": "circle"
    ]
    @State private var shoulderButtonState: [String: String] = [ // 肩部按键的初始状态
        "L1": "l1.button.roundedbottom.horizontal",
        "R1": "r1.button.roundedbottom.horizontal",
        "L2": "l2.button.roundedtop.horizontal",
        "R2": "r2.button.roundedtop.horizontal"
    ]

    // 摇杆位置
    @State private var leftThumbstickPosition: CGPoint = .zero
    @State private var rightThumbstickPosition: CGPoint = .zero

    // 按键名称与 SF Symbols 图标的映射
    private let buttonMappings: [String: String] = [
        "D-Pad Up": "arrow.up.circle.fill",
        "D-Pad Down": "arrow.down.circle.fill",
        "D-Pad Left": "arrow.left.circle.fill",
        "D-Pad Right": "arrow.right.circle.fill",
        "Button A": "a.circle.fill",
        "Button B": "b.circle.fill",
        "Button X": "x.circle.fill",
        "Button Y": "y.circle.fill",
        "Left Shoulder": "l.circle.fill",
        "Right Shoulder": "r.circle.fill",
        "Left Trigger": "l1.circle.fill",
        "Right Trigger": "r1.circle.fill",
        "Menu": "line.horizontal.3.circle.fill",
        "Options": "ellipsis.circle.fill"
    ]

    var body: some View {
        NavigationSplitView {
            // 左侧列表视图，显示数据模型中的 Item 列表
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteItems) // 支持删除操作
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200) // 设置列表宽度
            .toolbar {
                ToolbarItem {
                    Button(action: addItem) { // 添加新 Item 的按钮
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            // 右侧详细视图，显示手柄连接状态和按键信息
            VStack {
                Text("Select an item") // 提示选择一个 Item
                Divider()
                Text("Connected Controller: \(connectedController?.vendorName ?? "None")") // 显示连接的手柄名称
                HStack {
                    Text("Last Button Pressed:") // 显示最近按下的按键
                    VStack {
                        Image(systemName: buttonIcon(for: lastButtonPressed)) // 显示按键对应的图标
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        Text(lastButtonPressed) // 显示按键名称
                            .font(.headline)
                            .foregroundColor(.primary)
                        if let duration = currentButtonDuration {
                            Text("Duration: \(String(format: "%.2f", duration))s") // 实时显示持续时间
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                Divider()
                Text("Controller Layout") // 手柄布局标题
                    .font(.headline)
                VStack {
                    // 肩部按键布局
                    HStack {
                        Image(systemName: shoulderButtonState["L2"] ?? "l2.button.roundedtop.horizontal")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Spacer()
                        Image(systemName: shoulderButtonState["R2"] ?? "r2.button.roundedtop.horizontal")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                    }
                    HStack {
                        Image(systemName: shoulderButtonState["L1"] ?? "l1.button.roundedbottom.horizontal")
                            .font(.system(size: 40))
                            .foregroundColor(.purple)
                        Spacer()
                        Image(systemName: shoulderButtonState["R1"] ?? "r1.button.roundedbottom.horizontal")
                            .font(.system(size: 40))
                            .foregroundColor(.purple)
                    }
                    Divider()
                    // 摇杆显示
                    HStack(spacing: 40) {
                        // 左摇杆
                        ZStack {
                            Circle() // 摇杆底座
                                .stroke(lineWidth: 2)
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray)
                            Circle() // 摇杆位置指示器
                                .frame(width: 30, height: 30)
                                .foregroundColor(.blue)
                                .offset(x: leftThumbstickPosition.x * 25, y: leftThumbstickPosition.y * 25)
                            Text("L") // 左摇杆标签
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .offset(y: 45)
                            // 显示具体数值
                            VStack {
                                Text("x: \(String(format: "%.2f", leftThumbstickPosition.x))")
                                Text("y: \(String(format: "%.2f", leftThumbstickPosition.y))")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .offset(y: -45)
                        }
                        
                        // 右摇杆
                        ZStack {
                            Circle() // 摇杆底座
                                .stroke(lineWidth: 2)
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray)
                            Circle() // 摇杆位置指示器
                                .frame(width: 30, height: 30)
                                .foregroundColor(.red)
                                .offset(x: rightThumbstickPosition.x * 25, y: rightThumbstickPosition.y * 25)
                            Text("R") // 右摇杆标签
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .offset(y: 45)
                            // 显示具体数值
                            VStack {
                                Text("x: \(String(format: "%.2f", rightThumbstickPosition.x))")
                                Text("y: \(String(format: "%.2f", rightThumbstickPosition.y))")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .offset(y: -45)
                        }
                    }
                    .padding()
                    Divider()
                    // D-Pad 和按键布局
                    HStack {
                        // D-Pad 图标
                        Image(systemName: dpadState)
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        Spacer()
                        // 按键布局
                        VStack {
                            Image(systemName: buttonState["Y"] ?? "circle")
                                .font(.system(size: 40))
                                .foregroundColor(.red)
                            HStack {
                                Image(systemName: buttonState["X"] ?? "circle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.green)
                                Spacer()
                                Image(systemName: buttonState["B"] ?? "circle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.yellow)
                            }
                            Image(systemName: buttonState["A"] ?? "circle")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding()
                Divider()
                Text("Button History") // 按键历史记录标题
                    .font(.headline)
                List(buttonHistory, id: \.timestamp) { record in
                    HStack {
                        Text(record.button) // 显示按键名称
                        Spacer()
                        Text("\(record.timestamp, formatter: dateFormatter)") // 显示按键按下时间
                        if let duration = record.duration {
                            Text("(\(String(format: "%.2f", duration))s)") // 显示持续时长
                        }
                    }
                }
                .frame(maxHeight: 200) // 限制历史记录列表的高度
            }
            .onAppear(perform: setupGameController) // 设置手柄监听
            .onDisappear { stopTimer() } // 停止定时器
        }
    }

    // 根据按键名称返回对应的 SF Symbols 图标
    private func buttonIcon(for button: String) -> String {
        return buttonMappings[button] ?? "questionmark.circle.fill" // 未定义按键返回问号图标
    }

    // 设置游戏手柄的连接和断开监听
    private func setupGameController() {
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect, // 手柄连接通知
            object: nil,
            queue: .main
        ) { notification in
            if let controller = notification.object as? GCController {
                connectedController = controller // 更新连接的手柄
                setupControllerInput(controller) // 设置手柄输入监听
            }
        }

        NotificationCenter.default.addObserver(
            forName: .GCControllerDidDisconnect, // 手柄断开通知
            object: nil,
            queue: .main
        ) { _ in
            connectedController = nil // 清除手柄连接状态
            lastButtonPressed = "None" // 重置按键状态
        }

        // 检查是否有已连接的手柄
        if let controller = GCController.controllers().first {
            connectedController = controller
            setupControllerInput(controller)
        }
    }

    // 设置手柄按键输入监听
    private func setupControllerInput(_ controller: GCController) {
        controller.extendedGamepad?.valueChangedHandler = { [self] gamepad, element in
            // 更新摇杆位置
            self.leftThumbstickPosition = CGPoint(
                x: CGFloat(gamepad.leftThumbstick.xAxis.value),
                y: -CGFloat(gamepad.leftThumbstick.yAxis.value)  // 注意：摇杆Y轴在UI中是反向的
            )
            self.rightThumbstickPosition = CGPoint(
                x: CGFloat(gamepad.rightThumbstick.xAxis.value),
                y: -CGFloat(gamepad.rightThumbstick.yAxis.value)  // 注意：摇杆Y轴在UI中是反向的
            )
            
            // 检测按键输入并更新按键名称
            if let button = element as? GCControllerButtonInput {
                let buttonName = buttonName(for: button, in: gamepad) // 获取按键名称
                if button.isPressed {
                    self.lastButtonPressed = buttonName
                    self.startTrackingButtonPress(buttonName) // 开始记录按键按下时间
                    self.startTimer(for: buttonName) // 启动定时器实时更新持续时间
                    self.updateButtonState(buttonName, isPressed: true) // 更新按键状态
                } else {
                    self.lastButtonPressed = "None"
                    self.stopTrackingButtonPress(buttonName) // 停止记录并计算持续时长
                    self.stopTimer() // 停止定时器
                    self.updateButtonState(buttonName, isPressed: false) // 恢复按键状态
                }
            } else if let dpad = element as? GCControllerDirectionPad {
                if dpad.up.isPressed {
                    self.lastButtonPressed = "D-Pad Up"
                    self.startTrackingButtonPress("D-Pad Up")
                    self.startTimer(for: "D-Pad Up")
                    self.dpadState = "dpad.up.filled" // 更新 D-Pad 状态
                } else if dpad.down.isPressed {
                    self.lastButtonPressed = "D-Pad Down"
                    self.startTrackingButtonPress("D-Pad Down")
                    self.startTimer(for: "D-Pad Down")
                    self.dpadState = "dpad.down.filled"
                } else if dpad.left.isPressed {
                    self.lastButtonPressed = "D-Pad Left"
                    self.startTrackingButtonPress("D-Pad Left")
                    self.startTimer(for: "D-Pad Left")
                    self.dpadState = "dpad.left.filled"
                } else if dpad.right.isPressed {
                    self.lastButtonPressed = "D-Pad Right"
                    self.startTrackingButtonPress("D-Pad Right")
                    self.startTimer(for: "D-Pad Right")
                    self.dpadState = "dpad.right.filled"
                } else {
                    self.lastButtonPressed = "None"
                    self.stopTrackingButtonPress("D-Pad Up")
                    self.stopTrackingButtonPress("D-Pad Down")
                    self.stopTrackingButtonPress("D-Pad Left")
                    self.stopTrackingButtonPress("D-Pad Right")
                    self.stopTimer() // 停止定时器
                    self.dpadState = "dpad" // 恢复 D-Pad 初始状态
                }
            }
        }
    }

    // 更新按键状态
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

    // 获取按键名称
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
        } else {
            return "Unknown Button"
        }
    }

    // 开始记录按键按下时间
    private func startTrackingButtonPress(_ button: String) {
        if buttonPressStartTimes[button] == nil {
            buttonPressStartTimes[button] = Date() // 记录按下时间
        }
    }

    // 停止记录按键按下时间并计算持续时长
    private func stopTrackingButtonPress(_ button: String) {
        if let startTime = buttonPressStartTimes[button] {
            let duration = Date().timeIntervalSince(startTime) // 计算持续时长
            buttonHistory.append((button: button, timestamp: startTime, duration: duration)) // 添加到历史记录
            if buttonHistory.count > 10 { // 限制历史记录最多保存 10 条
                buttonHistory.removeFirst()
            }
            buttonPressStartTimes[button] = nil // 清除开始时间
        }
    }

    // 启动定时器实时更新持续时间
    private func startTimer(for button: String) {
        stopTimer() // 停止之前的定时器
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.updateCurrentButtonDuration(button)
        }
    }

    // 停止定时器
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // 实时更新当前按键的持续时间
    private func updateCurrentButtonDuration(_ button: String) {
        if let startTime = buttonPressStartTimes[button] {
            self.currentButtonDuration = Date().timeIntervalSince(startTime) // 计算实时持续时间
        }
    }

    // 日期格式化器
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }

    // 添加新 Item 到数据模型
    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    // 删除选中的 Item
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true) // 使用内存中的数据模型进行预览
}
