import SwiftUI

struct GridView: View {
    @StateObject private var viewModel = NotesViewModel()
    @EnvironmentObject var settings: AppSettings
    @State private var showingNewFolderAlert = false
    @State private var showingNewNoteAlert = false
    @State private var showingRenameAlert = false
    @State private var showingSettings = false
    @State private var showingPDFImporter = false
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
                                    },
                                    onColorChange: { colorHex in
                                        if case .folder(let folder) = item {
                                            viewModel.updateFolderColor(folder, colorHex: colorHex)
                                        }
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
                        Menu {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button {
                                    settings.sortOption = option
                                    viewModel.sortItems()
                                } label: {
                                    HStack {
                                        Text(option.rawValue)
                                        if settings.sortOption == option {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Label("Sort", systemImage: "arrow.up.arrow.down")
                        }

                        Menu {
                            Button {
                                newItemName = ""
                                showingNewNoteAlert = true
                            } label: {
                                Label("New Note", systemImage: "doc.badge.plus")
                            }

                            Button {
                                showingPDFImporter = true
                            } label: {
                                Label("Import PDF", systemImage: "doc.badge.arrow.up")
                            }
                        } label: {
                            Label("New Note", systemImage: "doc.badge.plus")
                        }

                        Button {
                            newItemName = ""
                            showingNewFolderAlert = true
                        } label: {
                            Label("New Folder", systemImage: "folder.badge.plus")
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
            .fileImporter(
                isPresented: $showingPDFImporter,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                handlePDFImport(result)
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

    private func handlePDFImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            // Get file name without extension
            let fileName = url.deletingPathExtension().lastPathComponent

            // Import PDF
            if let note = PDFImporter.importPDF(from: url, name: fileName, parentFolderID: viewModel.currentFolderID) {
                // Save the imported note
                viewModel.saveNote(note)
                print("✅ PDF imported successfully as note: \(note.name)")

                // Open the newly imported note
                if let fullNote = viewModel.loadNote(id: note.id) {
                    selectedNote = fullNote
                }
            } else {
                print("❌ Failed to import PDF")
            }
        case .failure(let error):
            print("❌ PDF import error: \(error.localizedDescription)")
        }
    }
}
