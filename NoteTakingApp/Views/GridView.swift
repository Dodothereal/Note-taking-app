import SwiftUI

struct GridView: View {
    @StateObject private var viewModel = NotesViewModel()
    @State private var showingNewFolderAlert = false
    @State private var showingNewNoteAlert = false
    @State private var showingRenameAlert = false
    @State private var showingSettings = false
    @State private var newItemName = ""
    @State private var selectedNote: Note?
    @State private var itemToRename: FileSystemItem?

    let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 24)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Breadcrumb
                BreadcrumbView(path: viewModel.folderPath) { folderID in
                    if let folderID = folderID {
                        viewModel.navigateToFolder(folderID)
                    } else {
                        viewModel.navigateToRoot()
                    }
                }

                // Grid
                if viewModel.items.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 24) {
                            ForEach(viewModel.items) { item in
                                GridItemView(
                                    item: item,
                                    onTap: {
                                        handleItemTap(item)
                                    },
                                    onRename: {
                                        itemToRename = item
                                        newItemName = item.name
                                        showingRenameAlert = true
                                    },
                                    onDelete: {
                                        viewModel.deleteItem(item)
                                    }
                                )
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGray6).opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !viewModel.folderPath.isEmpty {
                        Button {
                            viewModel.navigateBack()
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                    } else {
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            newItemName = ""
                            showingNewFolderAlert = true
                        } label: {
                            Label("New Folder", systemImage: "folder.badge.plus")
                        }

                        Button {
                            newItemName = ""
                            showingNewNoteAlert = true
                        } label: {
                            Label("New Note", systemImage: "doc.badge.plus")
                        }
                    }
                }
            }
            .alert("New Folder", isPresented: $showingNewFolderAlert) {
                TextField("Folder Name", text: $newItemName)
                Button("Cancel", role: .cancel) { }
                Button("Create") {
                    if !newItemName.isEmpty {
                        viewModel.createFolder(name: newItemName)
                    }
                }
            }
            .alert("New Note", isPresented: $showingNewNoteAlert) {
                TextField("Note Name", text: $newItemName)
                Button("Cancel", role: .cancel) { }
                Button("Create") {
                    if !newItemName.isEmpty {
                        if let note = viewModel.createNote(name: newItemName) {
                            // Reload to ensure we have the full note data
                            selectedNote = viewModel.loadNote(id: note.id)
                        }
                    }
                }
            }
            .alert("Rename", isPresented: $showingRenameAlert) {
                TextField("Name", text: $newItemName)
                Button("Cancel", role: .cancel) {
                    itemToRename = nil
                }
                Button("Rename") {
                    if !newItemName.isEmpty, let item = itemToRename {
                        viewModel.renameItem(item, to: newItemName)
                    }
                    itemToRename = nil
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .fullScreenCover(item: $selectedNote) { note in
                NoteEditorView(note: note, viewModel: viewModel)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)

                Image(systemName: "folder.fill.badge.plus")
                    .font(.system(size: 50, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue.opacity(0.8), .blue.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("No notes or folders")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)
                Text("Tap the + buttons above to get started")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func handleItemTap(_ item: FileSystemItem) {
        switch item {
        case .folder(let folder):
            viewModel.navigateToFolder(folder.id)
        case .note(let note):
            // Reload the note from storage to ensure we have all data
            if let fullNote = viewModel.loadNote(id: note.id) {
                selectedNote = fullNote
            }
        }
    }
}
