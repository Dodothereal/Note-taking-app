import SwiftUI
import PencilKit

// MARK: - Constants

private enum EditorConstants {
    static let thumbnailDebounceDelay: TimeInterval = 0.5
    static let toolPickerInitialDelay: TimeInterval = 0.4
    static let toolPickerRetryDelay: TimeInterval = 0.1
    static let toolPickerFirstResponderDelay: TimeInterval = 0.2
}

struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var settings = AppSettings.shared
    @State private var note: Note
    @State private var currentPageIndex: Int = 0
    @State private var showPageThumbnails = false
    @State private var showNoteSettings = false
    @State private var currentDrawing: PKDrawing = PKDrawing()
    @State private var previousPageIndex: Int = 0
    @State private var skipOnChange: Bool = false
    @State private var zoomScale: CGFloat = 1.0
    @State private var baseZoomScale: CGFloat = 1.0
    @State private var autoSaveTimer: Timer?

    let viewModel: NotesViewModel

    init(note: Note, viewModel: NotesViewModel) {
        _note = State(initialValue: note)
        self.viewModel = viewModel
    }

    private var isPageValid: Bool {
        !note.pages.isEmpty && currentPageIndex >= 0 && currentPageIndex < note.pages.count
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    if isPageValid {
                        // Current page view with zoomable scroll view
                        ZStack {
                            // Black background to show page boundaries
                            Color.black
                                .ignoresSafeArea()

                            ZoomableScrollView(
                                zoomScale: $zoomScale,
                                doubleTapToReset: true,
                                maxZoomScale: settings.maxZoomLevel
                            ) {
                                ZStack {
                                    // White background
                                    Color.white

                                    // Template background - with ID to force re-render
                                    PageTemplateView(
                                        template: note.pages[currentPageIndex].template,
                                        size: note.defaultPageSize.size
                                    )
                                    .id("\(note.pages[currentPageIndex].id)-\(note.pages[currentPageIndex].template)")
                                    .allowsHitTesting(false)

                                    // Canvas for drawing (only one instance)
                                    CanvasView(
                                        drawing: $currentDrawing,
                                        onDrawingChanged: { drawing in
                                            // Update binding immediately to prevent drawing from disappearing
                                            currentDrawing = drawing
                                        }
                                    )
                                }
                                .frame(width: note.defaultPageSize.size.width, height: note.defaultPageSize.size.height)
                            }
                        }
                        .overlay(pageIndicator)
                    } else {
                        // Error state
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(.red)
                            Text("Error loading page")
                                .font(.headline)
                                .padding()
                        }
                    }

                    // Page thumbnails sidebar
                    if showPageThumbnails {
                        PageThumbnailsView(
                            pages: $note.pages,
                            currentPageIndex: $currentPageIndex,
                            onAddPage: {
                                addPage()
                            },
                            onDeletePage: { index in
                                deletePage(at: index)
                            }
                        )
                    }
                }
            }
            .navigationTitle(note.name)
            .onChange(of: currentPageIndex) { oldIndex, newIndex in
                // Skip if flagged (e.g., during addPage/deletePage which handle their own loading)
                if skipOnChange {
                    skipOnChange = false
                    return
                }

                // Save drawing when page changes (via swipe, thumbnail tap, etc.)
                if oldIndex >= 0 && oldIndex < note.pages.count && oldIndex != newIndex {
                    print("📄 Page changed from \(oldIndex) to \(newIndex), saving and loading")

                    // Save the current drawing to the OLD page (before we load the new page)
                    updateDrawing(at: oldIndex, with: currentDrawing)

                    // Now load the new page
                    loadCurrentPage()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    doneButton
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    toolbarControls
                }
            }
            .onAppear {
                print("🚀 NoteEditorView appeared")
                print("📊 Note: \(note.name)")
                print("📊 Total pages: \(note.pages.count)")
                print("📊 Current page index: \(currentPageIndex)")

                // Ensure valid page index
                if currentPageIndex >= note.pages.count {
                    print("⚠️ Page index out of bounds, adjusting: \(currentPageIndex) -> \(max(0, note.pages.count - 1))")
                    currentPageIndex = max(0, note.pages.count - 1)
                }
                if currentPageIndex < 0 {
                    print("⚠️ Page index negative, adjusting to 0")
                    currentPageIndex = 0
                }
                loadCurrentPage()

                // Start auto-save timer
                startAutoSave()
            }
            .onDisappear {
                // Stop auto-save timer
                stopAutoSave()
            }
            .sheet(isPresented: $showNoteSettings) {
                NoteSettingsView(note: $note, currentPageIndex: currentPageIndex)
            }
        }
    }

    private var pageIndicator: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "doc.text.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("Page \(currentPageIndex + 1) of \(note.pages.count)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.regularMaterial)
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                .padding(16)
            }
        }
    }

    private var doneButton: some View {
        Button {
            saveAndDismiss()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .font(.subheadline.weight(.semibold))
                Text("Done")
                    .font(.body.weight(.medium))
            }
            .foregroundStyle(.blue)
        }
    }

    private var toolbarControls: some View {
        HStack(spacing: 12) {
            // Note settings button
            Button {
                showNoteSettings = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.blue)
            }

            Divider()
                .frame(height: 20)

            // Sidebar toggle
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showPageThumbnails.toggle()
                }
            } label: {
                Image(systemName: showPageThumbnails ? "sidebar.right" : "sidebar.left")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.blue)
            }
        }
    }

    private func updateDrawing(at index: Int, with drawing: PKDrawing) {
        guard index >= 0 && index < note.pages.count else {
            print("⚠️ Cannot update drawing - invalid index: \(index)")
            return
        }

        print("✏️ Updating drawing for page \(index)")
        note.updatePage(at: index, with: drawing)

        // Debounce thumbnail generation
        DispatchQueue.main.asyncAfter(deadline: .now() + EditorConstants.thumbnailDebounceDelay) {
            guard index < note.pages.count else { return }
            print("📸 Generating thumbnail for page \(index)")
            note.generateThumbnail(for: index) { thumbnailData in
                if let data = thumbnailData, index < note.pages.count {
                    note.pages[index].thumbnail = data
                }
            }
        }
    }

    private func loadCurrentPage() {
        guard !note.pages.isEmpty else {
            print("⚠️ Cannot load page - no pages available")
            currentDrawing = PKDrawing()
            return
        }

        // Ensure valid index
        if currentPageIndex < 0 || currentPageIndex >= note.pages.count {
            print("⚠️ Invalid page index: \(currentPageIndex), adjusting to 0")
            currentPageIndex = 0
        }

        print("📄 Loading page \(currentPageIndex)")
        currentDrawing = note.pages[currentPageIndex].drawing
    }

    private func nextPage() {
        guard currentPageIndex < note.pages.count - 1 else {
            print("⚠️ Cannot go to next page - already at last page")
            return
        }

        print("➡️ Moving to next page: \(currentPageIndex) -> \(currentPageIndex + 1)")

        // Just change the index - onChange will handle saving and loading
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPageIndex += 1
        }
    }

    private func previousPage() {
        guard currentPageIndex > 0 else {
            print("⚠️ Cannot go to previous page - already at first page")
            return
        }

        print("⬅️ Moving to previous page: \(currentPageIndex) -> \(currentPageIndex - 1)")

        // Just change the index - onChange will handle saving and loading
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPageIndex -= 1
        }
    }

    private func addPage() {
        print("➕ Adding new page. Current count: \(note.pages.count)")

        // Save current page first if valid
        if isPageValid {
            updateDrawing(at: currentPageIndex, with: currentDrawing)
        }

        // Mutate note and update index synchronously to prevent state loss
        // Uses default template from settings
        note.addPage()

        // Skip onChange since we're handling the page load ourselves
        skipOnChange = true
        currentPageIndex = note.pages.count - 1

        print("✅ New page added. Total pages: \(note.pages.count), Current index: \(currentPageIndex)")

        // Load new page after state update
        DispatchQueue.main.async {
            self.loadCurrentPage()
        }
    }

    private func deletePage(at index: Int) {
        guard note.pages.count > 1 else {
            print("⚠️ Cannot delete - only one page left")
            return
        }

        print("🗑️ Deleting page at index: \(index). Total pages before: \(note.pages.count)")

        // Save current drawing before deleting if valid
        if index == currentPageIndex && isPageValid {
            updateDrawing(at: currentPageIndex, with: currentDrawing)
        }

        // Mutate note and update index synchronously to prevent state loss
        note.deletePage(at: index)

        // Skip onChange since we're handling the page load ourselves
        skipOnChange = true
        if currentPageIndex >= note.pages.count {
            currentPageIndex = max(0, note.pages.count - 1)
            print("📍 Adjusted current page index to: \(currentPageIndex)")
        }

        print("✅ Page deleted. Total pages now: \(note.pages.count)")

        // Load updated page after state update
        DispatchQueue.main.async {
            self.loadCurrentPage()
        }
    }

    private func startAutoSave() {
        print("⏰ Starting auto-save timer (every 5 seconds)")
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            autoSave()
        }
    }

    private func stopAutoSave() {
        print("⏰ Stopping auto-save timer")
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
    }

    private func autoSave() {
        print("💾 Auto-saving note...")

        // Save current drawing
        updateDrawing(at: currentPageIndex, with: currentDrawing)

        // Save note
        viewModel.saveNote(note)

        print("✅ Auto-save completed")
    }

    private func saveAndDismiss() {
        print("💾 Saving note and dismissing...")

        // Stop auto-save timer
        stopAutoSave()

        // Save current drawing
        updateDrawing(at: currentPageIndex, with: currentDrawing)

        // Save note
        viewModel.saveNote(note)

        print("✅ Note saved successfully")
        dismiss()
    }
}

