import SwiftUI
import PencilKit

struct PageThumbnailsView: View {
    @Binding var pages: [NotePage]
    @Binding var currentPageIndex: Int
    let onAddPage: () -> Void
    let onDeletePage: (Int) -> Void
    @ObservedObject var settings = AppSettings.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header with glass effect
            HStack {
                Image(systemName: "doc.on.doc.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Pages")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.regularMaterial)
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(.white.opacity(0.2)),
                alignment: .bottom
            )

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        pageThumbnail(page: page, index: index)
                    }

                    // Add page button with glass effect
                    Button {
                        onAddPage()
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .blue.opacity(0.7)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            Text("Add Page")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.blue)
                        }
                        .frame(width: 110, height: 150)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1.5)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [.white.opacity(0.3), .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 0.5
                                )
                        )
                        .shadow(color: .blue.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.vertical, 16)
            }
        }
        .frame(width: 160)
        .background(.regularMaterial)
        .overlay(
            Rectangle()
                .frame(width: 0.5)
                .foregroundColor(.white.opacity(0.2)),
            alignment: .leading
        )
    }

    @ViewBuilder
    private func pageThumbnail(page: NotePage, index: Int) -> some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                // Thumbnail with glass effect
                ZStack {
                    if let thumbnailData = page.thumbnail,
                       let uiImage = UIImage(data: thumbnailData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 110, height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .conditionalColorInvert(settings.nightModeEnabled && settings.nightModeInvertDrawings)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: settings.nightModeEnabled ? [Color.black, Color(.systemGray5)] : [.white, Color(.systemGray6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 110, height: 150)
                            .overlay(
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.tertiary)
                            )
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            currentPageIndex == index ?
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            ) :
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: currentPageIndex == index ? 2.5 : 0.5
                        )
                )
                .shadow(
                    color: currentPageIndex == index ? .blue.opacity(0.3) : .black.opacity(0.1),
                    radius: currentPageIndex == index ? 8 : 4,
                    x: 0,
                    y: currentPageIndex == index ? 4 : 2
                )
                .scaleEffect(currentPageIndex == index ? 1.0 : 0.95)

                // Delete button with glass effect
                if pages.count > 1 {
                    Button {
                        onDeletePage(index)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.red)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 24, height: 24)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                    }
                    .offset(x: 6, y: -6)
                }
            }

            // Page label with glass effect
            Text("Page \(index + 1)")
                .font(.caption.weight(.medium))
                .foregroundStyle(currentPageIndex == index ? .primary : .secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background {
                    if currentPageIndex == index {
                        Capsule()
                            .fill(.thinMaterial)
                    }
                }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                currentPageIndex = index
            }
        }
    }
}
