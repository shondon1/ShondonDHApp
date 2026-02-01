//
//  ProfileListView.swift
//  ShondonDHApp
//
//  List view for managing profiles with CRUD operations
//

import SwiftUI

struct ProfileListView: View {
    // MARK: - ViewModel
    @StateObject private var viewModel = ProfileManagementViewModel()

    // MARK: - UI State
    @State private var showingAddSheet = false
    @State private var editingProfile: Profile?
    @State private var deletingProfile: Profile?
    @State private var showingDeleteAlert = false
    @State private var isEditMode: EditMode = .inactive

    // MARK: - Body
    var body: some View {
        VStack {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.profiles.isEmpty {
                emptyStateView
            } else {
                profileList
            }
        }
        .navigationTitle("Profiles")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if !viewModel.profiles.isEmpty {
                    EditButton()
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .environment(\.editMode, $isEditMode)
        .sheet(isPresented: $showingAddSheet) {
            ProfileFormView(viewModel: viewModel, mode: .create)
        }
        .sheet(item: $editingProfile) { profile in
            ProfileFormView(viewModel: viewModel, mode: .edit(profile))
        }
        .alert("Delete Profile?", isPresented: $showingDeleteAlert, presenting: deletingProfile) { profile in
            Button("Cancel", role: .cancel) {
                deletingProfile = nil
            }
            Button("Delete", role: .destructive) {
                Task {
                    try? await viewModel.deleteProfile(profile)
                    deletingProfile = nil
                }
            }
        } message: { profile in
            Text("Are you sure you want to delete \(profile.name)? This action cannot be undone.")
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage)
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading profiles...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Profiles Yet")
                .font(.title2)
                .bold()

            Text("Add community members to display in the DreamHouse app")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: { showingAddSheet = true }) {
                Label("Add First Profile", systemImage: "plus.circle.fill")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }

    // MARK: - Profile List
    private var profileList: some View {
        List {
            // Active Profiles Section
            Section {
                ForEach(viewModel.profiles.filter { $0.isActive }) { profile in
                    ProfileRowView(
                        profile: profile,
                        onEdit: { editingProfile = profile },
                        onToggle: { viewModel.toggleActive(profile) },
                        onDelete: {
                            deletingProfile = profile
                            showingDeleteAlert = true
                        }
                    )
                }
                .onMove(perform: moveProfiles)
            } header: {
                HStack {
                    Text("Active Profiles")
                    Spacer()
                    Text("\(viewModel.profiles.filter { $0.isActive }.count)")
                        .foregroundColor(.secondary)
                }
            } footer: {
                Text("Drag to reorder. These profiles appear in the DreamHouse app.")
            }

            // Inactive Profiles Section
            let inactiveProfiles = viewModel.profiles.filter { !$0.isActive }
            if !inactiveProfiles.isEmpty {
                Section {
                    ForEach(inactiveProfiles) { profile in
                        ProfileRowView(
                            profile: profile,
                            onEdit: { editingProfile = profile },
                            onToggle: { viewModel.toggleActive(profile) },
                            onDelete: {
                                deletingProfile = profile
                                showingDeleteAlert = true
                            }
                        )
                    }
                } header: {
                    HStack {
                        Text("Hidden Profiles")
                        Spacer()
                        Text("\(inactiveProfiles.count)")
                            .foregroundColor(.secondary)
                    }
                } footer: {
                    Text("These profiles are hidden from the DreamHouse app.")
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Move Profiles
    private func moveProfiles(from source: IndexSet, to destination: Int) {
        viewModel.reorderProfiles(from: source, to: destination)
    }
}

// MARK: - Profile Row View
struct ProfileRowView: View {
    let profile: Profile
    let onEdit: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            AsyncImage(url: URL(string: profile.profileImage)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                case .failure:
                    placeholderCircle
                case .empty:
                    ProgressView()
                        .frame(width: 50, height: 50)
                @unknown default:
                    placeholderCircle
                }
            }

            // Profile Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(profile.name)
                        .font(.headline)
                        .foregroundColor(profile.isActive ? .primary : .secondary)

                    if !profile.isActive {
                        Text("Hidden")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    }
                }

                if let affiliation = profile.affiliation, !affiliation.isEmpty {
                    Text(affiliation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Social icons
                if profile.hasSocialLinks {
                    HStack(spacing: 6) {
                        if let _ = profile.instagram, !profile.instagram!.isEmpty {
                            Image(systemName: "camera.fill")
                                .font(.caption2)
                                .foregroundColor(.pink)
                        }
                        if let _ = profile.youtube, !profile.youtube!.isEmpty {
                            Image(systemName: "play.rectangle.fill")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                        if let _ = profile.thirdSocial, !profile.thirdSocial!.isEmpty {
                            Image(systemName: "at")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }

            Spacer()

            // Order badge
            Text("#\(profile.order + 1)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }

            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .swipeActions(edge: .leading) {
            Button {
                onToggle()
            } label: {
                Label(profile.isActive ? "Hide" : "Show", systemImage: profile.isActive ? "eye.slash" : "eye")
            }
            .tint(profile.isActive ? .orange : .green)
        }
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit Profile", systemImage: "pencil")
            }

            Button {
                onToggle()
            } label: {
                Label(profile.isActive ? "Hide Profile" : "Show Profile", systemImage: profile.isActive ? "eye.slash" : "eye")
            }

            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Profile", systemImage: "trash")
            }
        }
    }

    private var placeholderCircle: some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 50, height: 50)
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundColor(.gray)
            )
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        ProfileListView()
    }
}
