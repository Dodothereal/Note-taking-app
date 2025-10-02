import Foundation
import SwiftUI
import PencilKit

@MainActor
class NotesViewModel: ObservableObject {
    @Published var items: [FileSystemItem] = []
    @Published var currentFolderID: UUID?
    @Published var folderPath: [Folder] = []
    @Published var errorMessage: String?
    @Published var showError = false

    private let storage = StorageManager.shared
    private let settings = AppSettings.shared

    init() {
        loadItems()
    }

    // MARK: - Load Operations

    func loadItems() {
        do {
            items = try storage.loadItems(in: currentFolderID)
            sortItems()
            folderPath = try storage.getFolderPath(for: currentFolderID)
        } catch {
            showErrorMessage("Failed to load items: \(error.localizedDescription)")
        }
    }

    // MARK: - Sorting

    func sortItems() {
        switch settings.sortOption {
        case .modifiedDate:
            items.sort { $0.modifiedAt > $1.modifiedAt }
        case .name:
            items.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .createdDate:
            items.sort { $0.createdAt > $1.createdAt }
        }
    }

    // MARK: - Navigation

    func navigateToFolder(_ folderID: UUID) {
        currentFolderID = folderID
        loadItems()
    }

    func navigateToRoot() {
        currentFolderID = nil
        loadItems()
    }

    func navigateBack() {
        if let lastFolder = folderPath.last {
            currentFolderID = lastFolder.parentFolderID
        } else {
            currentFolderID = nil
        }
        loadItems()
    }

    // MARK: - Create Operations

    func createFolder(name: String) {
        let folder = Folder(name: name, parentFolderID: currentFolderID)
        do {
            try storage.saveFolder(folder)
            // Incremental update: add new folder to items and re-sort
            items.insert(.folder(folder), at: 0)
            sortItems()
        } catch {
            showErrorMessage("Failed to create folder: \(error.localizedDescription)")
        }
    }

    func createNote(name: String) -> Note? {
        print("📝 Creating new note: \(name)")
        let note = Note(name: name, parentFolderID: currentFolderID)
        do {
            try storage.saveNote(note)
            print("✅ Note created and saved: \(note.id)")
            // Incremental update: add new note to items and re-sort
            items.insert(.note(note), at: 0)
            sortItems()
            return note
        } catch {
            print("❌ Failed to create note: \(error)")
            showErrorMessage("Failed to create note: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Delete Operations

    func deleteItem(_ item: FileSystemItem) {
        do {
            switch item {
            case .folder(let folder):
                try storage.deleteFolder(id: folder.id)
            case .note(let note):
                try storage.deleteNote(id: note.id)
            }
            // Incremental update: remove item from array
            items.removeAll { $0.id == item.id }
        } catch {
            showErrorMessage("Failed to delete item: \(error.localizedDescription)")
        }
    }

    // MARK: - Rename Operations

    func renameItem(_ item: FileSystemItem, to newName: String) {
        do {
            switch item {
            case .folder(let folder):
                try storage.renameFolder(id: folder.id, to: newName)
                // Incremental update: update folder in array
                if let index = items.firstIndex(where: { $0.id == folder.id }) {
                    if case .folder(var updatedFolder) = items[index] {
                        updatedFolder.name = newName
                        updatedFolder.modifiedAt = Date()
                        items[index] = .folder(updatedFolder)
                    }
                }
            case .note(let note):
                try storage.renameNote(id: note.id, to: newName)
                // Incremental update: update note in array
                if let index = items.firstIndex(where: { $0.id == note.id }) {
                    if case .note(var updatedNote) = items[index] {
                        updatedNote.name = newName
                        updatedNote.modifiedAt = Date()
                        items[index] = .note(updatedNote)
                    }
                }
            }
            // Re-sort since modifiedAt changed
            sortItems()
        } catch {
            showErrorMessage("Failed to rename item: \(error.localizedDescription)")
        }
    }

    func updateFolderColor(_ folder: Folder, colorHex: String?) {
        do {
            try storage.updateFolderColor(id: folder.id, colorHex: colorHex)
            // Incremental update: update folder in array
            if let index = items.firstIndex(where: { $0.id == folder.id }) {
                if case .folder(var updatedFolder) = items[index] {
                    updatedFolder.colorHex = colorHex
                    updatedFolder.modifiedAt = Date()
                    items[index] = .folder(updatedFolder)
                }
            }
            // Re-sort since modifiedAt changed
            sortItems()
        } catch {
            showErrorMessage("Failed to update folder color: \(error.localizedDescription)")
        }
    }

    // MARK: - Move Operations

    func moveItem(_ item: FileSystemItem, to targetFolderID: UUID?) {
        do {
            switch item {
            case .folder(let folder):
                try storage.moveFolder(id: folder.id, to: targetFolderID)
            case .note(let note):
                try storage.moveNote(id: note.id, to: targetFolderID)
            }
            // Incremental update: remove item if moved to different folder
            if targetFolderID != currentFolderID {
                items.removeAll { $0.id == item.id }
            }
        } catch {
            showErrorMessage("Failed to move item: \(error.localizedDescription)")
        }
    }

    // MARK: - Note Operations

    func saveNote(_ note: Note) {
        print("💾 Saving note: \(note.name) (ID: \(note.id))")
        print("📄 Note has \(note.pages.count) pages")
        do {
            try storage.saveNote(note)
            print("✅ Note saved successfully")
            // Incremental update: update note in array if it exists
            if let index = items.firstIndex(where: { $0.id == note.id }) {
                items[index] = .note(note)
                // Re-sort since modifiedAt may have changed
                sortItems()
            }
        } catch {
            print("❌ Failed to save note: \(error)")
            showErrorMessage("Failed to save note: \(error.localizedDescription)")
        }
    }

    func loadNote(id: UUID) -> Note? {
        print("📖 Loading note with ID: \(id)")
        do {
            let note = try storage.loadNote(id: id)
            print("✅ Note loaded: \(note.name) with \(note.pages.count) pages")
            return note
        } catch {
            print("❌ Failed to load note: \(error)")
            showErrorMessage("Failed to load note: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Error Handling

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}
