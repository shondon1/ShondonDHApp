//
//  Content+Item.swift
//  ShondonDHApp
//
//  Created by Rashon Hyslop on 6/22/25.
//

import Foundation
import UniformTypeIdentifiers
import SwiftUI
import CoreTransferable

// ContentItem.swift
//
//  ContentItem.swift
//  ShondonDHApp
//
//  Created by Rashon Hyslop on 6/21/25.
//

import Foundation

struct ContentItem: Identifiable, Codable, Sendable {
    let id: String
    let title: String
    let type: String
    let duration: String
    let isFromLibrary: Bool
    
    var typeIcon: String {
        switch type {
        case "music":      return "🎵"
        case "show":       return "🎙️"
        case "promo":      return "📢"
        case "video_show": return "🎬"
        default:           return "📻"
        }
    }
}

// MARK: - Time Slot Model
struct TimeSlot: Identifiable, Sendable {
    let id: String
    let time: Date
    var content: ContentItem?
}
