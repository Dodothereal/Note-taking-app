import Foundation

enum DeletedItemType: String, Codable {
    case note
    case folder
}

struct DeletedItem: Identifiable, Codable {
    let id: UUID
    let originalID: UUID
    let name: String
    let type: DeletedItemType
    let deletedAt: Date
    let data: Data // Encoded Note or Folder
    let parentFolderID: UUID?

    init(id: UUID = UUID(), originalID: UUID, name: String, type: DeletedItemType, deletedAt: Date = Date(), data: Data, parentFolderID: UUID? = nil) {
        self.id = id
        self.originalID = originalID
        self.name = name
        self.type = type
        self.deletedAt = deletedAt
        self.data = data
        self.parentFolderID = parentFolderID
    }

    func shouldDelete(retentionDays: Int?) -> Bool {
        guard let days = retentionDays else {
            return false // Keep forever
        }

        let daysSinceDeletion = Calendar.current.dateComponents([.day], from: deletedAt, to: Date()).day ?? 0
        return daysSinceDeletion >= days
    }
}
