//
//  UpdateMessageManager.swift
//  ShondonDHApp
//
//  Created by Claude on 1/31/26.
//

import Foundation
import SwiftUI
import FirebaseFirestore

// MARK: - Update Message Model
struct UpdateMessage: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var message: String
    var isActive: Bool
    var createdAt: Date?
    var version: String? // Optional app version (e.g., "1.2.0")
    var type: String // "feature", "announcement", "maintenance", "bugfix", "general"

    var typeDisplay: String {
        switch type {
        case "feature": return "New Feature"
        case "announcement": return "Announcement"
        case "maintenance": return "Maintenance"
        case "bugfix": return "Bug Fix"
        default: return "Update"
        }
    }

    var typeIcon: String {
        switch type {
        case "feature": return "star.fill"
        case "announcement": return "megaphone.fill"
        case "maintenance": return "wrench.fill"
        case "bugfix": return "ladybug.fill"
        default: return "doc.text.fill"
        }
    }

    var typeColor: Color {
        switch type {
        case "feature": return .purple
        case "announcement": return .blue
        case "maintenance": return .orange
        case "bugfix": return .green
        default: return .gray
        }
    }
}

// MARK: - Update Messages Management View
struct UpdateMessagesView: View {
    @State private var messages: [UpdateMessage] = []
    @State private var isLoading = true
    @State private var showingAddSheet = false
    @State private var listener: ListenerRegistration?

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading updates...")
                        .padding()
                } else if messages.isEmpty {
                    EmptyUpdateView(showingAddSheet: $showingAddSheet)
                } else {
                    List {
                        ForEach(messages) { message in
                            UpdateMessageRow(
                                message: message,
                                onToggle: { toggleMessage(message) },
                                onDelete: { deleteMessage(message) }
                            )
                        }
                    }
                }
            }
            .navigationTitle("Update Messages")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddUpdateMessageView()
            }
            .onAppear { subscribeToMessages() }
            .onDisappear { listener?.remove() }
        }
    }

    private func subscribeToMessages() {
        isLoading = true
        let db = Firestore.firestore()

        listener = db.collection("updateMessages")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                isLoading = false

                if let error = error {
                    print("Error loading update messages: \(error)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

                messages = documents.compactMap { doc -> UpdateMessage? in
                    try? doc.data(as: UpdateMessage.self)
                }
            }
    }

    private func toggleMessage(_ message: UpdateMessage) {
        guard let id = message.id else { return }
        let db = Firestore.firestore()

        db.collection("updateMessages").document(id).updateData([
            "isActive": !message.isActive
        ])
    }

    private func deleteMessage(_ message: UpdateMessage) {
        guard let id = message.id else { return }
        let db = Firestore.firestore()

        db.collection("updateMessages").document(id).delete()
    }
}

// MARK: - Update Message Row
struct UpdateMessageRow: View {
    let message: UpdateMessage
    let onToggle: () -> Void
    let onDelete: () -> Void

