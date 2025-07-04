//
//  RadioFlowListView.swift
//  ShondonDHApp
//
//  Created by Rashon Hyslop on 7/2/25.
//


import SwiftUI
import FirebaseFirestore
// import FirebaseFirestoreSwift

struct RadioFlowListView: View {
    @State private var flowItems: [RadioContent] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading playlist...")
                } else if let error = errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                } else {
                    List {
                        ForEach(flowItems) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.headline)
                                Text("Type: \(item.type.capitalized)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text(item.url)
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                    .lineLimit(1)
                            }
                        }
                        .onDelete(perform: deleteItem)
                    }
                }
            }
            .navigationTitle("Radio Flow List")
            .toolbar {
                EditButton()
            }
        }
        .onAppear(perform: fetchFlow)
    }

    func fetchFlow() {
        isLoading = true
        let db = Firestore.firestore()
        db.collection("radioFlow").getDocuments { snapshot, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                return
            }

            guard let documents = snapshot?.documents else {
                self.errorMessage = "No data found."
                self.isLoading = false
                return
            }

            self.flowItems = documents.compactMap { doc in
                try? doc.data(as: RadioContent.self)
            }

            self.isLoading = false
        }
    }

    func deleteItem(at offsets: IndexSet) {
        let db = Firestore.firestore()
        offsets.forEach { index in
            if let id = flowItems[index].id {
                db.collection("radioFlow").document(id).delete()
            }
        }
        flowItems.remove(atOffsets: offsets)
    }
}

#Preview {
    RadioFlowListView()
}
