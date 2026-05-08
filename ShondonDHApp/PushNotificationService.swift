//
//  PushNotificationService.swift
//  ShondonDHApp
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// MARK: - Notification Queue Item Model

struct NotificationQueueItem: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var body: String
    var topic: String
    var category: String          // "content" | "announcement" | "maintenance" | "urgent"
    var interruptionLevel: String // "passive" | "active" | "time-sensitive"
    var sourceType: String        // "manual" | "auto_upload"
    var sourceId: String?
    var status: String            // "pending" | "sent" | "failed"
    var sentAt: Date?
    var createdAt: Date?
    var createdBy: String

    // MARK: Display Helpers

    var statusIcon: String {
        switch status {
        case "sent":    return "checkmark.circle.fill"
        case "failed":  return "xmark.circle.fill"
        default:        return "clock.fill"
        }
    }

    var statusColor: Color {
        switch status {
        case "sent":   return .green
        case "failed": return .red
        default:       return .orange
        }
    }

    var interruptionDisplay: String {
        switch interruptionLevel {
        case "time-sensitive": return "Urgent"
        case "passive":        return "Silent"
        default:               return "Normal"
        }
    }

    var interruptionIcon: String {
        switch interruptionLevel {
        case "time-sensitive": return "bell.badge.fill"
        case "passive":        return "bell.slash.fill"
        default:               return "bell.fill"
        }
    }

    var interruptionColor: Color {
        switch interruptionLevel {
        case "time-sensitive": return .red
        case "passive":        return .secondary
        default:               return .blue
        }
    }
}

// MARK: - Interruption Level Options

enum NotificationInterruptionLevel: String, CaseIterable, Identifiable {
    case passive        = "passive"
    case active         = "active"
    case timeSensitive  = "time-sensitive"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .passive:       return "Silent"
        case .active:        return "Normal"
        case .timeSensitive: return "Urgent"
        }
    }

    var description: String {
        switch self {
        case .passive:
            return "Appears quietly on the lock screen. No sound or banner. Best for non-urgent updates."
        case .active:
            return "Shows a banner and plays the default sound. Use for general announcements."
        case .timeSensitive:
            return "Breaks through Focus modes with a sound. Reserve for truly important news only."
        }
    }

    var icon: String {
        switch self {
        case .passive:       return "bell.slash.fill"
        case .active:        return "bell.fill"
        case .timeSensitive: return "bell.badge.fill"
        }
    }

    var color: Color {
        switch self {
        case .passive:       return .secondary
        case .active:        return .blue
        case .timeSensitive: return .red
        }
    }
}

// MARK: - Push Notification Service

class PushNotificationService {
    static let shared = PushNotificationService()
    private let db = Firestore.firestore()

    /// The FCM topic all listener-app users subscribe to.
    static let listenerTopic = "dreamhouse_radio"

    private init() {}

    /// Queues a notification to be sent by the Cloud Function.
    func queue(
        title: String,
        body: String,
        category: String,
        interruptionLevel: NotificationInterruptionLevel,
        sourceType: String = "manual",
        sourceId: String? = nil
    ) async throws {
        var data: [String: Any] = [
            "title":            title,
            "body":             body,
            "topic":            Self.listenerTopic,
            "category":         category,
            "interruptionLevel": interruptionLevel.rawValue,
            "sourceType":       sourceType,
            "status":           "pending",
            "createdAt":        FieldValue.serverTimestamp(),
            "createdBy":        Auth.auth().currentUser?.email ?? "admin"
        ]
        if let sourceId { data["sourceId"] = sourceId }
        try await db.collection("notifications_queue").addDocument(data: data)
    }

    /// Loads recent notifications for the history view.
    func fetchRecent(limit: Int = 30) async throws -> [NotificationQueueItem] {
        let snapshot = try await db.collection("notifications_queue")
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: NotificationQueueItem.self) }
    }
}

// MARK: - Interruption Level Picker (reusable)

struct InterruptionLevelPicker: View {
    @Binding var selection: NotificationInterruptionLevel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Interruption Level")
                .font(.subheadline)
                .fontWeight(.semibold)

            ForEach(NotificationInterruptionLevel.allCases) { level in
                Button(action: { selection = level }) {
                    HStack(spacing: 12) {
                        Image(systemName: level.icon)
                            .foregroundColor(level.color)
                            .frame(width: 22)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(level.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            Text(level.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        if selection == level {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(level.color)
                        }
                    }
                    .padding(10)
                    .background(
                        selection == level
                            ? level.color.opacity(0.08)
                            : Color(.systemGray6)
                    )
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Notification Preview Card (reusable)

struct NotificationPreviewCard: View {
    let title: String
    let bodyt: String
    let interruptionLevel: NotificationInterruptionLevel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "radio.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                Text("DreamHouse Radio")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
                Text("now")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                if interruptionLevel == .timeSensitive {
                    Text("TIME SENSITIVE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.red)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(4)
                }
            }

            Text(title.isEmpty ? "Notification title..." : title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(title.isEmpty ? .secondary : .primary)

            Text(bodyt.isEmpty ? "Notification body will appear here." : bodyt)
                .font(.subheadline)
                .foregroundColor(bodyt.isEmpty ? .secondary : .primary)
                .lineLimit(3)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
    }
}
