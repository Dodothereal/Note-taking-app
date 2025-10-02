import Foundation
import PencilKit

class StorageManager {
    static let shared = StorageManager()

    private let fileManager = FileManager.default
    private let notesDirectory: URL
    private let foldersDirectory: URL

    // In-memory cache for performance
    private var notesCache: [UUID: Note] = [:]
    private var foldersCache: [UUID: Folder] = [:]
    private let cacheQueue = DispatchQueue(label: "com.notetakingapp.cache", attributes: .concurrent)

    private init() {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        notesDirectory = documentsPath.appendingPathComponent("Notes", isDirectory: true)
        foldersDirectory = documentsPath.appendingPathComponent("Folders", isDirectory: true)

        createDirectoriesIfNeeded()
        // Lazy loading - cache will be populated on demand when items are accessed
    }

    private func createDirectoriesIfNeeded() {
        do {
            try fileManager.createDirectory(at: notesDirectory, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: foldersDirectory, withIntermediateDirectories: true)
        } catch {
            print("❌ Error creating directories: \(error.localizedDescription)")
        }
    }

    private func preloadCache() {
        cacheQueue.async(flags: .barrier) {
            do {
                // Preload all notes
                let noteURLs = try self.fileManager.contentsOfDirectory(at: self.notesDirectory, includingPropertiesForKeys: nil)
                for url in noteURLs where url.pathExtension == "note" {
                    do {
                        let data = try Data(contentsOf: url)
                        let note = try JSONDecoder().decode(Note.self, from: data)
                        self.notesCache[note.id] = note
                    } catch {
                        print("⚠️ Corrupted note file: \(url.lastPathComponent) - \(error.localizedDescription)")
                        // Try to recover by moving to backup
                        self.quarantineCorruptedFile(url)
                    }
                }

                // Preload all folders
                let folderURLs = try self.fileManager.contentsOfDirectory(at: self.foldersDirectory, includingPropertiesForKeys: nil)
                for url in folderURLs where url.pathExtension == "folder" {
                    do {
                        let data = try Data(contentsOf: url)
                        let folder = try JSONDecoder().decode(Folder.self, from: data)
                        self.foldersCache[folder.id] = folder
                    } catch {
                        print("⚠️ Corrupted folder file: \(url.lastPathComponent) - \(error.localizedDescription)")
                        // Try to recover by moving to backup
                        self.quarantineCorruptedFile(url)
                    }
                }
            } catch {
                print("❌ Error preloading cache: \(error.localizedDescription)")
            }
        }
    }

    private func quarantineCorruptedFile(_ url: URL) {
        let backupDir = url.deletingLastPathComponent().appendingPathComponent("Corrupted", isDirectory: true)
        do {
            try fileManager.createDirectory(at: backupDir, withIntermediateDirectories: true)
            let backupURL = backupDir.appendingPathComponent(url.lastPathComponent)
            try fileManager.moveItem(at: url, to: backupURL)
            print("✅ Moved corrupted file to: \(backupURL.path)")
        } catch {
            print("❌ Failed to quarantine corrupted file: \(error.localizedDescription)")
        }
    }

    // MARK: - Note Operations

    func saveNote(_ note: Note) throws {
        let noteURL = notesDirectory.appendingPathComponent("\(note.id.uuidString).note")
        let data = try JSONEncoder().encode(note)

        // Atomic write to prevent corruption
        let tempURL = noteURL.deletingLastPathComponent().appendingPathComponent(UUID().uuidString)
        try data.write(to: tempURL)
        _ = try fileManager.replaceItemAt(noteURL, withItemAt: tempURL)

        // Update cache
        cacheQueue.async(flags: .barrier) {
            self.notesCache[note.id] = note
        }
    }

    func loadNote(id: UUID) throws -> Note {
        // Try cache first
        var cachedNote: Note?
        cacheQueue.sync {
            cachedNote = notesCache[id]
        }

        if let note = cachedNote {
            return note
        }

        // Load from disk if not in cache
        let noteURL = notesDirectory.appendingPathComponent("\(id.uuidString).note")

        do {
            let data = try Data(contentsOf: noteURL)
            let note = try JSONDecoder().decode(Note.self, from: data)

            // Update cache
            cacheQueue.async(flags: .barrier) {
                self.notesCache[note.id] = note
            }

            return note
        } catch {
            print("❌ Failed to load note \(id): \(error.localizedDescription)")
            // Quarantine corrupted file
            if fileManager.fileExists(atPath: noteURL.path) {
                quarantineCorruptedFile(noteURL)
            }
            throw error
        }
    }

