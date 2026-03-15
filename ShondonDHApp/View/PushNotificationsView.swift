//
//  PushNotificationsView.swift
//  ShondonDHApp
//

import SwiftUI
import FirebaseFirestore

// MARK: - Push Notifications Hub

struct PushNotificationsView: View {
    @State private var showingCompose = false
    @State private var history: [NotificationQueueItem] = []
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            List {
                // Compose CTA at the top
                Section {
                    Button(action: { showingCompose = true }) {
                        HStack {
                            Image(systemName: "bell.badge.fill")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.blue)
                                .cornerRadius(8)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Send a Notification")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Text("Compose and send to all listeners")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }

                // Guidance note
                Section {
                    NotificationGuidanceView()
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                }

                // History
                Section("Recent Notifications") {
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding()
                    } else if history.isEmpty && !isLoading {
                        Text("No notifications sent yet.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(history) { item in
                            NotificationHistoryRow(item: item)
                        }
                    }
                }
            }
            .navigationTitle("Push Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCompose = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingCompose, onDismiss: loadHistory) {
                ComposeNotificationView()
            }
            .onAppear(perform: loadHistory)
        }
    }

    private func loadHistory() {
        isLoading = true
        Task {
            do {
                let items = try await PushNotificationService.shared.fetchRecent()
                await MainActor.run {
                    history = items
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Guidance Card

private struct NotificationGuidanceView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Respectful Notification Guidelines", systemImage: "info.circle.fill")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 4) {
                GuidelineRow(icon: "bell.slash.fill",  color: .secondary, text: "Use Silent for minor updates — no sound, just a lock-screen entry.")
                GuidelineRow(icon: "bell.fill",        color: .blue,      text: "Use Normal for announcements listeners will appreciate.")
                GuidelineRow(icon: "bell.badge.fill",  color: .red,       text: "Reserve Urgent for truly breaking news — it bypasses Focus modes.")
                GuidelineRow(icon: "clock",            color: .orange,    text: "Avoid sending at night. Listeners in different time zones will still see it.")
            }
        }
        .padding(12)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(10)
    }
}

private struct GuidelineRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 16)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - History Row

struct NotificationHistoryRow: View {
    let item: NotificationQueueItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: item.interruptionIcon)
                    .font(.caption)
                    .foregroundColor(item.interruptionColor)
                Text(item.interruptionDisplay)
                    .font(.caption)
                    .foregroundColor(item.interruptionColor)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: item.statusIcon)
                        .font(.caption2)
                    Text(item.status.capitalized)
                        .font(.caption2)
                }
                .foregroundColor(item.statusColor)
                if let date = item.createdAt {
                    Text(date, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            Text(item.title)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(item.body)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            if item.sourceType == "auto_upload" {
                Label("Auto — new content", systemImage: "arrow.up.circle")
                    .font(.caption2)
                    .foregroundColor(.purple)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Compose Notification View

struct ComposeNotificationView: View {
    @State private var notifTitle = ""
    @State private var notifBody = ""
    @State private var interruptionLevel: NotificationInterruptionLevel = .active
    @State private var isSending = false
    @State private var showingResult = false
    @State private var resultMessage = ""
    @State private var resultIsError = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Message") {
                    TextField("Title (e.g. Big news from DreamHouse)", text: $notifTitle)
                    TextField("Body", text: $notifBody, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    InterruptionLevelPicker(selection: $interruptionLevel)
                } header: {
                    Text("Interruption Level")
                } footer: {
                    Text("When in doubt, choose Normal or Silent. Urgent should be rare — overusing it trains listeners to ignore your alerts.")
                }

                if !notifTitle.isEmpty || !notifBody.isEmpty {
                    Section("Preview") {
                        NotificationPreviewCard(
                            title: notifTitle,
                            body: notifBody,
                            interruptionLevel: interruptionLevel
                        )
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .navigationTitle("Compose Notification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: send) {
                        if isSending {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Text("Send")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isValid || isSending)
                }
            }
            .alert(resultIsError ? "Error" : "Notification Queued", isPresented: $showingResult) {
                Button("OK") {
                    if !resultIsError { dismiss() }
                }
            } message: {
                Text(resultMessage)
            }
        }
    }

    private var isValid: Bool {
        !notifTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !notifBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func send() {
        isSending = true
        Task {
            do {
                try await PushNotificationService.shared.queue(
                    title: notifTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                    body: notifBody.trimmingCharacters(in: .whitespacesAndNewlines),
                    category: "announcement",
                    interruptionLevel: interruptionLevel
                )
                await MainActor.run {
                    resultIsError = false
                    resultMessage = "Your notification has been queued and will be sent to listeners shortly."
                    showingResult = true
                    isSending = false
                }
            } catch {
                await MainActor.run {
                    resultIsError = true
                    resultMessage = firestoreErrorMessage(error)
                    showingResult = true
                    isSending = false
                }
            }
        }
    }
}