// MARK: - Canvas View Wrapper

struct CanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let onDrawingChanged: (PKDrawing) -> Void

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.drawingPolicy = .pencilOnly  // Only allow Apple Pencil input
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawing = drawing
        canvasView.delegate = context.coordinator

        // Fix blurry rendering by setting proper scale for Retina displays
        canvasView.contentScaleFactor = UIScreen.main.scale
        canvasView.layer.contentsScale = UIScreen.main.scale
        canvasView.layer.rasterizationScale = UIScreen.main.scale

        // Ensure canvas is transparent and doesn't obscure the template
        canvasView.layer.isOpaque = false

        print("🖌️ Canvas created (transparent, pencilOnly, scale: \(UIScreen.main.scale)), setting up tool picker...")

        // Defer tool picker setup to ensure view hierarchy is ready
        // Use longer delay on first load to ensure window is available
        DispatchQueue.main.asyncAfter(deadline: .now() + EditorConstants.toolPickerInitialDelay) {
            context.coordinator.setupToolPicker(for: canvasView)
        }

        return canvasView
    }

    static func dismantleUIView(_ uiView: PKCanvasView, coordinator: Coordinator) {
        print("🧹 Cleaning up canvas view...")
        // Properly cleanup first responder status
        if uiView.isFirstResponder {
            uiView.resignFirstResponder()
            print("✅ Canvas resigned first responder")
        }
        coordinator.toolPicker?.setVisible(false, forFirstResponder: uiView)
        coordinator.toolPicker?.removeObserver(uiView)
        coordinator.toolPicker = nil
        print("✅ Tool picker cleaned up")
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Only update if drawings are actually different
        let currentData = uiView.drawing.dataRepresentation()
        let newData = drawing.dataRepresentation()

        if currentData != newData {
            uiView.drawing = drawing
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onDrawingChanged: onDrawingChanged)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        let onDrawingChanged: (PKDrawing) -> Void
        var toolPicker: PKToolPicker?
        private var isToolPickerSetup = false
        private var setupWorkItem: DispatchWorkItem?

        init(onDrawingChanged: @escaping (PKDrawing) -> Void) {
            self.onDrawingChanged = onDrawingChanged
        }

        deinit {
            // Clean up work items
            setupWorkItem?.cancel()
        }

        func setupToolPicker(for canvasView: PKCanvasView) {
            // Prevent multiple setup attempts
            guard !isToolPickerSetup else {
                return
            }

            // Cancel any pending setup work
            setupWorkItem?.cancel()

            // Check if view is in hierarchy
            guard let window = canvasView.window else {
                // Schedule retry with cancellable work item
                let workItem = DispatchWorkItem { [weak self, weak canvasView] in
                    guard let self = self, let canvasView = canvasView else { return }
                    self.setupToolPicker(for: canvasView)
                }
                setupWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + EditorConstants.toolPickerRetryDelay, execute: workItem)
                return
            }

            // Get or create tool picker
            self.toolPicker = PKToolPicker()
            self.toolPicker?.setVisible(true, forFirstResponder: canvasView)
            self.toolPicker?.addObserver(canvasView)

            // Delay becoming first responder slightly to avoid conflicts
            let workItem = DispatchWorkItem { [weak self, weak canvasView] in
                guard let self = self, let canvasView = canvasView,
                      canvasView.window != nil,
                      !canvasView.isFirstResponder else {
                    return
                }

                canvasView.becomeFirstResponder()
                self.isToolPickerSetup = true
            }
            setupWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + EditorConstants.toolPickerFirstResponderDelay, execute: workItem)
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            onDrawingChanged(canvasView.drawing)
        }
    }
}

