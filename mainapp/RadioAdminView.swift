//
//  RadioAdminView.swift
//  ShondonDHApp
//
//  Created by Rashon Hyslop on 7/2/25.
//

import SwiftUI
import FirebaseFirestore
import Combine

// MARK: - Track Model
struct RadioTrack: Identifiable, Codable {
    var id: String
    var title: String
    var url: String
    var duration: Int // Duration in seconds
}

// MARK: - Current Radio State Model
struct RadioState: Codable {
    var currentTrackUrl: String?
    var startTimestamp: Timestamp?
    var trackDuration: Int?
    var trackTitle: String?
}

// MARK: - Radio Admin View
struct RadioAdminView: View {
    // Current track state
    @State private var currentTrackUrl: String = ""
    @State private var currentTrackTitle: String = "No track playing"
    @State private var currentTrackDuration: Int = 0
    @State private var startTimestamp: Date?
    @State private var trackEndTime: Date?
    @State private var timeRemaining: String = "--:--"
    
    // Track selection
    @State private var selectedTrack: RadioTrack?
    @State private var availableTracks: [RadioTrack] = []
    
    // UI state
    @State private var isLoading = true
    @State private var isUpdating = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var listener: ListenerRegistration?
    
    // Timer for updating time remaining
    @State private var timer: Timer?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Current Track Section
                    currentTrackSection
                    
                    // Track Selection Section
                    trackSelectionSection
                    