    @State private var showingDeleteAlert = false
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with type and version
            HStack {
                Label(message.typeDisplay, systemImage: message.typeIcon)
                    .font(.caption)
                    .foregroundColor(message.typeColor)

                Spacer()

                if let version = message.version, !version.isEmpty {
                    Text("v\(version)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }

                if let createdAt = message.createdAt {
                    Text(createdAt, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Title
            Text(message.title)
                .font(.headline)
                .foregroundColor(message.isActive ? .primary : .secondary)

            // Message (expandable)
            VStack(alignment: .leading, spacing: 4) {
                Text(message.message)
                    .font(.subheadline)
                    .foregroundColor(message.isActive ? .secondary : .gray)
                    .lineLimit(isExpanded ? nil : 2)

                if message.message.count > 80 {
                    Button(action: { isExpanded.toggle() }) {
                        Text(isExpanded ? "Show less" : "Show more")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }

            // Actions
            HStack {
                // Active Toggle
                Button(action: onToggle) {
                    HStack(spacing: 4) {
                        Image(systemName: message.isActive ? "eye.fill" : "eye.slash")
                        Text(message.isActive ? "Active" : "Inactive")
                    }
                    .font(.caption)
                    .foregroundColor(message.isActive ? .green : .gray)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                // Delete Button
                Button(action: { showingDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
        .alert("Delete Update?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { onDelete() }
        } message: {
            Text("This action cannot be undone.")
        }
    }
}

// MARK: - Add Update Message View
struct AddUpdateMessageView: View {
    @State private var title = ""
    @State private var message = ""
    @State private var type = "announcement"
    @State private var version = ""
    @State private var isActive = true
    @State private var isSaving = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    // Notification options
    @State private var sendPushNotification = false
    @State private var notificationInterruption: NotificationInterruptionLevel = .active

    @Environment(\.dismiss) private var dismiss

    let types = [
        ("feature", "New Feature", "star.fill"),
        ("announcement", "Announcement", "megaphone.fill"),
        ("maintenance", "Maintenance", "wrench.fill"),
        ("bugfix", "Bug Fix", "ladybug.fill"),
        ("general", "General", "doc.text.fill")
    ]

    var body: some View {
        NavigationView {
            Form {
                // Title Input
                Section("Title") {
                    TextField("Enter update title...", text: $title)

                    Text("\(title.count)/100 characters")
                        .font(.caption)
                        .foregroundColor(title.count > 100 ? .red : .secondary)
                }

                // Message Input
                Section("Message") {
                    TextEditor(text: $message)
                        .frame(minHeight: 150)
                        .overlay(
                            Group {
                                if message.isEmpty {
                                    Text("Enter the update details for users to read...")
                                        .foregroundColor(.gray.opacity(0.5))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 8)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )

                    Text("\(message.count) characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Settings
                Section("Settings") {
                    // Type Picker
                    Picker("Type", selection: $type) {
                        ForEach(types, id: \.0) { typeInfo in
                            Label(typeInfo.1, systemImage: typeInfo.2)
                                .tag(typeInfo.0)
                        }
                    }

                    // Version (Optional)
                    HStack {
                        Text("Version")
                        Spacer()
                        TextField("e.g. 1.2.0", text: $version)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }

                    // Active Toggle
                    Toggle("Active Immediately", isOn: $isActive)
                }

                // Push Notification
                Section {
                    Toggle(isOn: $sendPushNotification) {
                        Label("Send Push Notification", systemImage: "bell.badge")
                    }

                    if sendPushNotification {
                        InterruptionLevelPicker(selection: $notificationInterruption)
                            .padding(.vertical, 4)
                    }
                } header: {
                    Text("Push Notification")
                } footer: {
                    if sendPushNotification {
                        Text("Listeners who have notifications enabled will receive this on their device.")
                    } else {
                        Text("This update will only appear inside the app. Enable the toggle to also push it to listeners' devices.")
                    }
                }

                // Notification Preview (only when push is on)
                if sendPushNotification {
                    Section("Notification Preview") {
                        NotificationPreviewCard(
                            title: title.isEmpty ? "Your title here..." : title,
                            bodyt: message.isEmpty ? "Your message will appear here." : message,
                            interruptionLevel: notificationInterruption
                        )
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                        .listRowBackground(Color.clear)
                    }
                }

                // Preview
                Section("In-App Preview") {
                    VStack(alignment: .leading, spacing: 12) {
                        // Type Badge
                        HStack {
                            Label(getTypeDisplay(), systemImage: getTypeIcon())
                                .font(.caption)
                                .foregroundColor(getTypeColor())

                            Spacer()

                            if !version.isEmpty {
                                Text("v\(version)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }

                        // Title Preview
                        Text(title.isEmpty ? "Your title here..." : title)
                            .font(.headline)
                            .foregroundColor(title.isEmpty ? .gray : .primary)

                        // Message Preview
                        Text(message.isEmpty ? "Your message will appear here..." : message)
                            .font(.subheadline)
                            .foregroundColor(message.isEmpty ? .gray : .secondary)
                            .lineLimit(3)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .navigationTitle("Add Update Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task { await saveMessage() }
                    }
                    .disabled(!isValid() || isSaving)
                }
            }
            .alert(alertMessage.hasPrefix("Error") ? "Error" : "Saved", isPresented: $showingAlert) {
                Button("OK") {
                    if !alertMessage.hasPrefix("Error") { dismiss() }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func isValid() -> Bool {
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               title.count <= 100
    }

    private func getTypeDisplay() -> String {
        types.first { $0.0 == type }?.1 ?? "Update"
    }

    private func getTypeIcon() -> String {
        types.first { $0.0 == type }?.2 ?? "doc.text.fill"
    }

    private func getTypeColor() -> Color {
        switch type {
        case "feature": return .purple
        case "announcement": return .blue
        case "maintenance": return .orange
        case "bugfix": return .green
        default: return .gray
        }
    }

    private func saveMessage() async {
        guard isValid() else { return }

        isSaving = true
        let db = Firestore.firestore()

        var data: [String: Any] = [
            "title": title.trimmingCharacters(in: .whitespacesAndNewlines),
            "message": message.trimmingCharacters(in: .whitespacesAndNewlines),
            "isActive": isActive,
            "type": type,
            "createdAt": FieldValue.serverTimestamp()
        ]

        if !version.isEmpty {
            data["version"] = version.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        do {
            let ref = try await db.collection("updateMessages").addDocument(data: data)

            // Optionally queue a push notification
            if sendPushNotification {
                try await PushNotificationService.shared.queue(
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    body: message.trimmingCharacters(in: .whitespacesAndNewlines),
                    category: type,
                    interruptionLevel: notificationInterruption,
                    sourceType: "manual",
                    sourceId: ref.documentID
                )
            }

            let pushed = sendPushNotification ? " Notification queued for listeners." : ""
            await MainActor.run {
                alertMessage = "Update message saved.\(pushed)"
                showingAlert = true
                isSaving = false
            }
        } catch {
            await MainActor.run {
                alertMessage = "Error: \(firestoreErrorMessage(error))"
                showingAlert = true
                isSaving = false
            }
        }
    }
}

// MARK: - Empty State View
struct EmptyUpdateView: View {
    @Binding var showingAddSheet: Bool

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Update Messages")
                .font(.title2)
                .bold()

            Text("Add update messages to inform users about new features, announcements, and more")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: { showingAddSheet = true }) {
                Label("Add First Update", systemImage: "plus.circle.fill")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

// MARK: - Preview
#Preview {
    UpdateMessagesView()
}