// MARK: - Zoomable ScrollView

struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    let content: Content
    @Binding var zoomScale: CGFloat
    let doubleTapToReset: Bool
    let maxZoomScale: Double

    init(
        zoomScale: Binding<CGFloat>,
        doubleTapToReset: Bool = true,
        maxZoomScale: Double = 10.0,
        @ViewBuilder content: () -> Content
    ) {
        self._zoomScale = zoomScale
        self.doubleTapToReset = doubleTapToReset
        self.maxZoomScale = maxZoomScale
        self.content = content()
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 0.5
        scrollView.maximumZoomScale = CGFloat(maxZoomScale)
        scrollView.bouncesZoom = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never

        // Create hosting controller for SwiftUI content
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear

        // Fix blurry rendering by setting proper scale for Retina displays
        hostingController.view.contentScaleFactor = UIScreen.main.scale
        hostingController.view.layer.contentsScale = UIScreen.main.scale

        scrollView.addSubview(hostingController.view)
        context.coordinator.hostingController = hostingController
        context.coordinator.contentView = hostingController.view

        // Add double tap gesture if enabled
        if doubleTapToReset {
            let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
            doubleTap.numberOfTapsRequired = 2
            scrollView.addGestureRecognizer(doubleTap)
        }

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        // Update max zoom scale if it changed
        scrollView.maximumZoomScale = CGFloat(maxZoomScale)

        // Update constraints if needed
        guard let contentView = context.coordinator.contentView else { return }

        if contentView.constraints.isEmpty {
            NSLayoutConstraint.activate([
                contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
                contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
                contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
                contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor)
            ])
        }

        // Update hosting controller content
        context.coordinator.hostingController?.rootView = content

        // Trigger centering after content is updated
        DispatchQueue.main.async {
            context.coordinator.centerContentIfNeeded(scrollView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(zoomScale: $zoomScale)
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingController: UIHostingController<Content>?
        var contentView: UIView?
        @Binding var zoomScale: CGFloat

        init(zoomScale: Binding<CGFloat>) {
            self._zoomScale = zoomScale
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return contentView
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            zoomScale = scrollView.zoomScale
            centerContentIfNeeded(scrollView)

            // Update content scale factor dynamically during zoom to prevent blurriness
            if let contentView = contentView {
                let scale = UIScreen.main.scale * scrollView.zoomScale
                contentView.contentScaleFactor = scale
                contentView.layer.contentsScale = scale

                // Update PKCanvasView scale if it exists in the hierarchy
                updateCanvasScale(in: contentView, scale: scale)
            }
        }

        private func updateCanvasScale(in view: UIView, scale: CGFloat) {
            // Recursively find and update PKCanvasView
            for subview in view.subviews {
                if let canvasView = subview as? PKCanvasView {
                    canvasView.contentScaleFactor = scale
                    canvasView.layer.contentsScale = scale
                    canvasView.layer.rasterizationScale = scale
                } else {
                    updateCanvasScale(in: subview, scale: scale)
                }
            }
        }

        func scrollViewDidLayoutSubviews(_ scrollView: UIScrollView) {
            centerContentIfNeeded(scrollView)
        }

        func centerContentIfNeeded(_ scrollView: UIScrollView) {
            guard let contentView = contentView else { return }

            let contentWidth = contentView.frame.width * scrollView.zoomScale
            let contentHeight = contentView.frame.height * scrollView.zoomScale

            let scrollViewWidth = scrollView.bounds.width
            let scrollViewHeight = scrollView.bounds.height

            let horizontalInset = max(0, (scrollViewWidth - contentWidth) / 2)
            let verticalInset = max(0, (scrollViewHeight - contentHeight) / 2)

            scrollView.contentInset = UIEdgeInsets(
                top: verticalInset,
                left: horizontalInset,
                bottom: verticalInset,
                right: horizontalInset
            )
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView = gesture.view as? UIScrollView,
                  let contentView = contentView else { return }

            if scrollView.zoomScale > 1.0 {
                // Reset to 1.0 and center the content
                UIView.animate(withDuration: 0.3) {
                    scrollView.setZoomScale(1.0, animated: false)

                    // Center the content after zoom reset
                    let contentWidth = contentView.frame.width
                    let contentHeight = contentView.frame.height
                    let scrollViewWidth = scrollView.bounds.width
                    let scrollViewHeight = scrollView.bounds.height

                    let offsetX = max(0, (contentWidth - scrollViewWidth) / 2)
                    let offsetY = max(0, (contentHeight - scrollViewHeight) / 2)

                    scrollView.contentOffset = CGPoint(x: offsetX, y: offsetY)
                }
            } else {
                // Zoom to 2.0 at tap location
                let location = gesture.location(in: contentView)
                let size = CGSize(
                    width: scrollView.bounds.width / 2.0,
                    height: scrollView.bounds.height / 2.0
                )
                let origin = CGPoint(
                    x: location.x - size.width / 2,
                    y: location.y - size.height / 2
                )
                scrollView.zoom(to: CGRect(origin: origin, size: size), animated: true)
            }
        }
    }
}
