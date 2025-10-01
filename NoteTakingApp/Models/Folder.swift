import Foundation

struct Folder: Identifiable, Codable {
    let id: UUID
    var name: String
    var createdAt: Date
    var modifiedAt: Date
    var parentFolderID: UUID?

    init(id: UUID = UUID(), name: String, parentFolderID: UUID? = nil) {
        self.id = id
        self.name = name
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.parentFolderID = parentFolderID
    }
}

enum FileSystemItem: Identifiable {
    case folder(Folder)
    case note(Note)

    var id: UUID {
        switch self {
        case .folder(let folder):
            return folder.id
        case .note(let note):
            return note.id
        }
    }

    var name: String {
        switch self {
        case .folder(let folder):
            return folder.name
        case .note(let note):
            return note.name
        }
    }

    var modifiedAt: Date {
        switch self {
        case .folder(let folder):
            return folder.modifiedAt
        case .note(let note):
            return note.modifiedAt
        }
    }

    var isFolder: Bool {
        if case .folder = self { return true }
        return false
    }
}
