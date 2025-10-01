import Foundation
import PDFKit
import PencilKit
import UIKit

class PDFExporter {
    // Reusable CIContext for better performance
    private static let ciContext = CIContext()

    static func exportNote(_ note: Note, nightMode: Bool = false) -> URL? {
        let pdfDocument = PDFDocument()
        let settings = AppSettings.shared

        for (index, page) in note.pages.enumerated() {
            guard let pdfPage = createPDFPage(from: page, pageSize: note.defaultPageSize, nightMode: nightMode) else {
                print("⚠️ Failed to create PDF page \(index)")
                continue
            }
            pdfDocument.insert(pdfPage, at: index)
        }

        // Save to temporary directory
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(note.name).pdf")

        if pdfDocument.write(to: tempURL) {
            print("✅ PDF exported to: \(tempURL.path)")
            return tempURL
        } else {
            print("❌ Failed to write PDF")
            return nil
        }
    }

    private static func createPDFPage(from notePage: NotePage, pageSize: PageSize, nightMode: Bool) -> PDFPage? {
        let size = pageSize.size
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            let cgContext = context.cgContext

            // Background
            if nightMode {
                UIColor.black.setFill()
            } else {
                UIColor.white.setFill()
            }
            cgContext.fill(CGRect(origin: .zero, size: size))

            // Template background
            drawTemplate(notePage.template, in: cgContext, size: size, nightMode: nightMode)

            // Drawing layer
            let drawing = notePage.drawing
            if !drawing.bounds.isEmpty {
                var drawnImage = drawing.image(from: CGRect(origin: .zero, size: size), scale: 1.0)

                // Apply night mode inversion if enabled
                if nightMode && AppSettings.shared.nightModeInvertDrawings {
                    drawnImage = invertImage(drawnImage) ?? drawnImage
                }

                drawnImage.draw(in: CGRect(origin: .zero, size: size))
            }

            // Shape annotations
            for shape in notePage.shapeAnnotations {
                drawShape(shape, in: cgContext, nightMode: nightMode)
            }

            // Image annotations
            for imageAnnotation in notePage.imageAnnotations {
                if let image = imageAnnotation.image {
                    cgContext.saveGState()

                    // Apply rotation
                    if imageAnnotation.rotation != 0 {
                        let center = CGPoint(
                            x: imageAnnotation.position.x + imageAnnotation.size.width / 2,
                            y: imageAnnotation.position.y + imageAnnotation.size.height / 2
                        )
                        cgContext.translateBy(x: center.x, y: center.y)
                        cgContext.rotate(by: imageAnnotation.rotation)
                        cgContext.translateBy(x: -center.x, y: -center.y)
                    }

                    var finalImage = image
                    if nightMode && AppSettings.shared.nightModeInvertImages {
                        finalImage = invertImage(image) ?? image
                    }

                    finalImage.draw(in: CGRect(origin: imageAnnotation.position, size: imageAnnotation.size))
                    cgContext.restoreGState()
                }
            }

            // Text annotations
            for textAnnotation in notePage.textAnnotations {
                var color = textAnnotation.color.uiColor
                if nightMode && AppSettings.shared.nightModeInvertText {
                    color = invertColor(color)
                }

                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineBreakMode = .byWordWrapping

                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont(name: textAnnotation.fontName, size: textAnnotation.fontSize) ?? UIFont.systemFont(ofSize: textAnnotation.fontSize),
                    .foregroundColor: color,
                    .paragraphStyle: paragraphStyle
                ]

                let rect = CGRect(
                    origin: textAnnotation.position,
                    size: CGSize(width: textAnnotation.width, height: .greatestFiniteMagnitude)
                )

                textAnnotation.text.draw(in: rect, withAttributes: attributes)
            }
        }

        // Create PDF page from image
        let pdfPage = PDFPage(image: image)
        return pdfPage
    }

    private static func drawTemplate(_ template: PageTemplate, in context: CGContext, size: CGSize, nightMode: Bool) {
        let settings = AppSettings.shared
        let scale = settings.resolutionScale

        var strokeColor = UIColor.gray.withAlphaComponent(0.2)
        if nightMode {
            strokeColor = UIColor.white.withAlphaComponent(0.2)
        }

        context.setStrokeColor(strokeColor.cgColor)
        context.setLineWidth(1.0 * scale)

        switch template {
        case .blank:
            break
        case .grid:
            let spacing = settings.gridSpacing * scale
            var x: CGFloat = 0
            while x <= size.width {
                context.move(to: CGPoint(x: x, y: 0))
                context.addLine(to: CGPoint(x: x, y: size.height))
                x += spacing
            }
            var y: CGFloat = 0
            while y <= size.height {
                context.move(to: CGPoint(x: 0, y: y))
                context.addLine(to: CGPoint(x: size.width, y: y))
                y += spacing
            }
            context.strokePath()
        case .dotted:
            let spacing = settings.gridSpacing * scale
            let dotSize = 2.0 * scale
            var fillColor = UIColor.gray.withAlphaComponent(0.3)
            if nightMode {
                fillColor = UIColor.white.withAlphaComponent(0.3)
            }
            context.setFillColor(fillColor.cgColor)
            var y: CGFloat = 0
            while y <= size.height {
                var x: CGFloat = 0
                while x <= size.width {
                    let rect = CGRect(x: x - dotSize / 2, y: y - dotSize / 2, width: dotSize, height: dotSize)
                    context.fillEllipse(in: rect)
                    x += spacing
                }
                y += spacing
            }
        case .lined:
            let spacing = settings.linedSpacing * scale
            var y: CGFloat = spacing
            while y <= size.height {
                context.move(to: CGPoint(x: 0, y: y))
                context.addLine(to: CGPoint(x: size.width, y: y))
                y += spacing
            }
            context.strokePath()
        }
    }

    private static func drawShape(_ shape: ShapeAnnotation, in context: CGContext, nightMode: Bool) {
        context.saveGState()

        var strokeColor = shape.strokeColor.uiColor
        if nightMode && AppSettings.shared.nightModeInvertDrawings {
            strokeColor = invertColor(strokeColor)
        }
        context.setStrokeColor(strokeColor.cgColor)
        context.setLineWidth(shape.lineWidth)

        if let fillColor = shape.fillColor {
            var fill = fillColor.uiColor
            if nightMode && AppSettings.shared.nightModeInvertDrawings {
                fill = invertColor(fill)
            }
            context.setFillColor(fill.cgColor)
        }

        switch shape.type {
        case .rectangle:
            let rect = shape.rect
            if shape.fillColor != nil {
                context.fill(rect)
            }
            context.stroke(rect)
        case .circle:
            let rect = shape.rect
            if shape.fillColor != nil {
                context.fillEllipse(in: rect)
            }
            context.strokeEllipse(in: rect)
        case .line:
            context.move(to: shape.startPoint)
            context.addLine(to: shape.endPoint)
            context.strokePath()
        case .arrow:
            drawArrow(from: shape.startPoint, to: shape.endPoint, in: context)
        case .triangle:
            let rect = shape.rect
            let top = CGPoint(x: rect.midX, y: rect.minY)
            let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)
            let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)
            context.move(to: top)
            context.addLine(to: bottomLeft)
            context.addLine(to: bottomRight)
            context.closePath()
            if shape.fillColor != nil {
                context.fillPath()
            }
            context.strokePath()
        }

        context.restoreGState()
    }

    private static func drawArrow(from start: CGPoint, to end: CGPoint, in context: CGContext) {
        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()

        // Arrowhead
        let angle = atan2(end.y - start.y, end.x - start.x)
        let arrowLength: CGFloat = 15
        let arrowAngle: CGFloat = .pi / 6

        let point1 = CGPoint(
            x: end.x - arrowLength * cos(angle - arrowAngle),
            y: end.y - arrowLength * sin(angle - arrowAngle)
        )
        let point2 = CGPoint(
            x: end.x - arrowLength * cos(angle + arrowAngle),
            y: end.y - arrowLength * sin(angle + arrowAngle)
        )

        context.move(to: end)
        context.addLine(to: point1)
        context.move(to: end)
        context.addLine(to: point2)
        context.strokePath()
    }

    private static func invertImage(_ image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }

        guard let filter = CIFilter(name: "CIColorInvert") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)

        guard let outputImage = filter.outputImage else { return nil }

        // Use shared context for better performance
        guard let cgImage = ciContext.createCGImage(outputImage, from: outputImage.extent) else { return nil }

        return UIImage(cgImage: cgImage)
    }

    private static func invertColor(_ color: UIColor) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: 1 - r, green: 1 - g, blue: 1 - b, alpha: a)
    }
}
