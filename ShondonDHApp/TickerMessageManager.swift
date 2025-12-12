//
//  TickerMessageManager.swift
//  ShondonDHApp
//
//  Created by Rashon hyslop on 8/24/25.
//

import Foundation
// TickerMessageManager.swift
// Enhanced ticker message management for the admin app

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// MARK: - Ticker Message Model
struct TickerMessage: Identifiable, Codable {
    @DocumentID var id: String?
    var message: String
    var isActive: Bool
    var priority: Int // 0 = Normal, 1 = High, 2 = Urgent
    var createdAt: Date?
    var expiresAt: Date?
    var category: String? // "promo", "announcement", "live", etc.
    
    var priorityText: String {
        switch priority {
        case 2: return "Urgent"
        case 1: return "High"
        default: return "Normal"
        }
    }
    
    var priorityColor: Color {
        switch priority {
        case 2: return .red
        case 1: return .orange
        default: return .blue
        }
    }
}

// MARK: - Main Ticker Management View
struct TickerManagementView: View {
    @State private var messages: [TickerMessage] = []
    @State private var isLoading = true
    @State private var showingAddSheet = false
    @State private var listener: ListenerRegistration?
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading messages...")
                        .padding()
                } else if messages.isEmpty {
                    EmptyTickerView(showingAddSheet: $showingAddSheet)
                } else {
                    List {
                        ForEach(messages) { message in
                            TickerMessageRow(
                                message: message,
                                onToggle: { toggleMessage(message) },
                                onDelete: { deleteMessage(message) }
                            )
                        }
                    }
                }
            }
            .navigationTitle("Ticker Messages")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddTickerMessageView()
            }
            .onAppear { subscribeToMessages() }
            .onDisappear { listener?.remove() }
        }
    }
    
    private func subscribeToMessages() {
        isLoading = true
        let db = Firestore.firestore()
        
        listener = db.collection("tickerMessages")
            .order(by: "priority", descending: true)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                isLoading = false
                
                if let error = error {
                    print("Error loading messages: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                messages = documents.compactMap { doc -> TickerMessage? in
                    try? doc.data(as: TickerMessage.self)
                }
            }
    }
    
    private func toggleMessage(_ message: TickerMessage) {
        guard let id = message.id else { return }
        let db = Firestore.firestore()
        
        db.collection("tickerMessages").document(id).updateData([
            "isActive": !message.isActive
        ])
    }
    
    private func deleteMessage(_ message: TickerMessage) {
        guard let id = message.id else { return }
        let db = Firestore.firestore()
        
        db.collection("tickerMessages").document(id).delete()
    }
}

// MARK: - Ticker Message Row
struct TickerMessageRow: View {
    let message: TickerMessage
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Priority and Status
            HStack {
                Label(message.priorityText, systemImage: priorityIcon)
                    .font(.caption)
                    .foregroundColor(message.priorityColor)
                
                Spacer()
                
                if let expiresAt = message.expiresAt {
                    if expiresAt <= Date() {
                        Label("Expired", systemImage: "clock.badge.xmark")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else {
                        Label(RelativeDateTimeFormatter().localizedString(for: expiresAt, relativeTo: Date()),
                              systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Message Text
            Text(message.message)
                .font(.system(.body))
                .foregroundColor(message.isActive ? .primary : .secondary)
                .lineLimit(3)
            
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
        .alert("Delete Message?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { onDelete() }
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    private var priorityIcon: String {
        switch message.priority {
        case 2: return "exclamationmark.triangle.fill"
        case 1: return "exclamationmark.circle.fill"
        default: return "info.circle.fill"
        }
    }
}

// MARK: - Add Ticker Message View
struct AddTickerMessageView: View {
    @State private var message = ""
    @State private var priority = 0
    @State private var category = "announcement"
    @State private var setExpiration = false
    @State private var expirationDate = Date().addingTimeInterval(86400) // 24 hours from now
    @State private var isActive = true
    @State private var isSaving = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    @Environment(\.dismiss) private var dismiss
    
    let priorities = [(0, "Normal"), (1, "High"), (2, "Urgent")]
    let categories = [
        ("announcement", "📢 Announcement"),
        ("promo", "🎉 Promo"),
        ("live", "🔴 Live"),
        ("event", "📅 Event"),
        ("general", "📝 General")
    ]
    
    var body: some View {
        NavigationView {
            Form {
                // Message Input
                Section("Message") {
                    TextEditor(text: $message)
                        .frame(minHeight: 100)
                        .overlay(
                            Group {
                                if message.isEmpty {
                                    Text("Enter your ticker message...")
                                        .foregroundColor(.gray.opacity(0.5))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 8)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                    
                    Text("\(message.count)/280 characters")
                        .font(.caption)
                        .foregroundColor(message.count > 280 ? .red : .secondary)
                }
                
                // Settings
                Section("Settings") {
                    // Priority Picker
                    Picker("Priority", selection: $priority) {
                        ForEach(priorities, id: \.0) { priority in
                            Label(priority.1, systemImage: priorityIcon(for: priority.0))
                                .tag(priority.0)
                        }
                    }
                    
                    // Category Picker
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.0) { category in
                            Text(category.1).tag(category.0)
                        }
                    }
                    
                    // Active Toggle
                    Toggle("Active Immediately", isOn: $isActive)
                    
                    // Expiration Toggle
                    Toggle("Set Expiration", isOn: $setExpiration)
                    
                    if setExpiration {
                        DatePicker(
                            "Expires",
                            selection: $expirationDate,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }
                
                // Preview
                Section("Preview") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(getCategoryEmoji())
                                .font(.title2)
                            Text(message.isEmpty ? "Your message will appear here..." : message)
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundColor(message.isEmpty ? .gray : .primary)
                            Spacer()
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            .navigationTitle("Add Ticker Message")
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
            .alert("Message Saved", isPresented: $showingAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func isValid() -> Bool {
        return !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               message.count <= 280
    }
    
    private func getCategoryEmoji() -> String {
        switch category {
        case "promo": return "🎉"
        case "live": return "🔴"
        case "event": return "📅"
        case "announcement": return "📢"
        default: return "📝"
        }
    }
    
    private func priorityIcon(for priority: Int) -> String {
        switch priority {
        case 2: return "exclamationmark.triangle.fill"
        case 1: return "exclamationmark.circle.fill"
        default: return "info.circle.fill"
        }
    }
    
    private func saveMessage() async {
        guard isValid() else { return }
        
        isSaving = true
        let db = Firestore.firestore()
        
        var data: [String: Any] = [
            "message": message.trimmingCharacters(in: .whitespacesAndNewlines),
            "isActive": isActive,
            "priority": priority,
            "category": category,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        if setExpiration {
            data["expiresAt"] = Timestamp(date: expirationDate)
        }
        
        do {
            try await db.collection("tickerMessages").addDocument(data: data)
            
            await MainActor.run {
                alertMessage = "Message added successfully!"
                showingAlert = true
                isSaving = false
            }
        } catch {
            await MainActor.run {
                alertMessage = "Error: \(error.localizedDescription)"
                showingAlert = true
                isSaving = false
            }
        }
    }
}

// MARK: - Empty State View
struct EmptyTickerView: View {
    @Binding var showingAddSheet: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "text.bubble.rtl")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Ticker Messages")
                .font(.title2)
                .bold()
            
            Text("Add messages to display on the radio ticker")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showingAddSheet = true }) {
                Label("Add First Message", systemImage: "plus.circle.fill")
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
    TickerManagementView()
}
