//
//  Item.swift
//  GameControllerManager
//
//  Created by tom on 2025/3/28.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