    func deleteNote(id: UUID, permanent: Bool = false) throws {
        let note = try loadNote(id: id)

        if permanent {
            // Permanent delete
            let noteURL = notesDirectory.appendingPathComponent("\(id.uuidString).note")
            try fileManager.removeItem(at: noteURL)

            // Remove from cache
            cacheQueue.async(flags: .barrier) {
                self.notesCache.removeValue(forKey: id)
            }
        } else {
            // Move to trash
            try TrashManager.shared.moveToTrash(note: note)

            // Remove from active storage
            let noteURL = notesDirectory.appendingPathComponent("\(id.uuidString).note")
            try fileManager.removeItem(at: noteURL)

            // Remove from cache
            cacheQueue.async(flags: .barrier) {
                self.notesCache.removeValue(forKey: id)
            }
        }
    }

    func loadAllNotes() throws -> [Note] {
        // Check if cache is empty - if so, load from disk
        var cacheIsEmpty = false
        cacheQueue.sync {
            cacheIsEmpty = notesCache.isEmpty
        }

        if cacheIsEmpty {
            // Lazy load notes from disk
            let noteURLs = try fileManager.contentsOfDirectory(at: notesDirectory, includingPropertiesForKeys: nil)
            for url in noteURLs where url.pathExtension == "note" {
                do {
                    let data = try Data(contentsOf: url)
                    let note = try JSONDecoder().decode(Note.self, from: data)
                    cacheQueue.async(flags: .barrier) {
                        self.notesCache[note.id] = note
                    }
                } catch {
                    print("⚠️ Corrupted note file: \(url.lastPathComponent) - \(error.localizedDescription)")
                    quarantineCorruptedFile(url)
                }
            }
        }

        var notes: [Note] = []
        cacheQueue.sync {
            notes = Array(notesCache.values)
        }
        return notes
    }

    func loadNotes(in folderID: UUID?) throws -> [Note] {
        // Ensure notes are loaded (lazy load if needed)
        _ = try loadAllNotes()

        var notes: [Note] = []
        cacheQueue.sync {
            notes = notesCache.values.filter { $0.parentFolderID == folderID }
        }
        return notes
    }

    // MARK: - Folder Operations

    func saveFolder(_ folder: Folder) throws {
        let folderURL = foldersDirectory.appendingPathComponent("\(folder.id.uuidString).folder")
        let data = try JSONEncoder().encode(folder)

        // Atomic write to prevent corruption
        let tempURL = folderURL.deletingLastPathComponent().appendingPathComponent(UUID().uuidString)
        try data.write(to: tempURL)
        _ = try fileManager.replaceItemAt(folderURL, withItemAt: tempURL)

        // Update cache
        cacheQueue.async(flags: .barrier) {
            self.foldersCache[folder.id] = folder
        }
    }

    func loadFolder(id: UUID) throws -> Folder {
        // Try cache first
        var cachedFolder: Folder?
        cacheQueue.sync {
            cachedFolder = foldersCache[id]
        }

        if let folder = cachedFolder {
            return folder
        }

        // Load from disk if not in cache
        let folderURL = foldersDirectory.appendingPathComponent("\(id.uuidString).folder")

        do {
            let data = try Data(contentsOf: folderURL)
            let folder = try JSONDecoder().decode(Folder.self, from: data)

            // Update cache
            cacheQueue.async(flags: .barrier) {
                self.foldersCache[folder.id] = folder
            }

            return folder
        } catch {
            print("❌ Failed to load folder \(id): \(error.localizedDescription)")
            // Quarantine corrupted file
            if fileManager.fileExists(atPath: folderURL.path) {
                quarantineCorruptedFile(folderURL)
            }
            throw error
        }
    }

