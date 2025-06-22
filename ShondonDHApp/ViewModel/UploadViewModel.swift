//
//  UploadView.swift
//  ShondonDHApp
//
//  Created by Rashon Hyslop on 6/21/25.
//

//
//  UploadViewModel.swift
//  ShondonDHApp
//
//  Created by Rashon Hyslop on 6/21/25.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseStorage
import Combine

@MainActor
class UploadViewModel: ObservableObject {
    @Published var title = ""
    @Published var startTime = ""
    @Published var duration = ""
    @Published var type = "music"
    @Published var hasVideo = false
    @Published var audioURL: URL?
    @Published var videoURL: URL?
    @Published var isUploading = false
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    func isValid() -> Bool {
        return !title.isEmpty &&
               !startTime.isEmpty &&
               !duration.isEmpty &&
               audioURL != nil
    }
    
    func uploadAndSave(completion: @escaping (Bool, String) -> Void) {
        guard isValid() else {
            completion(false, "Please fill in all required fields")
            return
        }
        
        guard let audioFile = audioURL else {
            completion(false, "Please select an audio file")
            return
        }
        
        isUploading = true
        
        Task {
            do {
                // Upload audio file
                let audioDownloadURL = try await uploadFile(audioFile, folder: "audio")
                
                // Upload video file if present
                var videoDownloadURL: String = ""
                if hasVideo, let videoFile = videoURL {
                    videoDownloadURL = try await uploadFile(videoFile, folder: "video")
                }
                
                // Save to Firestore
                try await saveToFirestore(
                    audioURL: audioDownloadURL,
                    videoURL: videoDownloadURL
                )
                
                // Reset form
                await resetForm()
                
                completion(true, "Block uploaded successfully!")
                
            } catch {
                completion(false, "Upload failed: \(error.localizedDescription)")
            }
            
            isUploading = false
        }
    }
    
    private func uploadFile(_ fileURL: URL, folder: String) async throws -> String {
        let fileName = "\(UUID().uuidString)_\(fileURL.lastPathComponent)"
        let storageRef = storage.reference().child("\(folder)/\(fileName)")
        
        let metadata = StorageMetadata()
        metadata.contentType = getContentType(for: fileURL)
        
        let _ = try await storageRef.putFileAsync(from: fileURL, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    private func saveToFirestore(audioURL: String, videoURL: String) async throws {
        let blockData: [String: Any] = [
            "title": title,
            "type": type,
            "has_video": hasVideo,
            "audio_url": audioURL,
            "video_url": videoURL,
            "stream_url": "https://radio.pmcshondon.com/dreamhouse",
            "start_time": startTime,
            "duration": duration,
            "host": "DJ Shon",
            "scheduled_day": "daily",
            "created_at": Timestamp(date: Date())
        ]
        
        try await db.collection("content_blocks").addDocument(data: blockData)
    }
    
    private func resetForm() {
        title = ""
        startTime = ""
        duration = ""
        type = "music"
        hasVideo = false
        audioURL = nil
        videoURL = nil
    }
    
    private func getContentType(for url: URL) -> String {
        let pathExtension = url.pathExtension.lowercased()
        
        switch pathExtension {
        case "mp3":
            return "audio/mpeg"
        case "wav":
            return "audio/wav"
        case "m4a":
            return "audio/m4a"
        case "mp4":
            return "video/mp4"
        case "mov":
            return "video/quicktime"
        default:
            return "application/octet-stream"
        }
    }
}
