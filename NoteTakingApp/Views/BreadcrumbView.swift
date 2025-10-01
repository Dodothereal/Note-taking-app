import SwiftUI

struct BreadcrumbView: View {
    let path: [Folder]
    let onNavigate: (UUID?) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                // Root with glass effect
                Button {
                    onNavigate(nil)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "house.fill")
                            .font(.subheadline)
                        Text("All Notes")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(path.isEmpty ? .primary : Color.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(path.isEmpty ? .regularMaterial : .ultraThinMaterial)
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }

                // Path
                ForEach(Array(path.enumerated()), id: \.element.id) { index, folder in
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)

                        Button {
                            onNavigate(folder.id)
                        } label: {
                            Text(folder.name)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(index == path.count - 1 ? .primary : Color.blue)
                                .lineLimit(1)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(index == path.count - 1 ? .regularMaterial : .ultraThinMaterial)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                                )
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(height: 50)
        .background(.ultraThinMaterial)
    }
}
