import SwiftUI

struct FolderColorPickerView: View {
    @Binding var selectedColor: Color
    let onDismiss: () -> Void
    let onSave: () -> Void

    @State private var showingCustomPicker = false

    private let colors: [Color] = [
        .blue, .purple, .pink, .red, .orange, .yellow,
        .green, .teal, .cyan, .indigo, .mint
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text("Choose Color")
                .font(.headline)
                .padding(.top)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                ForEach(colors, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(Color.primary, lineWidth: 3)
                                .opacity(color.toHex() == selectedColor.toHex() ? 1 : 0)
                        )
                        .onTapGesture {
                            selectedColor = color
                            onSave()
                        }
                }

                ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                    .labelsHidden()
                    .frame(width: 44, height: 44)
                    .onChange(of: selectedColor) { _ in
                        onSave()
                    }
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
        .presentationDetents([.height(200)])
    }
}

struct GridItemView: View {
    let item: FileSystemItem
    let onTap: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void
    let onColorChange: ((String?) -> Void)?

    @State private var isPressed = false
    @State private var showingDeleteConfirmation = false
    @State private var showingColorPicker = false
    @State private var selectedColor: Color = .blue
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

                if item.isFolder, case .folder(let folder) = item {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 56, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [folder.color, folder.color.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: folder.color.opacity(0.3), radius: 8, x: 0, y: 4)
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
            if item.isFolder {
                Button {
                    if case .folder(let folder) = item {
                        selectedColor = folder.color
                    }
                    showingColorPicker = true
                } label: {
                    Label("Change Color", systemImage: "paintpalette")
                }
            }

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
        .sheet(isPresented: $showingColorPicker) {
            FolderColorPickerView(
                selectedColor: $selectedColor,
                onDismiss: { showingColorPicker = false },
                onSave: {
                    onColorChange?(selectedColor.toHex())
                    showingColorPicker = false
                }
            )
        }
    }
}
