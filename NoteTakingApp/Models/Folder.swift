import Foundation
import SwiftUI

struct Folder: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var createdAt: Date
    var modifiedAt: Date
    var parentFolderID: UUID?
    var colorHex: String?

    init(id: UUID = UUID(), name: String, parentFolderID: UUID? = nil, colorHex: String? = nil) {
        self.id = id
        self.name = name
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.parentFolderID = parentFolderID
        self.colorHex = colorHex
    }

    var color: Color {
        if let colorHex = colorHex, let color = Color(hex: colorHex) {
            return color
        }
        return .blue
    }
}

enum FileSystemItem: Identifiable, Equatable {
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

    var createdAt: Date {
        switch self {
        case .folder(let folder):
            return folder.createdAt
        case .note(let note):
            return note.createdAt
        }
    }

    var isFolder: Bool {
        if case .folder = self { return true }
        return false
    }
}
