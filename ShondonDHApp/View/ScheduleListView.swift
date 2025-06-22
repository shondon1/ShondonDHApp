//
//  ScheduleListView.swift
//  ShondonDHApp
//
//  Created by Rashon Hyslop on 6/21/25.
//

//
//  ScheduleListView.swift
//  ShondonDHApp
//
//  Created by Rashon Hyslop on 6/21/25.
//

import SwiftUI
import FirebaseFirestore

struct ScheduleListView: View {
    @State private var blocks: [RadioBlock] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading schedule...")
            } else if blocks.isEmpty {
                ContentUnavailableView(
                    "No Scheduled Blocks",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("Upload some content to see it here.")
                )
            } else {
                List(blocks) { block in
                    RadioBlockRow(block: block)
                }
            }
        }
        .navigationTitle("Scheduled Blocks")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await fetchSchedule()
        }
        .onAppear {
            Task {
                await fetchSchedule()
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    @MainActor
    private func fetchSchedule() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let db = Firestore.firestore()
            let snapshot = try await db.collection("content_blocks")
                .order(by: "start_time")
                .getDocuments()
            
            blocks = snapshot.documents.compactMap { document in
                try? document.data(as: RadioBlock.self)
            }
        } catch {
            errorMessage = "Failed to load schedule: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct RadioBlockRow: View {
    let block: RadioBlock
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(block.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Text(block.type.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(typeColor.opacity(0.2))
                    .foregroundColor(typeColor)
                    .clipShape(Capsule())
            }
            
            HStack {
                Label(block.start_time, systemImage: "clock")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if block.has_video {
                    Image("video.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }
            
            Text("Duration: \(block.duration)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
    
    private var typeColor: Color {
        switch block.type.lowercased() {
        case "music":
            return .blue
        case "show":
            return .green
        case "promo":
            return .orange
        default:
            return .gray
        }
    }
}
