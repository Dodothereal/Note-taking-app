import Foundation
import UIKit

enum ShapeType: String, Codable {
    case rectangle
    case circle
    case line
    case arrow
    case triangle
}

struct ShapeAnnotation: Identifiable, Codable {
    let id: UUID
    var type: ShapeType
    var startPoint: CGPoint
    var endPoint: CGPoint
    var strokeColor: CodableColor
    var fillColor: CodableColor?
    var lineWidth: CGFloat
    var createdAt: Date
    var modifiedAt: Date

    init(id: UUID = UUID(), type: ShapeType, startPoint: CGPoint, endPoint: CGPoint, strokeColor: CodableColor = CodableColor(uiColor: .black), fillColor: CodableColor? = nil, lineWidth: CGFloat = 2.0) {
        self.id = id
        self.type = type
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.strokeColor = strokeColor
        self.fillColor = fillColor
        self.lineWidth = lineWidth
        self.createdAt = Date()
        self.modifiedAt = Date()
    }

    var rect: CGRect {
        CGRect(
            x: min(startPoint.x, endPoint.x),
            y: min(startPoint.y, endPoint.y),
            width: abs(endPoint.x - startPoint.x),
            height: abs(endPoint.y - startPoint.y)
        )
    }
}
