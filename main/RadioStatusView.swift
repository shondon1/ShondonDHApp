//
//  RadioStatusView.swift
//  DreamHouse
//
//  Created by Rashon Hyslop on 7/19/25.
//

import SwiftUI
import FirebaseFirestore

struct RadioStatusView: View {
    @StateObject private var viewModel = EnhancedRadioViewModel()
    @State private var refreshTrigger = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Current Status Card
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "radio.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading) {
                                Text("DreamHouse Radio")
                                    .font(.title2)
                                    .bold()
                                Text("24/7 Vibe Station")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Live Indicator
                            if viewModel.isLive {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                    Text("LIVE")
                                        .font(.caption)
                                        .bold()
                                        .foregroundColor(.red)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        
                        Divider()
                        
                        // Status Details
                        VStack(spacing: 12) {
                            StatusRow(
                                icon: "antenna.radiowaves.left.and.right",
                                title: "Listeners",
                                value: "\(viewModel.listenerCount)",
                                color: .green
                            )
                            
                            StatusRow(
                                icon: "music.note",
                                title: "Current Track",
                                value: currentTrackTitle,
                                color: .blue
                            )
                            
                            if !viewModel.isLive && !viewModel.nextUpTitle.isEmpty {
                                StatusRow(
                                    icon: "music.note.list",
                                    title: "Up Next",
                                    value: viewModel.nextUpTitle,
                                    color: .orange
                                )
                            }
                            
                            StatusRow(
                                icon: "clock",
                                title: "Playlist Items",
                                value: "\(viewModel.playlist.count)",
                                color: .purple
                            )
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Current Ticker Message
                    if !viewModel.currentTickerMessage.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "text.bubble.fill")
                                    .foregroundColor(.blue)
                                Text("Current Ticker Message")
                                    .font(.headline)
                                Spacer()
                            }
                            
                            Text(viewModel.currentTickerMessage)
                                .font(.subheadline)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Quick Actions
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "text.bubble.fill")
                                .foregroundColor(.blue)
                            Text("Quick Actions")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                // Add quick message
                            }) {
                                VStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                    Text("Add Message")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(12)
                            }
                            
                            Button(action: {
                                // Refresh status
                                refreshTrigger.toggle()
                            }) {
                                VStack {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.title2)
                                    Text("Refresh")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Error Display
                    if let errorMessage = viewModel.errorMessage {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Error")
                                .font(.headline)
                            Text(errorMessage)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Radio Status")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                // Refresh data
                refreshTrigger.toggle()
            }
        }
    }
    
    private var currentTrackTitle: String {
        if viewModel.isLive {
            return viewModel.liveTrackTitle ?? "Live Broadcast"
        } else if !viewModel.playlist.isEmpty {
            return viewModel.playlist[viewModel.currentIndex].title
        }
        return "No track playing"
    }
}

// MARK: - Status Row
struct StatusRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .bold()
                .foregroundColor(color)
        }
    }
}

#Preview {
    RadioStatusView()
} 