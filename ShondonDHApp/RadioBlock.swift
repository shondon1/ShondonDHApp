//
//  RadioBlock.swift
//  ShondonDHApp
//
//  Created by Rashon Hyslop on 6/21/25.
//



import Foundation
import FirebaseFirestore

struct RadioBlock: Codable, Identifiable {
    @DocumentID var id: String?
    let title: String
    let type: String
    let has_video: Bool
    let audio_url: String
    let video_url: String?
    let stream_url: String
    let start_time: String
    let duration: String
    let host: String
    let scheduled_day: String
    let created_at: Timestamp?
    
    // Custom coding keys to handle snake_case from Firestore
    enum CodingKeys: String, CodingKey {
        case title
        case type
        case has_video
        case audio_url
        case video_url
        case stream_url
        case start_time
        case duration
        case host
        case scheduled_day
        case created_at
    }
    
    // Computed property for display purposes
    var displayStartTime: String {
        // You can format the time here if needed
        return start_time
    }
    
    var displayDuration: String {
        // You can format the duration here if needed
        return duration
    }
}
