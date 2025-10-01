import Foundation
import PencilKit
import UIKit

// MARK: - Constants

private enum ThumbnailConstants {
    static let size = CGSize(width: 200, height: 200)
    static let debounceDelay: TimeInterval = 0.5
}

enum PageTemplate: String, Codable {
    case blank
    case grid
    case dotted
    case lined
}

enum PageSize: Codable, Equatable {
    case a4

    var size: CGSize {
        // A4 at 72 DPI: 8.27 × 11.69 inches = 595 × 842 points
        return CGSize(width: 595, height: 842)
    }

    var displayName: String {
        return "A4"
    }
}

struct NotePage: Identifiable, Codable {
    let id: UUID
    var drawingData: Data
    var thumbnail: Data?
    var template: PageTemplate
    var createdAt: Date
    var modifiedAt: Date

    init(id: UUID = UUID(), drawingData: Data = Data(), template: PageTemplate = .blank, createdAt: Date = Date(), modifiedAt: Date = Date()) {
        self.id = id
        self.drawingData = drawingData
        self.template = template
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    var drawing: PKDrawing {
        get {
            guard !drawingData.isEmpty else {
                return PKDrawing()
            }

            do {
                return try PKDrawing(data: drawingData)
            } catch {
                print("⚠️ Failed to load drawing for page \(id): \(error.localizedDescription)")
                print("⚠️ Drawing data size: \(drawingData.count) bytes - returning empty drawing")
                // Return empty drawing if data is corrupted
                return PKDrawing()
            }
        }
        set {
            drawingData = newValue.dataRepresentation()
            modifiedAt = Date()
        }
    }
}

struct Note: Identifiable, Codable {
    let id: UUID
    var name: String
    var pages: [NotePage]
    var createdAt: Date
    var modifiedAt: Date
    var parentFolderID: UUID?
    var defaultPageSize: PageSize

    init(id: UUID = UUID(), name: String, parentFolderID: UUID? = nil, defaultPageSize: PageSize = .a4) {
        self.id = id
        self.name = name
        self.pages = [NotePage()]
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.parentFolderID = parentFolderID
        self.defaultPageSize = defaultPageSize
    }

    var thumbnailData: Data? {
        pages.first?.thumbnail
    }

    mutating func addPage(template: PageTemplate = .blank) {
        pages.append(NotePage(template: template))
        modifiedAt = Date()
    }

    mutating func deletePage(at index: Int) {
        guard pages.count > 1, index >= 0, index < pages.count else { return }
        pages.remove(at: index)
        modifiedAt = Date()
    }

    mutating func updatePage(at index: Int, with drawing: PKDrawing) {
        guard index >= 0, index < pages.count else { return }
        pages[index].drawing = drawing
        modifiedAt = Date()

        // Update thumbnail for first page
        if index == 0 {
            generateThumbnail(for: index)
        }
    }

    mutating func generateThumbnail(for pageIndex: Int, completion: ((Data?) -> Void)? = nil) {
        guard pageIndex >= 0, pageIndex < pages.count else {
            print("⚠️ Cannot generate thumbnail - invalid page index: \(pageIndex)")
            completion?(nil)
            return
        }

        let drawing = pages[pageIndex].drawing

        // Skip if drawing is empty
        guard !drawing.bounds.isEmpty && drawing.bounds.width > 0 && drawing.bounds.height > 0 else {
            print("⚠️ Skipping thumbnail generation - empty drawing bounds")
            pages[pageIndex].thumbnail = nil
            completion?(nil)
            return
        }

        // Constants
        let thumbnailSize = ThumbnailConstants.size
        let drawingBounds = drawing.bounds

        // Generate thumbnail on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            let image = drawing.image(from: drawingBounds, scale: 1.0)

            let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
            let thumbnail = renderer.image { context in
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: thumbnailSize))

                let drawingAspect = drawingBounds.width / drawingBounds.height
                let thumbnailAspect = thumbnailSize.width / thumbnailSize.height

                var rect = CGRect.zero
                if drawingAspect > thumbnailAspect {
                    let height = thumbnailSize.width / drawingAspect
                    rect = CGRect(x: 0, y: (thumbnailSize.height - height) / 2, width: thumbnailSize.width, height: height)
                } else {
                    let width = thumbnailSize.height * drawingAspect
                    rect = CGRect(x: (thumbnailSize.width - width) / 2, y: 0, width: width, height: thumbnailSize.height)
                }

                image.draw(in: rect)
            }

            let thumbnailData = thumbnail.pngData()

            DispatchQueue.main.async {
                completion?(thumbnailData)
            }
        }
    }
}
