//
//  FilePickerView.swift
//  ShondonDHApp
//
//  Created by Rashon Hyslop on 6/21/25.
//



import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

struct FilePickerView: View {
    @Binding var fileURL: URL?
    let label: String
    let allowedTypes: [UTType]
    @State private var showingDocumentPicker = false
    @State private var showingPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var errorMessage: String?
    @State private var isProcessing = false
    
    // Convenience initializer
    init(fileURL: Binding<URL?>, label: String) {
        self._fileURL = fileURL
        self.label = label
        self.allowedTypes = [UTType.audio, UTType.movie, UTType.mp3, UTType.mpeg4Movie]
    }
    
    // New initializer with specific file types
    init(fileURL: Binding<URL?>, label: String, allowedTypes: [UTType]) {
        self._fileURL = fileURL
        self.label = label
        self.allowedTypes = allowedTypes
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // File picker button (Files app)
            Button(action: {
                showingDocumentPicker = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "folder.badge.plus")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Choose from Files")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Browse files on your device")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if fileURL != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                    } else {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    fileURL != nil ? Color.green : Color.blue.opacity(0.5),
                                    lineWidth: 1
                                )
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isProcessing)
            
            // Photos picker for videos only
            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .videos,
                photoLibrary: .shared()
            ) {
                HStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title2)
                        .foregroundColor(.purple)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Choose from Photos")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Select videos from camera roll")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.purple.opacity(0.5), lineWidth: 1)
                        )
                )
            }
            .disabled(isProcessing)
            .onChange(of: selectedPhotoItem) { newItem in
                Task {
                    await loadMediaFromPhotos(newItem)
                }
            }
            
            // Selected file info
            if let url = fileURL {
                HStack(spacing: 8) {
                    Image(systemName: fileTypeIcon)
                        .foregroundColor(.accentColor)
                        .font(.caption)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Selected: \(url.lastPathComponent)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(fileSizeDescription(for: url))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Remove") {
                        // Clean up temp file if it exists
                        if url.path.contains("tmp") {
                            try? FileManager.default.removeItem(at: url)
                        }
                        fileURL = nil
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
                .padding(.horizontal, 4)
            }
            
            // Error message
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
            }
        }
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: allowedTypes,
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
    }
    
    private var isVideoType: Bool {
        allowedTypes.contains(where: { $0.conforms(to: .movie) })
    }
    
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        isProcessing = true
        errorMessage = nil
        
        switch result {
        case .success(let urls):
            guard let sourceURL = urls.first else {
                errorMessage = "No file selected"
                isProcessing = false
                return
            }
            
            // Start accessing security-scoped resource
            guard sourceURL.startAccessingSecurityScopedResource() else {
                errorMessage = "Cannot access file. Please try again."
                isProcessing = false
                return
            }
            
            // Copy to temporary directory
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "\(UUID().uuidString)_\(sourceURL.lastPathComponent)"
            let tempURL = tempDir.appendingPathComponent(fileName)
            
            do {
                // Remove existing temp file if needed
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    try FileManager.default.removeItem(at: tempURL)
                }
                
                // Copy file
                try FileManager.default.copyItem(at: sourceURL, to: tempURL)
                fileURL = tempURL
                
                // Stop accessing the original file
                sourceURL.stopAccessingSecurityScopedResource()
                
            } catch {
                errorMessage = "Error copying file: \(error.localizedDescription)"
                sourceURL.stopAccessingSecurityScopedResource()
            }
            
        case .failure(let error):
            errorMessage = "Selection failed: \(error.localizedDescription)"
        }
        
        isProcessing = false
    }
    
    private func loadMediaFromPhotos(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        await MainActor.run {
            isProcessing = true
            errorMessage = nil
        }
        
        do {
            // For videos, try Movie transferable first
            if isVideoType {
                if let movie = try await item.loadTransferable(type: Movie.self) {
                    await MainActor.run {
                        fileURL = movie.url
                        isProcessing = false
                    }
                    return
                }
            }
            
            // Try loading as data for both video and audio
            if let data = try await item.loadTransferable(type: Data.self) {
                // Determine file extension based on content type
                let fileExtension: String
                if isVideoType {
                    fileExtension = "mov"
                } else {
                    // For audio, default to m4a (common iOS audio format)
                    fileExtension = "m4a"
                }
                
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(UUID().uuidString).\(fileExtension)")
                
                try data.write(to: tempURL)
                
                await MainActor.run {
                    fileURL = tempURL
                    isProcessing = false
                }
                return
            }
            
            // If nothing worked
            await MainActor.run {
                errorMessage = "Failed to load media from Photos"
                isProcessing = false
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Error: \(error.localizedDescription)"
                isProcessing = false
            }
        }
    }
    
    private var fileTypeIcon: String {
        if allowedTypes.contains(where: { $0.conforms(to: .movie) }) {
            return "video.fill"
        } else if allowedTypes.contains(where: { $0.conforms(to: .audio) }) {
            return "music.note"
        } else {
            return "doc.fill"
        }
    }
    
    private func fileSizeDescription(for url: URL) -> String {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let size = attributes[.size] as? Int64 {
                return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            }
        } catch {
            // Ignore error
        }
        return ""
    }
}

// UTType Extensions
extension UTType {
    static let mp3 = UTType(filenameExtension: "mp3") ?? .audio
    static let wav = UTType(filenameExtension: "wav") ?? .audio
    static let m4a = UTType(filenameExtension: "m4a") ?? .audio
    static let mpeg4Audio = UTType(filenameExtension: "m4a") ?? .audio
}

// Movie Transferable (if not already in your project)
struct Movie: Transferable {
    let url: URL
    
    nonisolated static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = FileManager.default.temporaryDirectory
                .appendingPathComponent(received.file.lastPathComponent)
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Movie(url: copy)
        }
    }
}

