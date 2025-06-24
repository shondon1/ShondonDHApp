//
//  ScheduleView.swift
//  ShondonDHApp
//
//  Created by Rashon Hyslop on 6/22/25.
//



//
//  SchedulingView.swift
//  ShondonDHApp
//
//  Created by Rashon Hyslop on 6/21/25.
//
//
//  SchedulingView.swift
//  ShondonDHApp
//
//  Created by Rashon Hyslop on 6/21/25.
//

import SwiftUI

struct SchedulingView: View {
    @ObservedObject var viewModel: UploadViewModel
    @State private var selectedDate = Date()
    @State private var timeSlots: [TimeSlot] = []
    @State private var draggedContent: ContentItem?
    
    private let calendar = Calendar.current
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            // Date Picker
            DatePicker("Schedule Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .padding()
                .background(Color(UIColor.systemGroupedBackground))
            
            // Schedule Grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.fixed(80)), // Time column
                    GridItem(.flexible()) // Content column
                ], spacing: 1) {
                    
                    // Header
                    Text("Time")
                        .font(.headline)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor.opacity(0.1))
                    
                    Text("Scheduled Content")
                        .font(.headline)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor.opacity(0.1))
                    
                    // Time slots (24 hour schedule)
                    ForEach(timeSlots, id: \.id) { slot in
                        // Time label
                        Text(timeFormatter.string(from: slot.time))
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, minHeight: 60)
                            .background(Color(UIColor.systemGroupedBackground))
                        
                        // Content slot
                        TimeSlotView(
                            slot: slot,
                            draggedContent: $draggedContent,
                            viewModel: viewModel,
                            sampleLibraryContent: sampleLibraryContent
                        ) { droppedContent in
                            handleContentDrop(content: droppedContent, to: slot)
                        }
                    }
                }
            }
            
            // Content Library at bottom
            contentLibrarySection
        }
        .navigationTitle("Schedule Planner")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            generateTimeSlots()
            loadScheduledContent()
        }
        .onChange(of: selectedDate) { _ in
            loadScheduledContent()
        }
    }
    
    private var contentLibrarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Content Library")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // Show current upload if in progress
                    if !viewModel.title.isEmpty {
                        ContentItemView(
                            content: ContentItem(
                                id: "current",
                                title: viewModel.title,
                                type: viewModel.type,
                                duration: viewModel.duration.isEmpty ? "Unknown" : viewModel.duration,
                                isFromLibrary: false
                            )
                        )
                        .draggable("current")
                    }
                    
                    // TODO: Load existing content from Firestore
                    ForEach(sampleLibraryContent, id: \.id) { content in
                        ContentItemView(content: content)
                            .draggable(content.id)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private func generateTimeSlots() {
        timeSlots = (0..<24).compactMap { hour in
            let time = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: selectedDate)
            guard let time = time else { return nil }
            return TimeSlot(id: "\(hour)", time: time, content: nil)
        }
    }
    
    private func loadScheduledContent() {
        // TODO: Load scheduled content from Firestore for selectedDate
        // For now, keeping empty slots
    }
    
    private func handleContentDrop(content: ContentItem, to slot: TimeSlot) {
        if let index = timeSlots.firstIndex(where: { $0.id == slot.id }) {
            timeSlots[index].content = content
            
            // Save to viewModel if it's the current upload
            if content.id == "current" {
                viewModel.scheduledTime = timeFormatter.string(from: slot.time)
                viewModel.scheduledDate = selectedDate
            }
        }
    }
    
    // Sample data - replace with Firestore data
    private var sampleLibraryContent: [ContentItem] {
        [
            ContentItem(id: "1", title: "Morning Mix", type: "music", duration: "30:00", isFromLibrary: true),
            ContentItem(id: "2", title: "Station ID", type: "promo", duration: "00:30", isFromLibrary: true),
            ContentItem(id: "3", title: "Talk Show", type: "show", duration: "60:00", isFromLibrary: true)
        ]
    }
}

// MARK: - Time Slot View
struct TimeSlotView: View {
    let slot: TimeSlot
    @Binding var draggedContent: ContentItem?
    let viewModel: UploadViewModel
    let sampleLibraryContent: [ContentItem]
    let onDrop: (ContentItem) -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(slot.content != nil ? Color.accentColor.opacity(0.1) : Color.clear)
                .frame(minHeight: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            if let content = slot.content {
                VStack(spacing: 2) {
                    Text(content.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                    Text(content.duration)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(4)
            } else {
                Text("Drop content here")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .dropDestination(for: String.self) { items, location in
            guard let itemId = items.first else { return false }
            
            // Find the content item by ID
            if itemId == "current" && !viewModel.title.isEmpty {
                let currentItem = ContentItem(
                    id: "current",
                    title: viewModel.title,
                    type: viewModel.type,
                    duration: viewModel.duration.isEmpty ? "Unknown" : viewModel.duration,
                    isFromLibrary: false
                )
                onDrop(currentItem)
            } else if let content = sampleLibraryContent.first(where: { $0.id == itemId }) {
                onDrop(content)
            }
            
            return true
        }
    }
}

// MARK: - Content Item View
struct ContentItemView: View {
    let content: ContentItem
    
    var body: some View {
        VStack(spacing: 4) {
            Text(content.typeIcon)
                .font(.title2)
            
            Text(content.title)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text(content.duration)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 80, height: 80)
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
        )
    }
}
