//
//  RadioFlowView.swift
//  ShondonDHApp
//
//  Created by Rashon Hyslop on 7/4/25.
//


import SwiftUI
import FirebaseFirestore
// import FirebaseFirestoreSwift

struct RadioFlowView: View {
    @State private var blocks: [RadioContent] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading Radio Flow…")
                        .padding()
                } else if let error = errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                } else {
                    List {
                        ForEach(blocks, id: \.id) { block in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(block.title)
                                        .font(.headline)
                                    Text(block.type.capitalized)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Image(systemName: "line.horizontal.3")
                                    .foregroundColor(.gray)
                            }
                        }
                        .onMove(perform: move)
                        .onDelete(perform: delete)
                    }
                    .toolbar {
                        EditButton()
                    }
                }
            }
            .navigationTitle("Radio Flow")
            .onAppear(perform: fetchFlow)
        }
    }

    func fetchFlow() {
        isLoading = true
        errorMessage = nil
        let db = Firestore.firestore()
        db.collection("radioFlow")
            .order(by: "order", descending: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    return
                }
                guard let docs = snapshot?.documents else {
                    errorMessage = "No documents found"
                    isLoading = false
                    return
                }
                do {
                    blocks = try docs.compactMap { try $0.data(as: RadioContent.self) }
                } catch {
                    errorMessage = "Decode error: \(error.localizedDescription)"
                }
                isLoading = false
            }
    }

    func move(from source: IndexSet, to destination: Int) {
        var revised = blocks
        revised.move(fromOffsets: source, toOffset: destination)
        blocks = revised

        // Calculate total loop duration (default 3 minutes per block if individual durations are not available)
        let totalDuration: Double = Double(blocks.count) * 180

        // Update Firestore with new order AND reset loop
        let db = Firestore.firestore()

        // Batch update
        let batch = db.batch()

        // Update track orders
        for (index, block) in blocks.enumerated() {
            if let id = block.id {
                let ref = db.collection("radioFlow").document(id)
                batch.updateData(["order": index], forDocument: ref)
            }
        }

        // Reset the playhead for new loop
        let playheadRef = db.collection("radioPlayhead").document("current")
        batch.setData([
            "loopStartTime": Date().timeIntervalSince1970 * 1000,
            "totalLoopDuration": totalDuration,
            "currentIndex": 0,
            "currentPosition": 0,
            "playlistVersion": FieldValue.increment(Int64(1)),
            "lastUpdated": FieldValue.serverTimestamp()
        ], forDocument: playheadRef, merge: true)

        // Commit
        batch.commit()
    }

    func delete(at offsets: IndexSet) {
        let db = Firestore.firestore()
        for index in offsets {
            let block = blocks[index]
            if let id = block.id {
                db.collection("radioFlow").document(id).delete()
            }
        }
        blocks.remove(atOffsets: offsets)
    }
}

#Preview {
    RadioFlowView()
}
