import Foundation
import PDFKit
import UIKit

class PDFImporter {
    static func importPDF(from url: URL, name: String, parentFolderID: UUID?) -> Note? {
        guard let pdfDocument = PDFDocument(url: url) else {
            print("❌ Failed to load PDF from URL: \(url)")
            return nil
        }

        let pageCount = pdfDocument.pageCount
        guard pageCount > 0 else {
            print("⚠️ PDF has no pages")
            return nil
        }

        // Create note
        var note = Note(name: name, parentFolderID: parentFolderID)
        note.pages.removeAll() // Remove default blank page

        // Convert each PDF page to a NotePage with image annotation
        for pageIndex in 0..<pageCount {
            guard let pdfPage = pdfDocument.page(at: pageIndex) else {
                print("⚠️ Failed to load PDF page \(pageIndex)")
                continue
            }

            let notePage = createNotePage(from: pdfPage, index: pageIndex)
            note.pages.append(notePage)
        }

        if note.pages.isEmpty {
            print("❌ No pages were imported from PDF")
            return nil
        }

        print("✅ Successfully imported PDF with \(note.pages.count) pages")
        return note
    }

    private static func createNotePage(from pdfPage: PDFPage, index: Int) -> NotePage {
        // Get PDF page bounds
        let pageRect = pdfPage.bounds(for: .mediaBox)

        // Determine target size (use Note's default page size)
        let targetSize = PageSize.a4.size

        // Render PDF page to image
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let pageImage = renderer.image { context in
            // Fill white background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: targetSize))

            // Calculate scaling to fit PDF page into target size
            let scaleX = targetSize.width / pageRect.width
            let scaleY = targetSize.height / pageRect.height
            let scale = min(scaleX, scaleY)

            let scaledWidth = pageRect.width * scale
            let scaledHeight = pageRect.height * scale

            let x = (targetSize.width - scaledWidth) / 2
            let y = (targetSize.height - scaledHeight) / 2

            let drawRect = CGRect(x: x, y: y, width: scaledWidth, height: scaledHeight)

            // Draw PDF page
            context.cgContext.saveGState()
            context.cgContext.translateBy(x: drawRect.minX, y: drawRect.maxY)
            context.cgContext.scaleBy(x: scale, y: -scale)
            context.cgContext.translateBy(x: -pageRect.minX, y: -pageRect.minY)
            pdfPage.draw(with: .mediaBox, to: context.cgContext)
            context.cgContext.restoreGState()
        }

        // Convert image to data
        guard let imageData = pageImage.jpegData(compressionQuality: 0.9) else {
            print("⚠️ Failed to convert PDF page \(index) to image data")
            return NotePage(template: .blank)
        }

        // Create image annotation for the PDF page
        let imageAnnotation = ImageAnnotation(
            imageData: imageData,
            position: .zero,
            size: targetSize
        )

        // Create NotePage with the image annotation
        var notePage = NotePage(template: .blank)
        notePage.imageAnnotations = [imageAnnotation]

        return notePage
    }
}
