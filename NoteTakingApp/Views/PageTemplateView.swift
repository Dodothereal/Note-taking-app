import SwiftUI

struct PageTemplateView: View {
    let template: PageTemplate
    let size: CGSize

    var body: some View {
        Canvas { context, canvasSize in
            switch template {
            case .blank:
                break
            case .grid:
                drawGrid(context: context, size: canvasSize)
            case .dotted:
                drawDotted(context: context, size: canvasSize)
            case .lined:
                drawLined(context: context, size: canvasSize)
            }
        }
    }

    private func drawGrid(context: GraphicsContext, size: CGSize) {
        let spacing: CGFloat = 20
        var path = Path()

        // Vertical lines
        var x: CGFloat = 0
        while x <= size.width {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            x += spacing
        }

        // Horizontal lines
        var y: CGFloat = 0
        while y <= size.height {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            y += spacing
        }

        context.stroke(path, with: .color(.gray.opacity(0.2)), lineWidth: 0.5)
    }

    private func drawDotted(context: GraphicsContext, size: CGSize) {
        let spacing: CGFloat = 20
        var path = Path()

        var y: CGFloat = 0
        while y <= size.height {
            var x: CGFloat = 0
            while x <= size.width {
                path.addEllipse(in: CGRect(x: x - 1, y: y - 1, width: 2, height: 2))
                x += spacing
            }
            y += spacing
        }

        context.fill(path, with: .color(.gray.opacity(0.3)))
    }

    private func drawLined(context: GraphicsContext, size: CGSize) {
        let spacing: CGFloat = 30
        var path = Path()

        var y: CGFloat = spacing
        while y <= size.height {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            y += spacing
        }

        context.stroke(path, with: .color(.gray.opacity(0.2)), lineWidth: 0.5)
    }
}
