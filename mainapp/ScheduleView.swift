//
//  ScheduleView.swift
//  ShondonDHApp
//
//  Created by Rashon Hyslop on 6/22/25.
//

import SwiftUI
import FirebaseFirestore

struct ScheduleView: View {
    @State private var scheduledContent: [ScheduledItem] = []
    @State private var isLoading = true
    @State private var showingAddSheet = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading schedule...")
                        .padding()
                } else {
                    List {
                        ForEach(scheduledContent) { item in
                            ScheduledItemRow(item: item)
                        }
                        .onDelete(perform: deleteItem)
                    }
                }
            }
            .navigationTitle("Schedule Management")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddScheduledItemView()
            }
            .onAppear {
                loadScheduledContent()
            }
        }
    }
    
    private func loadScheduledContent() {
        isLoading = true
        let db = Firestore.firestore()
        
        db.collection("scheduledContent")
            .order(by: "scheduledTime")
            .getDocuments { snapshot, error in
                isLoading = false
                
                if let error = error {
                    print("Error loading scheduled content: \(error)")
                    return
                }
                
                if let documents = snapshot?.documents {
                    scheduledContent = documents.compactMap { document in
                        let data = document.data()
                        return ScheduledItem(
                            id: document.documentID,
                            title: data["title"] as? String ?? "",
                            type: data["type"] as? String ?? "audio",
                            url: data["url"] as? String ?? "",
                            scheduledTime: (data["scheduledTime"] as? Timestamp)?.dateValue() ?? Date(),
                            isActive: data["isActive"] as? Bool ?? true
                        )
                    }
                }
            }
    }
    
    private func deleteItem(at offsets: IndexSet) {
        let db = Firestore.firestore()
        
        for index in offsets {
            let item = scheduledContent[index]
            db.collection("scheduledContent").document(item.id).delete()
        }
        
        scheduledContent.remove(atOffsets: offsets)
    }
}

// MARK: - Scheduled Item Model
struct ScheduledItem: Identifiable {
    let id: String
    let title: String
    let type: String
    let url: String
    let scheduledTime: Date
    let isActive: Bool
}

// MARK: - Scheduled Item Row
struct ScheduledItemRow: View {
    let item: ScheduledItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconForType(item.type))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text(item.title)
                        .font(.headline)
                    
                    Text(item.type.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if item.isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                Text(timeFormatter.string(from: item.scheduledTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(dateFormatter.string(from: item.scheduledTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
    
    private func iconForType(_ type: String) -> String {
        switch type {
        case "audio": return "music.note"
        case "video": return "video"
        case "youtube": return "play.rectangle"
        default: return "radio"
        }
    }
}

// MARK: - Add Scheduled Item View
struct AddScheduledItemView: View {
    @State private var title = ""
    @State private var type = "audio"
    @State private var url = ""
    @State private var scheduledTime = Date()
    @State private var isActive = true
    @State private var isSaving = false
    @Environment(\.dismiss) private var dismiss
    
    let types = ["audio", "video", "youtube"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Content Details") {
                    TextField("Title", text: $title)
                    
                    Picker("Type", selection: $type) {
                        ForEach(types, id: \.self) { type in
                            Text(type.capitalized).tag(type)
                        }
                    }
                    
                    TextField("URL", text: $url)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section("Schedule") {
                    DatePicker("Scheduled Time", selection: $scheduledTime, displayedComponents: [.date, .hourAndMinute])
                    
                    Toggle("Active", isOn: $isActive)
                }
            }
            .navigationTitle("Add Scheduled Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveItem()
                        }
                    }
                    .disabled(title.isEmpty || url.isEmpty || isSaving)
                }
            }
        }
    }
    
    private func saveItem() async {
        isSaving = true
        
        let db = Firestore.firestore()
        let data: [String: Any] = [
            "title": title,
            "type": type,
            "url": url,
            "scheduledTime": Timestamp(date: scheduledTime),
            "isActive": isActive,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        do {
            try await db.collection("scheduledContent").addDocument(data: data)
            dismiss()
        } catch {
            print("Error saving scheduled item: \(error)")
            isSaving = false
        }
    }
}

#Preview {
    ScheduleView()
}
