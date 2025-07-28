//
//  QuickMessageView.swift
//  DreamHouse
//
//  Created by Rashon Hyslop on 7/19/25.
//

import SwiftUI
import FirebaseFirestore

struct QuickMessageView: View {
    @StateObject private var viewModel = EnhancedRadioViewModel()
    @State private var message = ""
    @State private var priority = 0
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isAdding = false
    @Environment(\.dismiss) private var dismiss
    
    let priorities = [
        (0, "Normal"),
        (1, "High"),
        (2, "Urgent")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("Quick Message")
                        .font(.title2)
                        .bold()
                    
                    Text("Add a message to the radio ticker")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Message Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Message")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter your message...", text: $message, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                .padding(.horizontal)
                
                // Priority Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Priority")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(priorities, id: \.0) { priority in
                            HStack {
                                Image(systemName: priorityIcon(for: priority.0))
                                    .foregroundColor(priorityColor(for: priority.0))
                                Text(priority.1)
                            }
                            .tag(priority.0)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.horizontal)
                
                // Add Button
                Button(action: {
                    Task {
                        await addMessage()
                    }
                }) {
                    HStack {
                        if isAdding {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "plus.circle.fill")
                        }
                        Text(isAdding ? "Adding..." : "Add Message")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValidMessage() ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!isValidMessage() || isAdding)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Quick Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Message Added", isPresented: $showingAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func isValidMessage() -> Bool {
        return !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func addMessage() async {
        guard isValidMessage() else { return }
        
        isAdding = true
        let messageText = message.trimmingCharacters(in: .whitespacesAndNewlines)
        
        await viewModel.addTickerMessage(messageText, priority: priority)
        
        await MainActor.run {
            alertMessage = "Message added successfully!"
            showingAlert = true
            isAdding = false
        }
    }
    
    private func priorityIcon(for priority: Int) -> String {
        switch priority {
        case 2: return "exclamationmark.triangle.fill"
        case 1: return "exclamationmark.circle.fill"
        default: return "info.circle.fill"
        }
    }
    
    private func priorityColor(for priority: Int) -> Color {
        switch priority {
        case 2: return .red
        case 1: return .orange
        default: return .blue
        }
    }
}

#Preview {
    QuickMessageView()
} 