                    // Switch Track Button
                    switchTrackButton
                }
                .padding()
            }
            .navigationTitle("Radio Admin")
            .onAppear {
                loadAvailableTracks()
                listenToRadioState()
            }
            .onDisappear {
                listener?.remove()
                timer?.invalidate()
            }
            .alert("Radio Update", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Current Track Section
    private var currentTrackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "music.note")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Currently Playing")
                    .font(.headline)
                Spacer()
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text(currentTrackTitle)
                    .font(.title3)
                    .bold()
                    .foregroundColor(.primary)
                
                if !currentTrackUrl.isEmpty {
                    Text(currentTrackUrl)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    if let endTime = trackEndTime {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ends at:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatTime(endTime))
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Time remaining:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(timeRemaining)
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.orange)
                        }
                    } else {
                        Text("Track info loading...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Track Selection Section
    private var trackSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet")
                    .font(.title2)
                    .foregroundColor(.green)
                Text("Select Next Track")
                    .font(.headline)
                Spacer()
            }
            
            Divider()
            
            if isLoading && availableTracks.isEmpty {
                ProgressView("Loading tracks...")
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if availableTracks.isEmpty {
                Text("No tracks available")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(availableTracks) { track in
                    TrackRow(
                        track: track,
                        isSelected: selectedTrack?.id == track.id
                    ) {
                        selectedTrack = track
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Switch Track Button
    private var switchTrackButton: some View {
        Button(action: switchTrack) {
            HStack {
                if isUpdating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "play.circle.fill")
                        .font(.title3)
                }
                
                Text(isUpdating ? "Switching..." : "Switch Track")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
            .padding()
            .background(buttonColor)
            .cornerRadius(12)
        }
        .disabled(isUpdating || selectedTrack == nil)
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods
    
    private var buttonColor: Color {
        if isUpdating || selectedTrack == nil {
            return Color.gray
        }
        return Color.blue
    }
    
    private func loadAvailableTracks() {
        // Option 1: Load from Firebase radioFlow collection
        let db = Firestore.firestore()
        db.collection("radioFlow")
            .order(by: "order", descending: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error loading tracks: \(error.localizedDescription)")
                    // Fallback to hardcoded tracks
                    loadHardcodedTracks()
                    return
                }
                
                guard let docs = snapshot?.documents else {
                    loadHardcodedTracks()
                    return
                }
                
                var tracks: [RadioTrack] = []
                for (index, doc) in docs.enumerated() {
                    let data = doc.data()
                    if let title = data["title"] as? String,
                       let url = data["url"] as? String {
                        // Try to get duration from data, default to 240 seconds (4 minutes)
                        let duration = data["duration"] as? Int ?? 240
                        tracks.append(RadioTrack(
                            id: doc.documentID,
                            title: title,
                            url: url,
                            duration: duration
                        ))
                    }
                }
                
                DispatchQueue.main.async {
                    if tracks.isEmpty {
                        loadHardcodedTracks()
                    } else {
                        availableTracks = tracks
                        isLoading = false
                    }
                }
            }
    }
    
    private func loadHardcodedTracks() {
        // Fallback hardcoded tracks - you can customize these
        availableTracks = [
            RadioTrack(id: "1", title: "DreamHouse Vibes", url: "https://yourcdn.com/track1.mp3", duration: 240),
            RadioTrack(id: "2", title: "Chill Beats", url: "https://yourcdn.com/track2.mp3", duration: 180),
            RadioTrack(id: "3", title: "Deep House Mix", url: "https://yourcdn.com/track3.mp3", duration: 300),
            RadioTrack(id: "4", title: "Electronic Dreams", url: "https://yourcdn.com/track4.mp3", duration: 210)
        ]
        isLoading = false
    }
    
    private func listenToRadioState() {
        let db = Firestore.firestore()
        listener = db.collection("radioState").document("current")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error listening to radio state: \(error.localizedDescription)")
                    return
                }
                
                guard let data = snapshot?.data() else {
                    print("No data in radioState/current")
                    return
                }
                
                DispatchQueue.main.async {
                    // Update current track info
                    currentTrackUrl = data["url"] as? String ?? ""
                    currentTrackTitle = data["title"] as? String ?? "No track playing"
                    currentTrackDuration = data["duration"] as? Int ?? 0
                    
                    // Get start timestamp
                    if let timestamp = data["startTimestamp"] as? Timestamp {
                        startTimestamp = timestamp.dateValue()
                        calculateTrackEndTime()
                    }
                    
                    isLoading = false
                }
            }
        
        // Start timer to update time remaining
        startTimer()
    }
    
    private func calculateTrackEndTime() {
        guard let start = startTimestamp, currentTrackDuration > 0 else {
            trackEndTime = nil
            return
        }
        
        trackEndTime = start.addingTimeInterval(TimeInterval(currentTrackDuration))
        updateTimeRemaining()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateTimeRemaining()
        }
    }
    
    private func updateTimeRemaining() {
        guard let endTime = trackEndTime else {
            timeRemaining = "--:--"
            return
        }
        
        let now = Date()
        if now >= endTime {
            timeRemaining = "00:00"
            trackEndTime = nil
        } else {
            let remaining = Int(endTime.timeIntervalSince(now))
            let minutes = remaining / 60
            let seconds = remaining % 60
            timeRemaining = String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    private func switchTrack() {
        guard let track = selectedTrack else { return }
        
        isUpdating = true
        
        let db = Firestore.firestore()
        let radioData: [String: Any] = [
            "type": "audio",
            "url": track.url,
            "title": track.title,
            "isPlaying": true,
            "thumbnail": "",
            "duration": track.duration,
            "startTimestamp": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]

        db.collection("radioState").document("current").setData(radioData, merge: true) { error in
            DispatchQueue.main.async {
                isUpdating = false
                
                if let error = error {
                    alertMessage = "Error: \(error.localizedDescription)"
                } else {
                    alertMessage = "Track switched successfully! '\(track.title)' is now playing."
                    // Clear selection after successful switch
                    selectedTrack = nil
                }
                showAlert = true
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Track Row Component
struct TrackRow: View {
    let track: RadioTrack
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.title)
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.primary)
                    
                    Text(formatDuration(track.duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                        .font(.title3)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

#Preview {
    RadioAdminView()
}
