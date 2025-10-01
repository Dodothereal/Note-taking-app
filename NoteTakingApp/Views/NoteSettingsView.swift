import SwiftUI

struct NoteSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var note: Note
    let currentPageIndex: Int

    private var isValidPageIndex: Bool {
        currentPageIndex >= 0 && currentPageIndex < note.pages.count
    }

    var body: some View {
        NavigationStack {
            Form {
                if isValidPageIndex {
                    Section {
                        Picker("Page Template", selection: Binding(
                            get: { note.pages[currentPageIndex].template },
                            set: { newTemplate in
                                note.pages[currentPageIndex].template = newTemplate
                                note.pages[currentPageIndex].modifiedAt = Date()
                            }
                        )) {
                            Text("Blank").tag(PageTemplate.blank)
                            Text("Grid").tag(PageTemplate.grid)
                            Text("Dotted").tag(PageTemplate.dotted)
                            Text("Lined").tag(PageTemplate.lined)
                        }
                        .pickerStyle(.menu)
                    } header: {
                        Text("Current Page")
                    } footer: {
                        Text("Change the template for the currently open page (Page \(currentPageIndex + 1)).")
                    }
                }
            }
            .navigationTitle("Note Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
