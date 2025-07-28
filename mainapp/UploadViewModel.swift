//
//  UploadView.swift
//  ShondonDHApp
//
//  Created by Rashon Hyslop on 6/21/25.
//




import Foundation
import Firebase
import FirebaseFirestore
import FirebaseStorage
import Combine
import AVFoundation

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
    @Published var uploadProgress: Double = 0.0
    @Published var uploadStatus = ""
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let fileManager = FileManager.default
    
    // Documents directory for temporary file storage
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func isValid() -> Bool {
        return !title.isEmpty &&
               !startTime.isEmpty &&
               !duration.isEmpty &&
               audioURL != nil &&
               isValidTimeFormat(startTime) &&
               isValidDurationFormat(duration)
    }
    
    private func isValidTimeFormat(_ time: String) -> Bool {
        let timeRegex = #"^([01]?[0-9]|2[0-3]):[0-5][0-9]$"#
        return time.range(of: timeRegex, options: .regularExpression) != nil
    }
    
    private func isValidDurationFormat(_ duration: String) -> Bool {
        let durationRegex = #"^([0-9]{1,2}):([0-5][0-9]):([0-5][0-9])$"#
        return duration.range(of: durationRegex, options: .regularExpression) != nil
    }
    
    func uploadAndSave(completion: @escaping (Bool, String) -> Void) {
        guard isValid() else {
            completion(false, "Please fill in all required fields with valid formats")
            return
        }
        
        guard let audioFile = audioURL else {
            completion(false, "Please select an audio file")
            return
        }
        
        isUploading = true
        uploadProgress = 0.0
        uploadStatus = "Starting upload..."
        
        Task {
            do {
                // Step 1: Copy files to documents directory
                uploadStatus = "Preparing files..."
                uploadProgress = 0.1
                
                let audioLocalURL = try await copyFileToDocuments(audioFile, prefix: "audio")
                
                var videoLocalURL: URL?
                if hasVideo, let videoFile = videoURL {
                    videoLocalURL = try await copyFileToDocuments(videoFile, prefix: "video")
                }
                
                // Step 2: Get file metadata
                let audioMetadata = try await getAudioMetadata(audioLocalURL)
                
                // Step 3: Upload audio file
                uploadStatus = "Uploading audio..."
                uploadProgress = 0.3
                
                let audioDownloadURL = try await uploadFileWithProgress(
                    audioLocalURL,
                    folder: "audio",
                    progressStart: 0.3,
                    progressEnd: hasVideo ? 0.6 : 0.8
                )
                
                // Step 4: Upload video file if present
                var videoDownloadURL: String = ""
                if let videoLocal = videoLocalURL {
                    uploadStatus = "Uploading video..."
                    uploadProgress = 0.6
                    
                    videoDownloadURL = try await uploadFileWithProgress(
                        videoLocal,
                        folder: "video",
                        progressStart: 0.6,
                        progressEnd: 0.8
                    )
                }
                
                // Step 5: Save to Firestore
                uploadStatus = "Saving to database..."
                uploadProgress = 0.9
                
                try await saveToFirestore(
                    audioURL: audioDownloadURL,
                    videoURL: videoDownloadURL,
                    audioMetadata: audioMetadata
                )
                
                // Step 6: Cleanup temp files
                try fileManager.removeItem(at: audioLocalURL)
                if let videoLocal = videoLocalURL {
                    try fileManager.removeItem(at: videoLocal)
                }
                
                // Step 7: Trigger radio update
                try await triggerRadioUpdate()
                
                // Reset form
                await resetForm()
                
                uploadStatus = "Upload complete!"
                uploadProgress = 1.0
                
                completion(true, "Block uploaded successfully! Radio will update shortly.")
                
            } catch {
                uploadStatus = "Upload failed"
                completion(false, "Upload failed: \(error.localizedDescription)")
            }
            
            isUploading = false
        }
    }
    
    private func copyFileToDocuments(_ sourceURL: URL, prefix: String) async throws -> URL {
        let fileName = "\(prefix)_\(UUID().uuidString)_\(sourceURL.lastPathComponent)"
        let destinationURL = documentsDirectory.appendingPathComponent(fileName)
        
        // Ensure we can access the file
        guard sourceURL.startAccessingSecurityScopedResource() else {
            throw UploadError.fileAccessDenied
        }
        defer { sourceURL.stopAccessingSecurityScopedResource() }
        
        // Copy file to documents directory
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        
        return destinationURL
    }
    
    private func getAudioMetadata(_ audioURL: URL) async throws -> AudioMetadata {
        let asset = AVAsset(url: audioURL)
        
        // Get duration
        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)
        
        // Get metadata
        let metadata = try await asset.load(.metadata)
        var title: String?
        var artist: String?
        
        for item in metadata {
            if let key = item.commonKey {
                switch key {
                case .commonKeyTitle:
                    title = try await item.load(.stringValue)
                case .commonKeyArtist:
                    artist = try await item.load(.stringValue)
                default:
                    break
                }
            }
        }
        
        return AudioMetadata(
            duration: durationSeconds,
            title: title,
            artist: artist
        )
    }
    
    private func uploadFileWithProgress(
        _ fileURL: URL,
        folder: String,
        progressStart: Double,
        progressEnd: Double
    ) async throws -> String {
        let fileName = fileURL.lastPathComponent
        let storageRef = storage.reference().child("\(folder)/\(fileName)")
        
        let metadata = StorageMetadata()
        metadata.contentType = getContentType(for: fileURL)
        
        // Upload with progress tracking
        return try await withCheckedThrowingContinuation { continuation in
            let uploadTask = storageRef.putFile(from: fileURL, metadata: metadata)
            
            // Observe progress
            uploadTask.observe(.progress) { snapshot in
                if let progress = snapshot.progress {
                    let percentage = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                    let adjustedProgress = progressStart + (percentage * (progressEnd - progressStart))
                    
                    Task { @MainActor in
                        self.uploadProgress = adjustedProgress
                    }
                }
            }
            
            // Handle completion
            uploadTask.observe(.success) { snapshot in
                storageRef.downloadURL { url, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let url = url {
                        continuation.resume(returning: url.absoluteString)
                    } else {
                        continuation.resume(throwing: UploadError.noDownloadURL)
                    }
                }
            }
            
            uploadTask.observe(.failure) { snapshot in
                if let error = snapshot.error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: UploadError.uploadFailed)
                }
            }
        }
    }
    
    private func saveToFirestore(
        audioURL: String,
        videoURL: String,
        audioMetadata: AudioMetadata
    ) async throws {
        let blockData: [String: Any] = [
            "title": title,
            "type": type,
            "has_video": hasVideo,
            "audio_url": audioURL,
            "video_url": videoURL,
            "stream_url": audioURL, // For now, use direct audio URL
            "start_time": startTime,
            "duration": duration,
            "host": "DJ Shon",
            "scheduled_day": "daily",
            "created_at": Timestamp(date: Date()),
            // Audio metadata
            "audio_duration_seconds": audioMetadata.duration,
            "detected_title": audioMetadata.title ?? "",
            "detected_artist": audioMetadata.artist ?? "",
            // Radio automation fields
            "is_active": true,
            "play_count": 0,
            "last_played": NSNull(),
            "priority": type == "music" ? 1 : (type == "promo" ? 3 : 2)
        ]
        
        try await db.collection("content_blocks").addDocument(data: blockData)
    }
    
    private func triggerRadioUpdate() async throws {
        // Call your AWS API to update radio playlist
        let updateData: [String: Any] = [
            "action": "refresh_playlist",
            "timestamp": Timestamp(date: Date())
        ]
        
        try await db.collection("radio_updates").addDocument(data: updateData)
        
        // TODO: Later add direct API call to your AWS server
        // try await callAWSPlaylistAPI()
    }
    
    private func resetForm() {
        title = ""
        startTime = ""
        duration = ""
        type = "music"
        hasVideo = false
        audioURL = nil
        videoURL = nil
        uploadProgress = 0.0
        uploadStatus = ""
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
        case "aac":
            return "audio/aac"
        case "mp4":
            return "video/mp4"
        case "mov":
            return "video/quicktime"
        case "m4v":
            return "video/x-m4v"
        default:
            return "application/octet-stream"
        }
    }
}

// MARK: - Supporting Types
struct AudioMetadata {
    let duration: Double
    let title: String?
    let artist: String?
}

enum UploadError: LocalizedError {
    case fileAccessDenied
    case noDownloadURL
    case uploadFailed
    
    var errorDescription: String? {
        switch self {
        case .fileAccessDenied:
            return "Cannot access the selected file"
        case .noDownloadURL:
            return "Failed to get download URL"
        case .uploadFailed:
            return "Upload failed"
        }
    }
}
