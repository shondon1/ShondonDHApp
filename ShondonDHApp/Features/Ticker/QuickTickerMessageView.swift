//
//  QuickTickerMessageView.swift
//  ShondonDHApp
//

import FirebaseFirestore
import SwiftUI

struct QuickTickerMessageView: View {
    @State private var message = ""
    @State private var priority = 0
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isAdding = false
    @Environment(\.dismiss) private var dismiss

    private let priorities = [
        (0, "Normal"),
        (1, "High"),
        (2, "Urgent"),
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)

                    Text("Quick Ticker Message")
                        .font(.title2)
                        .bold()

                    Text("Add a message to the radio ticker")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Message")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    TextField("Enter your message...", text: $message, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                .padding(.horizontal)

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
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func addMessage() async {
        guard isValidMessage() else { return }

        isAdding = true
        let messageText = message.trimmingCharacters(in: .whitespacesAndNewlines)

        let db = Firestore.firestore()
        let data: [String: Any] = [
            "message": messageText,
            "isActive": true,
            "priority": priority,
            "createdAt": FieldValue.serverTimestamp(),
        ]

        do {
            try await db.collection("tickerMessages").addDocument(data: data)

            await MainActor.run {
                alertMessage = "Message added successfully!"
                showingAlert = true
                isAdding = false
            }
        } catch {
            await MainActor.run {
                alertMessage = "Failed to add message: \(firestoreErrorMessage(error))"
                showingAlert = true
                isAdding = false
            }
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
