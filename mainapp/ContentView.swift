//
//  ContentView.swift
//  ShondonDHApp
//
//  Created by Rashon Hyslop on 6/21/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

struct ContentView: View {
    @StateObject private var authManager = AuthenticationManager()
    
    var body: some View {
        Group {
            if authManager.isLoading {
                // Loading view while authenticating
                VStack {
                    ProgressView()
                    Text("Authenticating...")
                        .padding(.top)
                }
            } else if authManager.isAuthenticated {
                // Working content with existing views
                NavigationView {
                    List {
                        Section("Content Management") {
                            NavigationLink(destination: UploadView()) {
                                Label("Upload New Content", systemImage: "square.and.arrow.up")
                            }
                            
                            NavigationLink(destination: RadioFlowView()) {
                                Label("Radio Flow", systemImage: "book")
                            }
                        }
                        
                        Section("Radio Control") {
                            NavigationLink(destination: RadioAdminView()) {
                                Label("Radio Admin", systemImage: "radio")
                            }
                            
                            NavigationLink(destination: ScheduleView()) {
                                Label("Schedule Management", systemImage: "calendar")
                            }
                        }
                        
                        Section("Quick Actions") {
                            NavigationLink(destination: QuickTickerMessageView()) {
                                Label("Quick Ticker Message", systemImage: "text.bubble")
                            }
                            
                            NavigationLink(destination: RadioStatusView()) {
                                Label("Radio Status", systemImage: "antenna.radiowaves.left.and.right")
                            }
                        }
                    }
                    .navigationTitle("DreamHouse Studio")
                }
            } else {
                // Error view
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("Authentication Failed")
                        .font(.title2)
                    
                    Text(authManager.errorMessage)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Retry") {
                        authManager.signInAnonymously()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .onAppear {
            // Automatically sign in when app launches
            authManager.signInAnonymously()
        }
    }
}

// MARK: - Quick Ticker Message View (Simple Version)
struct QuickTickerMessageView: View {
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
                    
                    Text("Quick Ticker Message")
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
        
        let db = Firestore.firestore()
        let data: [String: Any] = [
            "message": messageText,
            "isActive": true,
            "priority": priority,
            "createdAt": FieldValue.serverTimestamp()
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
                alertMessage = "Failed to add message: \(error.localizedDescription)"
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

// MARK: - Simple Radio Status View
struct RadioStatusView: View {
    @State private var listenerCount = 0
    @State private var currentTrack = "Loading..."
    @State private var isLive = false
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Current Status Card
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "radio.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading) {
                                Text("DreamHouse Radio")
                                    .font(.title2)
                                    .bold()
                                Text("24/7 Vibe Station")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Live Indicator
                            if isLive {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                    Text("LIVE")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.red)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        
                        Divider()
                        
                        // Status Details
                        VStack(spacing: 12) {
                            StatusRow(
                                icon: "antenna.radiowaves.left.and.right",
                                title: "Listeners",
                                value: "\(listenerCount)",
                                color: .green
                            )
                            
                            StatusRow(
                                icon: "music.note",
                                title: "Current Track",
                                value: currentTrack,
                                color: .blue
                            )
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    if isLoading {
                        ProgressView("Loading status...")
                            .padding()
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Radio Status")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadRadioStatus()
            }
        }
    }
    
    private func loadRadioStatus() {
        // Simple status loading - you can enhance this later
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            listenerCount = Int.random(in: 10...50)
            currentTrack = "DreamHouse Vibes"
            isLive = true
        }
    }
}

// MARK: - Status Row
struct StatusRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .bold()
                .foregroundColor(color)
        }
    }
}

// Authentication Manager
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var errorMessage = ""
    
    init() {
        // Check if already signed in
        if let user = Auth.auth().currentUser {
            print("Already signed in with UID: \(user.uid)")
            self.isAuthenticated = true
            self.isLoading = false
        }
    }
    
    func signInAnonymously() {
        isLoading = true
        errorMessage = ""
        
        Auth.auth().signInAnonymously { [weak self] authResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Anonymous auth failed: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                    self?.isAuthenticated = false
                } else if let user = authResult?.user {
                    print("Signed in anonymously with UID: \(user.uid)")
                    self?.isAuthenticated = true
                }
                self?.isLoading = false
            }
        }
    }
}

#Preview {
    ContentView()
}
