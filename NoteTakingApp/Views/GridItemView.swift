import SwiftUI

struct GridItemView: View {
    let item: FileSystemItem
    let onTap: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void

    @State private var isPressed = false
    @State private var showingDeleteConfirmation = false
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        VStack(spacing: 12) {
            // Thumbnail or folder icon with glass effect
            ZStack {
                // Background with subtle gradient (adapts to night mode)
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: settings.nightModeEnabled ? [
                                Color.black,
                                Color(.systemGray5)
                            ] : [
                                Color(.systemBackground),
                                Color(.systemGray6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(1, contentMode: .fit)

                // Glass overlay
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .aspectRatio(1, contentMode: .fit)

                if item.isFolder {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 56, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                } else if case .note(let note) = item, let thumbnailData = note.thumbnailData,
                          let uiImage = UIImage(data: thumbnailData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .conditionalColorInvert(settings.nightModeEnabled && settings.nightModeInvertDrawings)
                } else {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 56, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.gray, .gray.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .gray.opacity(0.2), radius: 6, x: 0, y: 3)
                }
            }
            .frame(height: 160)
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)

            // Name with subtle background
            Text(item.name)
                .font(.subheadline.weight(.medium))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .frame(height: 40)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .opacity(0.5)
                )
        }
        .frame(width: 160)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
                onTap()
            }
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

            // Show delete confirmation
            showingDeleteConfirmation = true
        }
        .onDrag {
            // Create NSItemProvider for drag operation
            let itemData = try? JSONEncoder().encode(item.id.uuidString)
            return NSItemProvider(item: itemData as? NSSecureCoding, typeIdentifier: "public.data")
        }
        .contextMenu {
            Button {
                onRename()
            } label: {
                Label("Rename", systemImage: "pencil")
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .alert("Delete \(item.name)?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
                onDelete()
            }
        } message: {
            Text("This item will be moved to Recently Deleted.")
        }
    }
}
