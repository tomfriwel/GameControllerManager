//
//  ContentView.swift
//  GameControllerManager
//
//  Created by tom on 2025/3/28.
//

import SwiftUI
import SwiftData
import GameController // 添加 GameController 框架

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    @State private var connectedController: GCController? // 当前连接的手柄
    @State private var lastButtonPressed: String = "None" // 最近按下的按键

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .toolbar {
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            VStack {
                Text("Select an item")
                Divider()
                Text("Connected Controller: \(connectedController?.vendorName ?? "None")")
                Text("Last Button Pressed: \(lastButtonPressed)")
                    .font(.headline)
                    .padding()
            }
            .onAppear(perform: setupGameController)
        }
    }

    private func setupGameController() {
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { notification in
            if let controller = notification.object as? GCController {
                connectedController = controller
                setupControllerInput(controller)
            }
        }

        NotificationCenter.default.addObserver(
            forName: .GCControllerDidDisconnect,
            object: nil,
            queue: .main
        ) { _ in
            connectedController = nil
            lastButtonPressed = "None"
        }

        // 检查是否有已连接的手柄
        if let controller = GCController.controllers().first {
            connectedController = controller
            setupControllerInput(controller)
        }
    }

    private func setupControllerInput(_ controller: GCController) {
        controller.extendedGamepad?.valueChangedHandler = { [self] gamepad, element in
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

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

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
        .modelContainer(for: Item.self, inMemory: true)
}
