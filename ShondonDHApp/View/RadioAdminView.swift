//
//  RadioAdminView.swift
//  ShondonDHApp
//
//  Created by Rashon Hyslop on 7/2/25.
//


//
//  RadioAdminView.swift
//  DreamHouse Admin
//
//  Admin interface to control the 24/7 radio content
//

//import SwiftUI
//import FirebaseFirestore
//
//struct RadioAdminView: View {
//    @State private var contentType = "audio"
//    @State private var contentURL = ""
//    @State private var contentTitle = "DreamHouse Radio"
//    @State private var isPlaying = true
//    @State private var showAlert = false
//    @State private var alertMessage = ""
//    @State private var isUpdating = false
//    
//    // Preset content for easy testing
//    let presetContent = [
//        PresetRadioContent(
//            title: "Live Radio Stream",
//            type: "audio",
//            url: "https://stream.zeno.fm/f63dazzv408uv",
//            icon: "antenna.radiowaves.left.and.right"
//        ),
//        PresetRadioContent(
//            title: "Lofi Hip Hop Radio",
//            type: "youtube",
//            url: "https://www.youtube.com/watch?v=jfKfPfyJRdk",
//            icon: "music.note"
//        ),
//        PresetRadioContent(
//            title: "Test Video",
//            type: "video",
//            url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
//            icon: "video"
//        ),
//        PresetRadioContent(
//            title: "Jazz Radio",
//            type: "audio",
//            url: "https://jazz.streamguys1.com/live",
//            icon: "music.note.list"
//        )
//    ]
//    
//    // Auto-detect content type from URL
//    private func detectContentType(from url: String) -> String {
//        let lowercasedURL = url.lowercased()
//        
//        // YouTube detection
//        if lowercasedURL.contains("youtube.com") || lowercasedURL.contains("youtu.be") {
//            return "youtube"
//        }
//        
//        // Video file extensions
//        if lowercasedURL.hasSuffix(".mp4") || 
//           lowercasedURL.hasSuffix(".mov") || 
//           lowercasedURL.hasSuffix(".m3u8") ||
//           lowercasedURL.hasSuffix(".webm") {
//            return "video"
//        }
//        
//        // Audio file extensions
//        if lowercasedURL.hasSuffix(".mp3") || 
//           lowercasedURL.hasSuffix(".m4a") || 
//           lowercasedURL.hasSuffix(".wav") ||
//           lowercasedURL.hasSuffix(".aac") {
//            return "audio"
//        }
//        
//        // Live stream indicators
//        if lowercasedURL.contains("stream") || 
//           lowercasedURL.contains("live") ||
//           lowercasedURL.contains("radio") {
//            return "live"
//        }
//        
//        // Default to audio for unknown URLs
//        return "audio"
//    }
//    
//    var body: some View {
//        NavigationView {
//            Form {
//                // Current Status Section
//                Section("Current Radio Status") {
//                    CurrentRadioStatusView()
//                }
//                
//                // Quick Presets Section
//                Section("Quick Presets") {
//                    ForEach(presetContent) { preset in
//                        Button(action: {
//                            contentType = preset.type
//                            contentURL = preset.url
//                            contentTitle = preset.title
//                        }) {
//                            HStack {
//                                Image(systemName: preset.icon)
//                                    .frame(width: 30)
//                                    .foregroundColor(.blue)
//                                
//                                VStack(alignment: .leading) {
//                                    Text(preset.title)
//                                        .foregroundColor(.primary)
//                                    Text(preset.type.capitalized)
//                                        .font(.caption)
//                                        .foregroundColor(.secondary)
//                                }
//                                
//                                Spacer()
//                                
//                                if contentURL == preset.url {
//                                    Image(systemName: "checkmark.circle.fill")
//                                        .foregroundColor(.green)
//                                }
//                            }
//                        }
//                    }
//                }
//                
//                // Manual Content Section
//                Section("Configure Content") {
//                    // Content Type Picker
//                    Picker("Content Type", selection: $contentType) {
//                        Label("Audio Stream", systemImage: "antenna.radiowaves.left.and.right").tag("audio")
//                        Label("Video", systemImage: "video").tag("video")
//                        Label("YouTube", systemImage: "play.rectangle").tag("youtube")
//                        Label("Live Stream", systemImage: "dot.radiowaves.left.and.right").tag("live")
//                    }
//                    
//                    // URL Input
//                    VStack(alignment: .leading) {
//                        Text("Content URL")
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//                        
//                        TextField("Enter URL", text: $contentURL)
//                            .textFieldStyle(RoundedBorderTextFieldStyle())
//                            .autocapitalization(.none)
//                            .disableAutocorrection(true)
//                            .onChange(of: contentURL) { newURL in
//                                // Auto-detect content type when URL changes
//                                if !newURL.isEmpty {
//                                    contentType = detectContentType(from: newURL)
//                                }
//                            }
//                        
//                        Text(urlHintText)
//                            .font(.caption2)
//                            .foregroundColor(.secondary)
//                    }
//                    
//                    // Title Input
//                    VStack(alignment: .leading) {
//                        Text("Display Title")
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//                        
//                        TextField("Enter title", text: $contentTitle)
//                            .textFieldStyle(RoundedBorderTextFieldStyle())
//                    }
//                    
//                    // Playing Toggle
//                    Toggle("Start Playing Immediately", isOn: $isPlaying)
//                }
//                
//                // Update Button
//                Section {
//                    Button(action: updateRadioContent) {
//                        HStack {
//                            if isUpdating {
//                                ProgressView()
//                                    .progressViewStyle(CircularProgressViewStyle())
//                                    .scaleEffect(0.8)
//                            } else {
//                                Image(systemName: "radio")
//                            }
//                            
//                            Text(isUpdating ? "Updating..." : "Update Radio")
//                                .fontWeight(.medium)
//                        }
//                        .frame(maxWidth: .infinity)
//                        .foregroundColor(.white)
//                        .padding()
//                        .background(buttonColor)
//                        .cornerRadius(10)
//                    }
//                    .disabled(isUpdating || contentURL.isEmpty || contentTitle.isEmpty)
//                }
//                
//                // Instructions
//                Section("How It Works") {
//                    VStack(alignment: .leading, spacing: 8) {
//                        Label("The radio plays 24/7 in your DreamHouse app", systemImage: "info.circle")
//                            .font(.caption)
//                        
//                        Label("Changes appear instantly for all listeners", systemImage: "sparkles")
//                            .font(.caption)
//                        
//                        Label("YouTube URLs will be embedded in the app", systemImage: "play.rectangle")
//                            .font(.caption)
//                        
//                        Label("Use live stream URLs for continuous playback", systemImage: "antenna.radiowaves.left.and.right")
//                            .font(.caption)
//                    }
//                    .foregroundColor(.secondary)
//                }
//            }
//            .navigationTitle("Radio Control")
//            .alert("Radio Update", isPresented: $showAlert) {
//                Button("OK") { }
//            } message: {
//                Text(alertMessage)
//            }
//        }
//    }
//    
//    private var urlHintText: String {
//        switch contentType {
//        case "audio", "live":
//            return "Example: https://stream.example.com/radio.mp3"
//        case "video":
//            return "Example: https://example.com/video.mp4"
//        case "youtube":
//            return "Example: https://www.youtube.com/watch?v=VIDEO_ID"
//        default:
//            return "Enter a valid URL"
//        }
//    }
//    
//    private var buttonColor: Color {
//        if isUpdating || contentURL.isEmpty || contentTitle.isEmpty {
//            return Color.gray
//        }
//        return Color.blue
//    }
//    
//    private func updateRadioContent() {
//        isUpdating = true
//        
//        let db = Firestore.firestore()
//        let radioData: [String: Any] = [
//            "type": contentType,
//            "url": contentURL,
//            "title": contentTitle,
//            "isPlaying": isPlaying,
//            "thumbnail": "", // You can add thumbnail support later
//            "updatedAt": FieldValue.serverTimestamp()
//        ]
//        
//        db.collection("radioState").document("current").setData(radioData) { error in
//            isUpdating = false
//            
//            if let error = error {
//                alertMessage = "Error: \(error.localizedDescription)"
//            } else {
//                alertMessage = "Radio updated successfully! Content is now playing."
//            }
//            showAlert = true
//        }
//    }
//}
//
//// MARK: - Current Status View
//struct CurrentRadioStatusView: View {
//    @State private var currentContent: RadioContent?
//    @State private var isLoading = true
//    
//    var body: some View {
//        Group {
//            if isLoading {
//                HStack {
//                    ProgressView()
//                    Text("Loading...")
//                }
//            } else if let content = currentContent {
//                VStack(alignment: .leading, spacing: 8) {
//                    HStack {
//                        Image(systemName: iconForType(content.type))
//                            .foregroundColor(.blue)
//                        Text(content.title)
//                            .fontWeight(.medium)
//                    }
//                    
//                    HStack {
//                        Label(content.type.capitalized, systemImage: "info.circle")
//                            .font(.caption)
//                        
//                        Spacer()
//                        
//                        if content.isPlaying {
//                            Label("Playing", systemImage: "play.circle.fill")
//                                .font(.caption)
//                                .foregroundColor(.green)
//                        } else {
//                            Label("Paused", systemImage: "pause.circle.fill")
//                                .font(.caption)
//                                .foregroundColor(.orange)
//                        }
//                    }
//                    
//                    Text(content.url)
//                        .font(.caption2)
//                        .foregroundColor(.secondary)
//                        .lineLimit(1)
//                }
//            } else {
//                Text("No content currently set")
//                    .foregroundColor(.secondary)
//            }
//        }
//        .onAppear {
//            fetchCurrentStatus()
//        }
//    }
//    
//    private func fetchCurrentStatus() {
//        let db = Firestore.firestore()
//        db.collection("radioState").document("current").getDocument { snapshot, error in
//            isLoading = false
//            
//            if let data = snapshot?.data() {
//                currentContent = RadioContent(
//                    type: data["type"] as? String ?? "audio",
//                    url: data["url"] as? String ?? "",
//                    title: data["title"] as? String ?? "Unknown",
//                    isPlaying: data["isPlaying"] as? Bool ?? false
//                )
//            }
//        }
//    }
//    
//    private func iconForType(_ type: String) -> String {
//        switch type {
//        case "audio": return "antenna.radiowaves.left.and.right"
//        case "video": return "video"
//        case "youtube": return "play.rectangle"
//        case "live": return "dot.radiowaves.left.and.right"
//        default: return "radio"
//        }
//    }
//}
//
//// MARK: - Preset Model
//struct PresetRadioContent: Identifiable {
//    let id = UUID()
//    let title: String
//    let type: String
//    let url: String
//    let icon: String
//}
//
//#Preview {
//    RadioAdminView()
//}
