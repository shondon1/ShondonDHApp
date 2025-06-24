//
//  FilePickerView.swift
//  ShondonDHApp
//
//  Created by Rashon Hyslop on 6/21/25.
//


import SwiftUI
import UniformTypeIdentifiers

struct FilePickerView: View {
    @Binding var fileURL: URL?
    let label: String
    let allowedTypes: [UTType]
    @State private var showingDocumentPicker = false
    
    // Convenience initializer for backwards compatibility
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
            Button(action: {
                showingDocumentPicker = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: fileTypeIcon)
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(label)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(allowedTypesDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if fileURL != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                    } else {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.accentColor)
                            .font(.title2)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    fileURL != nil ? Color.green : Color.accentColor,
                                    lineWidth: fileURL != nil ? 2 : 1
                                )
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            if let url = fileURL {
                HStack(spacing: 8) {
                    Image(systemName: "doc.fill")
                        .foregroundColor(.accentColor)
                        .font(.caption)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Selected: \(url.lastPathComponent)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(fileSizeDescription(for: url))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Remove") {
                        fileURL = nil
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
                .padding(.horizontal, 4)
            }
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker(fileURL: $fileURL, allowedTypes: allowedTypes)
        }
    }
    
    private var fileTypeIcon: String {
        if allowedTypes.contains(.movie) || allowedTypes.contains(.mpeg4Movie) {
            return "video.badge.plus"
        } else if allowedTypes.contains(.audio) || allowedTypes.contains(.mp3) {
            return "music.note.list"
        } else {
            return "doc.badge.plus"
        }
    }
    
    private var allowedTypesDescription: String {
        var types: [String] = []
        
        if allowedTypes.contains(.movie) || allowedTypes.contains(.mpeg4Movie) || allowedTypes.contains(.quickTimeMovie) {
            types.append("Video")
        }
        if allowedTypes.contains(.audio) || allowedTypes.contains(.mp3) || allowedTypes.contains(.wav) || allowedTypes.contains(.m4a) {
            types.append("Audio")
        }
        
        return types.isEmpty ? "Media files" : "\(types.joined(separator: " & ")) files"
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

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var fileURL: URL?
    let allowedTypes: [UTType]
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: allowedTypes,
            asCopy: true
        )
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        
        // Configure picker appearance
        picker.shouldShowFileExtensions = true
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                parent.fileURL = url
            }
            parent.dismiss()
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}

// MARK: - UTType Extensions for better file type support
extension UTType {
    static let mp3 = UTType(filenameExtension: "mp3")!
    static let wav = UTType(filenameExtension: "wav")!
    static let m4a = UTType(filenameExtension: "m4a")!
    static let quickTimeMovie = UTType(filenameExtension: "mov")!
}
