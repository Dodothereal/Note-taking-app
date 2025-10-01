import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Maximum Zoom Level")
                            Spacer()
                            Text("\(Int(settings.maxZoomLevel))x")
                                .foregroundColor(.secondary)
                        }

                        Slider(value: $settings.maxZoomLevel, in: 1...20, step: 1)
                            .tint(.blue)
                    }
                } header: {
                    Text("Note Editor")
                } footer: {
                    Text("Set how far you can zoom into notes. Higher values allow more detailed work but may impact performance.")
                }
            }
            .navigationTitle("Settings")
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
