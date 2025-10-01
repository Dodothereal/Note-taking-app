import Foundation
import UIKit

struct ImageAnnotation: Identifiable, Codable {
    let id: UUID
    var imageData: Data
    var position: CGPoint
    var size: CGSize
    var rotation: CGFloat // in radians
    var createdAt: Date
    var modifiedAt: Date

    init(id: UUID = UUID(), imageData: Data, position: CGPoint, size: CGSize, rotation: CGFloat = 0) {
        self.id = id
        self.imageData = imageData
        self.position = position
        self.size = size
        self.rotation = rotation
        self.createdAt = Date()
        self.modifiedAt = Date()
    }

    var image: UIImage? {
        UIImage(data: imageData)
    }
}
