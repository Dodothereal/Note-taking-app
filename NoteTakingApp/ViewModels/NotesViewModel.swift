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

    init() {
        loadItems()
    }

    // MARK: - Load Operations

    func loadItems() {
        do {
            items = try storage.loadItems(in: currentFolderID)
            folderPath = try storage.getFolderPath(for: currentFolderID)
        } catch {
            showErrorMessage("Failed to load items: \(error.localizedDescription)")
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
            loadItems()
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
            loadItems()
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
            loadItems()
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
            case .note(let note):
                try storage.renameNote(id: note.id, to: newName)
            }
            loadItems()
        } catch {
            showErrorMessage("Failed to rename item: \(error.localizedDescription)")
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
            loadItems()
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
            loadItems()
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