    func deleteFolder(id: UUID, permanent: Bool = false) throws {
        let folder = try loadFolder(id: id)

        // Delete all notes in this folder
        let notes = try loadNotes(in: id)
        for note in notes {
            try deleteNote(id: note.id, permanent: permanent)
        }

        // Delete all subfolders
        let subfolders = try loadFolders(in: id)
        for subfolder in subfolders {
            try deleteFolder(id: subfolder.id, permanent: permanent)
        }

        if permanent {
            // Permanent delete
            let folderURL = foldersDirectory.appendingPathComponent("\(id.uuidString).folder")
            try fileManager.removeItem(at: folderURL)

            // Remove from cache
            cacheQueue.async(flags: .barrier) {
                self.foldersCache.removeValue(forKey: id)
            }
        } else {
            // Move to trash
            try TrashManager.shared.moveToTrash(folder: folder)

            // Remove from active storage
            let folderURL = foldersDirectory.appendingPathComponent("\(id.uuidString).folder")
            try fileManager.removeItem(at: folderURL)

            // Remove from cache
            cacheQueue.async(flags: .barrier) {
                self.foldersCache.removeValue(forKey: id)
            }
        }
    }

    func loadAllFolders() throws -> [Folder] {
        // Check if cache is empty - if so, load from disk
        var cacheIsEmpty = false
        cacheQueue.sync {
            cacheIsEmpty = foldersCache.isEmpty
        }

        if cacheIsEmpty {
            // Lazy load folders from disk
            let folderURLs = try fileManager.contentsOfDirectory(at: foldersDirectory, includingPropertiesForKeys: nil)
            for url in folderURLs where url.pathExtension == "folder" {
                do {
                    let data = try Data(contentsOf: url)
                    let folder = try JSONDecoder().decode(Folder.self, from: data)
                    cacheQueue.async(flags: .barrier) {
                        self.foldersCache[folder.id] = folder
                    }
                } catch {
                    print("⚠️ Corrupted folder file: \(url.lastPathComponent) - \(error.localizedDescription)")
                    quarantineCorruptedFile(url)
                }
            }
        }

        var folders: [Folder] = []
        cacheQueue.sync {
            folders = Array(foldersCache.values)
        }
        return folders
    }

    func loadFolders(in parentFolderID: UUID?) throws -> [Folder] {
        // Ensure folders are loaded (lazy load if needed)
        _ = try loadAllFolders()

        var folders: [Folder] = []
        cacheQueue.sync {
            folders = foldersCache.values.filter { $0.parentFolderID == parentFolderID }
        }
        return folders
    }

    // MARK: - Combined Operations

    func loadItems(in folderID: UUID?) throws -> [FileSystemItem] {
        let folders = try loadFolders(in: folderID).map { FileSystemItem.folder($0) }
        let notes = try loadNotes(in: folderID).map { FileSystemItem.note($0) }
        return (folders + notes).sorted { $0.modifiedAt > $1.modifiedAt }
    }

    // MARK: - Move Operations

    func moveNote(id: UUID, to newParentFolderID: UUID?) throws {
        var note = try loadNote(id: id)
        note.parentFolderID = newParentFolderID
        note.modifiedAt = Date()
        try saveNote(note)
    }

    func moveFolder(id: UUID, to newParentFolderID: UUID?) throws {
        var folder = try loadFolder(id: id)
        folder.parentFolderID = newParentFolderID
        folder.modifiedAt = Date()
        try saveFolder(folder)
    }

    // MARK: - Rename Operations

    func renameNote(id: UUID, to newName: String) throws {
        var note = try loadNote(id: id)
        note.name = newName
        note.modifiedAt = Date()
        try saveNote(note)
    }

    func renameFolder(id: UUID, to newName: String) throws {
        var folder = try loadFolder(id: id)
        folder.name = newName
        folder.modifiedAt = Date()
        try saveFolder(folder)
    }

    func updateFolderColor(id: UUID, colorHex: String?) throws {
        var folder = try loadFolder(id: id)
        folder.colorHex = colorHex
        folder.modifiedAt = Date()
        try saveFolder(folder)
    }

    // MARK: - Breadcrumb Path

    func getFolderPath(for folderID: UUID?) throws -> [Folder] {
        var path: [Folder] = []
        var currentFolderID = folderID

        while let folderId = currentFolderID {
            let folder = try loadFolder(id: folderId)
            path.insert(folder, at: 0)
            currentFolderID = folder.parentFolderID
        }

        return path
    }
}
