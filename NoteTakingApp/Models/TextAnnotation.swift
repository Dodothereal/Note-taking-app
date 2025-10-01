import Foundation
import UIKit

struct TextAnnotation: Identifiable, Codable {
    let id: UUID
    var text: String
    var position: CGPoint
    var fontSize: CGFloat
    var fontName: String
    var color: CodableColor
    var width: CGFloat
    var createdAt: Date
    var modifiedAt: Date

    init(id: UUID = UUID(), text: String, position: CGPoint, fontSize: CGFloat = 17, fontName: String = "Helvetica", color: CodableColor = CodableColor(uiColor: .black), width: CGFloat = 200) {
        self.id = id
        self.text = text
        self.position = position
        self.fontSize = fontSize
        self.fontName = fontName
        self.color = color
        self.width = width
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}

// Helper struct to encode/decode UIColor
struct CodableColor: Codable {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    var alpha: CGFloat

    init(uiColor: UIColor) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.red = r
        self.green = g
        self.blue = b
        self.alpha = a
    }

    var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
