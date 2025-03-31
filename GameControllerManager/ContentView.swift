//
//  ContentView.swift
//  GameControllerManager
//
//  Created by tom on 2025/3/28.
//

import SwiftUI
import SwiftData
import GameController

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    @StateObject private var controllerManager = ControllerManager() // 使用新的控制器管理器

    var body: some View {
        NavigationSplitView {
            // 左侧列表视图
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
            // 右侧详细视图
            TabView {
                VStack {
                    Text("Connected Controller: \(controllerManager.connectedController?.vendorName ?? "None")")
                    ControllerStatusView(controllerManager: controllerManager)
                }
                .tabItem {
                    Label("Status", systemImage: "gamecontroller")
                }

                ControllerLayoutView(controllerManager: controllerManager)
                    .tabItem {
                        Label("Layout", systemImage: "rectangle.3.group")
                    }

                VStack {
                    Text("Button History")
                        .font(.headline)
                    ButtonHistoryView(buttonHistory: controllerManager.buttonHistory)
                }
                .tabItem {
                    Label("History", systemImage: "clock")
                }

                VStack {
                    Text("Supported Buttons")
                        .font(.headline)
                    ScrollView {
                        VStack(alignment: .leading) {
                            ForEach(controllerManager.supportedButtons, id: \.self) { button in
                                Text(button)
                                    .padding(.vertical, 2)
                            }
                        }
                    }
                    .padding()
                }
                .tabItem {
                    Label("Buttons", systemImage: "list.bullet")
                }
            }
            .onAppear(perform: controllerManager.setupGameController)
            .onDisappear(perform: controllerManager.stopTimer)
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
