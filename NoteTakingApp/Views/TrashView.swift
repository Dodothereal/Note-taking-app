import SwiftUI

struct TrashView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var deletedItems: [DeletedItem] = []
    @State private var showingEmptyConfirmation = false
    @State private var itemToRestore: DeletedItem?
    @State private var itemToDelete: DeletedItem?
    @State private var errorMessage: String?
    @State private var showError = false

    let viewModel: NotesViewModel

    var body: some View {
        NavigationStack {
            Group {
                if deletedItems.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(deletedItems) { item in
                            deletedItemRow(item)
                        }
                    }
                }
            }
            .navigationTitle("Recently Deleted")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if !deletedItems.isEmpty {
                        Button(role: .destructive) {
                            showingEmptyConfirmation = true
                        } label: {
                            Text("Empty")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .onAppear {
                loadItems()
            }
            .alert("Empty Trash", isPresented: $showingEmptyConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Empty Trash", role: .destructive) {
                    emptyTrash()
                }
            } message: {
                Text("This will permanently delete all items in the trash. This action cannot be undone.")
            }
            .alert("Restore Item", isPresented: Binding(
                get: { itemToRestore != nil },
                set: { if !$0 { itemToRestore = nil } }
            )) {
                Button("Cancel", role: .cancel) {
                    itemToRestore = nil
                }
                Button("Restore") {
                    if let item = itemToRestore {
                        restoreItem(item)
                    }
                    itemToRestore = nil
                }
            } message: {
                if let item = itemToRestore {
                    Text("Restore \"\(item.name)\"?")
                }
            }
            .alert("Delete Permanently", isPresented: Binding(
                get: { itemToDelete != nil },
                set: { if !$0 { itemToDelete = nil } }
            )) {
                Button("Cancel", role: .cancel) {
                    itemToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let item = itemToDelete {
                        deleteItemPermanently(item)
                    }
                    itemToDelete = nil
                }
            } message: {
                if let item = itemToDelete {
                    Text("Permanently delete \"\(item.name)\"? This action cannot be undone.")
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                if let message = errorMessage {
                    Text(message)
                }
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

                Image(systemName: "trash")
                    .font(.system(size: 50, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.gray.opacity(0.8), .gray.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("No Recently Deleted Items")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)
                Text("Deleted notes and folders will appear here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func deletedItemRow(_ item: DeletedItem) -> some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                    .frame(width: 40, height: 40)

                Image(systemName: item.type == .folder ? "folder.fill" : "doc.text.fill")
                    .foregroundStyle(item.type == .folder ? .blue : .gray)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.body.weight(.medium))

                Text("Deleted \(timeAgo(item.deletedAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .contentShape(Rectangle())
        .swipeActions(edge: .leading) {
            Button {
                itemToRestore = item
            } label: {
                Label("Restore", systemImage: "arrow.uturn.backward")
            }
            .tint(.blue)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                itemToDelete = item
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Actions

    private func loadItems() {
        deletedItems = TrashManager.shared.loadAll()
    }

    private func restoreItem(_ item: DeletedItem) {
        do {
            let restored = try TrashManager.shared.restore(item)

            // Save the restored item back
            if let note = restored as? Note {
                try StorageManager.shared.saveNote(note)
            } else if let folder = restored as? Folder {
                try StorageManager.shared.saveFolder(folder)
            }

            loadItems()
            viewModel.loadItems()
        } catch {
            errorMessage = "Failed to restore item: \(error.localizedDescription)"
            showError = true
        }
    }

    private func deleteItemPermanently(_ item: DeletedItem) {
        do {
            try TrashManager.shared.delete(item.id)
            loadItems()
        } catch {
            errorMessage = "Failed to delete item: \(error.localizedDescription)"
            showError = true
        }
    }

    private func emptyTrash() {
        do {
            try TrashManager.shared.emptyTrash()
            loadItems()
        } catch {
            errorMessage = "Failed to empty trash: \(error.localizedDescription)"
            showError = true
        }
    }

    // MARK: - Helpers

    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
