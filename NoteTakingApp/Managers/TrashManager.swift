import Foundation
import UIKit

class TrashManager {
    static let shared = TrashManager()

    private let fileManager = FileManager.default
    private let trashDirectory: URL

    // In-memory cache for performance
    private var trashCache: [UUID: DeletedItem] = [:]
    private let cacheQueue = DispatchQueue(label: "com.notetakingapp.trash", attributes: .concurrent)
    private var cleanupTimer: Timer?

    private init() {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        trashDirectory = documentsPath.appendingPathComponent("Trash", isDirectory: true)

        createDirectoryIfNeeded()
        // Lazy loading - cache will be populated on demand when items are accessed
        scheduleAutomaticCleanup()

        // Add lifecycle observers to stop/start cleanup timer
        NotificationCenter.default.addObserver(self, selector: #selector(stopCleanupTimer), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(startCleanupTimer), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    private func createDirectoryIfNeeded() {
        do {
            try fileManager.createDirectory(at: trashDirectory, withIntermediateDirectories: true)
        } catch {
            print("❌ Error creating trash directory: \(error.localizedDescription)")
        }
    }

    private func preloadCache() {
        cacheQueue.async(flags: .barrier) {
            do {
                let urls = try self.fileManager.contentsOfDirectory(at: self.trashDirectory, includingPropertiesForKeys: nil)
                for url in urls where url.pathExtension == "trash" {
                    do {
                        let data = try Data(contentsOf: url)
                        let item = try JSONDecoder().decode(DeletedItem.self, from: data)
                        self.trashCache[item.id] = item
                    } catch {
                        print("⚠️ Corrupted trash file: \(url.lastPathComponent) - \(error.localizedDescription)")
                    }
                }
            } catch {
                print("❌ Error preloading trash cache: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Delete Operations

    func moveToTrash(note: Note) throws {
        let data = try JSONEncoder().encode(note)
        let deletedItem = DeletedItem(
            originalID: note.id,
            name: note.name,
            type: .note,
            data: data,
            parentFolderID: note.parentFolderID
        )
        try save(deletedItem)
    }

    func moveToTrash(folder: Folder) throws {
        let data = try JSONEncoder().encode(folder)
        let deletedItem = DeletedItem(
            originalID: folder.id,
            name: folder.name,
            type: .folder,
            data: data,
            parentFolderID: folder.parentFolderID
        )
        try save(deletedItem)
    }

    // MARK: - Restore Operations

    func restore(_ item: DeletedItem) throws -> Any {
        switch item.type {
        case .note:
            let note = try JSONDecoder().decode(Note.self, from: item.data)
            try delete(item.id)
            return note
        case .folder:
            let folder = try JSONDecoder().decode(Folder.self, from: item.data)
            try delete(item.id)
            return folder
        }
    }

    // MARK: - Storage Operations

    private func save(_ item: DeletedItem) throws {
        let itemURL = trashDirectory.appendingPathComponent("\(item.id.uuidString).trash")
        let data = try JSONEncoder().encode(item)

        // Atomic write
        let tempURL = itemURL.deletingLastPathComponent().appendingPathComponent(UUID().uuidString)
        try data.write(to: tempURL)
        _ = try fileManager.replaceItemAt(itemURL, withItemAt: tempURL)

        // Update cache
        cacheQueue.async(flags: .barrier) {
            self.trashCache[item.id] = item
        }
    }

    func delete(_ id: UUID) throws {
        let itemURL = trashDirectory.appendingPathComponent("\(id.uuidString).trash")
        try fileManager.removeItem(at: itemURL)

        // Remove from cache
        cacheQueue.async(flags: .barrier) {
            self.trashCache.removeValue(forKey: id)
        }
    }

    func loadAll() -> [DeletedItem] {
        // Check if cache is empty - if so, load from disk
        var cacheIsEmpty = false
        cacheQueue.sync {
            cacheIsEmpty = trashCache.isEmpty
        }

        if cacheIsEmpty {
            // Lazy load trash items from disk
            do {
                let urls = try fileManager.contentsOfDirectory(at: trashDirectory, includingPropertiesForKeys: nil)
                for url in urls where url.pathExtension == "trash" {
                    do {
                        let data = try Data(contentsOf: url)
                        let item = try JSONDecoder().decode(DeletedItem.self, from: data)
                        cacheQueue.async(flags: .barrier) {
                            self.trashCache[item.id] = item
                        }
                    } catch {
                        print("⚠️ Corrupted trash file: \(url.lastPathComponent)")
                    }
                }
            } catch {
                print("❌ Error loading trash items: \(error.localizedDescription)")
            }
        }

        var items: [DeletedItem] = []
        cacheQueue.sync {
            items = Array(trashCache.values).sorted { $0.deletedAt > $1.deletedAt }
        }
        return items
    }

    // MARK: - Cleanup Operations

    func cleanupExpiredItems() {
        let retentionDays = AppSettings.shared.trashRetentionDays
        let items = loadAll()

        for item in items {
            if item.shouldDelete(retentionDays: retentionDays) {
                do {
                    try delete(item.id)
                    print("🗑️ Auto-deleted expired item: \(item.name)")
                } catch {
                    print("❌ Failed to auto-delete item: \(error.localizedDescription)")
                }
            }
        }
    }

    func emptyTrash() throws {
        let items = loadAll()
        for item in items {
            try delete(item.id)
        }
    }

    private func scheduleAutomaticCleanup() {
        startCleanupTimer()

        // Run cleanup on init
        DispatchQueue.global(qos: .background).async {
            self.cleanupExpiredItems()
        }
    }

    @objc private func startCleanupTimer() {
        // Avoid multiple timers
        stopCleanupTimer()

        // Run cleanup daily
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { [weak self] _ in
            self?.cleanupExpiredItems()
        }
    }

    @objc private func stopCleanupTimer() {
        cleanupTimer?.invalidate()
        cleanupTimer = nil
    }

    // MARK: - Statistics

    func getTrashSize() -> Int64 {
        var totalSize: Int64 = 0
        do {
            let urls = try fileManager.contentsOfDirectory(at: trashDirectory, includingPropertiesForKeys: [.fileSizeKey])
            for url in urls {
                let resources = try url.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(resources.fileSize ?? 0)
            }
        } catch {
            print("❌ Error calculating trash size: \(error.localizedDescription)")
        }
        return totalSize
    }
}
