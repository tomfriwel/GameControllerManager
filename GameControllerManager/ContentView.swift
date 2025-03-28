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
                    }
                }
                .padding()
            }
            .onAppear(perform: setupGameController) // 设置手柄监听
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
            // 检测按键输入并更新按键名称
            if let button = element as? GCControllerButtonInput, button.isPressed {
                self.lastButtonPressed = "Button \(button)"
            } else if let dpad = element as? GCControllerDirectionPad {
                if dpad.up.isPressed { self.lastButtonPressed = "D-Pad Up" }
                else if dpad.down.isPressed { self.lastButtonPressed = "D-Pad Down" }
                else if dpad.left.isPressed { self.lastButtonPressed = "D-Pad Left" }
                else if dpad.right.isPressed { self.lastButtonPressed = "D-Pad Right" }
            }
        }
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
