//
//  TickerControlView.swift
//  DreamHouse
//
//  Created by Rashon Hyslop on 7/19/25.
//

import SwiftUI
import FirebaseFirestore

struct TickerControlView: View {
    @StateObject private var viewModel = EnhancedRadioViewModel()
    @State private var newMessage = ""
    @State private var selectedPriority = 0
    @State private var showExpirationPicker = false
    @State private var expirationHours: Int = 24
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isAddingMessage = false
    
    let priorities = [
        (0, "Normal"),
        (1, "High"),
        (2, "Urgent")
    ]
    
    let expirationOptions = [
        (1, "1 Hour"),
        (6, "6 Hours"),
        (12, "12 Hours"),
        (24, "24 Hours"),
        (72, "3 Days"),
        (168, "1 Week")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("Message Ticker Control")
                        .font(.title2)
                        .bold()
                    
                    Text("Manage scrolling messages on the radio")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Add New Message Section
                VStack(spacing: 16) {
                    // Message Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Message")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter ticker message...", text: $newMessage, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                    .padding(.horizontal)
                    
                    // Priority and Expiration
                    HStack(spacing: 16) {
                        // Priority Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Priority")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Picker("Priority", selection: $selectedPriority) {
                                ForEach(priorities, id: \.0) { priority in
                                    Text(priority.1).tag(priority.0)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // Expiration Toggle
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Auto-Expire")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                showExpirationPicker.toggle()
                            }) {
                                HStack {
                                    Image(systemName: showExpirationPicker ? "clock.fill" : "clock")
                                    Text(showExpirationPicker ? "\(expirationHours)h" : "Never")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(showExpirationPicker ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Add Message Button
                    Button(action: {
                        Task {
                            await addNewMessage()
                        }
                    }) {
                        HStack {
                            if isAddingMessage {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "plus.circle.fill")
                            }
                            Text(isAddingMessage ? "Adding..." : "Add Message")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValidMessage() ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!isValidMessage() || isAddingMessage)
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Color.gray.opacity(0.05))
                
                // Current Messages List
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Active Messages")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(viewModel.tickerMessages.count)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    if viewModel.tickerMessages.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "text.bubble")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            
                            Text("No active messages")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.tickerMessages) { message in
                                    TickerMessageRow(
                                        message: message,
                                        onToggle: { isActive in
                                            Task {
                                                await viewModel.updateTickerMessage(message.id ?? "", isActive: isActive)
                                            }
                                        },
                                        onDelete: {
                                            Task {
                                                await viewModel.deleteTickerMessage(message.id ?? "")
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.top)
                
                Spacer()
            }
            .navigationTitle("Ticker Control")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Ticker Update", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showExpirationPicker) {
                ExpirationPickerView(
                    selectedHours: $expirationHours,
                    options: expirationOptions,
                    isPresented: $showExpirationPicker
                )
            }
        }
    }
    
    private func isValidMessage() -> Bool {
        return !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func addNewMessage() async {
        guard isValidMessage() else { return }
        
        isAddingMessage = true
        let messageText = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        let expirationTime: TimeInterval? = showExpirationPicker ? TimeInterval(expirationHours * 3600) : nil
        
        await viewModel.addTickerMessage(messageText, priority: selectedPriority, expiresIn: expirationTime)
        
        await MainActor.run {
            newMessage = ""
            selectedPriority = 0
            showExpirationPicker = false
            expirationHours = 24
            isAddingMessage = false
            alertMessage = "Message added successfully!"
            showingAlert = true
        }
    }
}

// MARK: - Ticker Message Row
struct TickerMessageRow: View {
    let message: TickerMessage
    let onToggle: (Bool) -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.message)
                        .font(.subheadline)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        // Priority Badge
                        HStack(spacing: 4) {
                            Image(systemName: priorityIcon)
                                .font(.caption2)
                            Text(priorityText)
                                .font(.caption2)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(priorityColor.opacity(0.2))
                        .foregroundColor(priorityColor)
                        .cornerRadius(4)
                        
                        // Expiration Info
                        if let expiresAt = message.expiresAt {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                Text(timeUntilExpiration(expiresAt))
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    // Toggle Button
                    Button(action: {
                        onToggle(!message.isActive)
                    }) {
                        Image(systemName: message.isActive ? "eye.fill" : "eye.slash.fill")
                            .foregroundColor(message.isActive ? .green : .gray)
                    }
                    
                    // Delete Button
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .alert("Delete Message", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this message?")
        }
    }
    
    private var priorityIcon: String {
        switch message.priority {
        case 2: return "exclamationmark.triangle.fill"
        case 1: return "exclamationmark.circle.fill"
        default: return "info.circle.fill"
        }
    }
    
    private var priorityText: String {
        switch message.priority {
        case 2: return "Urgent"
        case 1: return "High"
        default: return "Normal"
        }
    }
    
    private var priorityColor: Color {
        switch message.priority {
        case 2: return .red
        case 1: return .orange
        default: return .blue
        }
    }
    
    private func timeUntilExpiration(_ expiresAt: Timestamp) -> String {
        let timeInterval = expiresAt.dateValue().timeIntervalSinceNow
        let hours = Int(timeInterval / 3600)
        let minutes = Int((timeInterval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Expiration Picker View
struct ExpirationPickerView: View {
    @Binding var selectedHours: Int
    let options: [(Int, String)]
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(options, id: \.0) { option in
                        Button(action: {
                            selectedHours = option.0
                            isPresented = false
                        }) {
                            HStack {
                                Text(option.1)
                                Spacer()
                                if selectedHours == option.0 {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                    
                    Button(action: {
                        selectedHours = 0
                        isPresented = false
                    }) {
                        HStack {
                            Text("Never Expire")
                            Spacer()
                            if selectedHours == 0 {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Set Expiration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    TickerControlView()
} 