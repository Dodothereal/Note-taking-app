import SwiftUI
import UIKit

struct PageTemplateView: UIViewRepresentable {
    let template: PageTemplate
    let size: CGSize
    let nightMode: Bool
    @ObservedObject var settings = AppSettings.shared

    func makeUIView(context: Context) -> TemplateUIView {
        let view = TemplateUIView()
        view.backgroundColor = .white
        view.isOpaque = true
        return view
    }

    func updateUIView(_ uiView: TemplateUIView, context: Context) {
        uiView.template = template
        uiView.size = size
        uiView.gridSpacing = settings.gridSpacing
        uiView.linedSpacing = settings.linedSpacing
        uiView.resolutionScale = settings.resolutionScale
        uiView.nightMode = nightMode
        uiView.backgroundColor = nightMode ? .black : .white
        uiView.setNeedsDisplay()
    }
}

class TemplateUIView: UIView {
    var template: PageTemplate = .blank
    var size: CGSize = .zero
    var gridSpacing: Double = 20.0
    var linedSpacing: Double = 30.0
    var resolutionScale: Double = 3.0
    var nightMode: Bool = false

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        // Fill background (white or black based on night mode)
        context.setFillColor(nightMode ? UIColor.black.cgColor : UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        switch template {
        case .blank:
            break
        case .grid:
            drawGrid(context: context)
        case .dotted:
            drawDotted(context: context)
        case .lined:
            drawLined(context: context)
        }
    }

    private func drawGrid(context: CGContext) {
        let scale = resolutionScale
        let spacing = gridSpacing * scale

        let strokeColor = nightMode ? UIColor.white.withAlphaComponent(0.2) : UIColor.gray.withAlphaComponent(0.2)
        context.setStrokeColor(strokeColor.cgColor)
        context.setLineWidth(1.0 * scale)

        // Vertical lines
        var x: CGFloat = 0
        while x <= size.width {
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: size.height))
            x += spacing
        }

        // Horizontal lines
        var y: CGFloat = 0
        while y <= size.height {
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: size.width, y: y))
            y += spacing
        }

        context.strokePath()
    }

    private func drawDotted(context: CGContext) {
        let scale = resolutionScale
        let spacing = gridSpacing * scale
        let dotSize = 2.0 * scale

        let fillColor = nightMode ? UIColor.white.withAlphaComponent(0.3) : UIColor.gray.withAlphaComponent(0.3)
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
    }

    private func drawLined(context: CGContext) {
        let scale = resolutionScale
        let spacing = linedSpacing * scale

        let strokeColor = nightMode ? UIColor.white.withAlphaComponent(0.2) : UIColor.gray.withAlphaComponent(0.2)
        context.setStrokeColor(strokeColor.cgColor)
        context.setLineWidth(1.0 * scale)

        var y: CGFloat = spacing
        while y <= size.height {
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: size.width, y: y))
            y += spacing
        }

        context.strokePath()
    }

    override var intrinsicContentSize: CGSize {
        return size
    }
}
