//
//  ContentView.swift
//  ShondonDHApp
//
//  Created by Rashon Hyslop on 6/21/25.
//
//
//  ContentView.swift
//  ShondonDHApp
//
//  Created by Rashon Hyslop on 6/21/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: UploadView()) {
                    Label("Upload New Block", systemImage: "square.and.arrow.up")
                }
                
                NavigationLink(destination: ScheduleListView()) {
                    Label("View Schedule", systemImage: "calendar")
                }
            }
            .navigationTitle("DreamHouse Studio")
        }
    }
}

#Preview {
    ContentView()
}

