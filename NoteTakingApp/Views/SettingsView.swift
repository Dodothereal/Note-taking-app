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

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Resolution Scale")
                            Spacer()
                            Text("\(String(format: "%.1f", settings.resolutionScale))x")
                                .foregroundColor(.secondary)
                        }

                        Slider(value: $settings.resolutionScale, in: 1...5, step: 0.5)
                            .tint(.blue)
                    }
                } header: {
                    Text("Performance")
                } footer: {
                    Text("Lower values save battery and improve performance. Higher values provide sharper text and drawings. Requires reopening notes to take effect.")
                }

                Section {
                    Picker("Default Template", selection: $settings.defaultTemplate) {
                        Text("Blank").tag("blank")
                        Text("Grid").tag("grid")
                        Text("Dotted").tag("dotted")
                        Text("Lined").tag("lined")
                    }
                    .pickerStyle(.menu)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Grid Spacing")
                            Spacer()
                            Text("\(Int(settings.gridSpacing)) pt")
                                .foregroundColor(.secondary)
                        }

                        Slider(value: $settings.gridSpacing, in: 10...50, step: 5)
                            .tint(.blue)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Line Spacing")
                            Spacer()
                            Text("\(Int(settings.linedSpacing)) pt")
                                .foregroundColor(.secondary)
                        }

                        Slider(value: $settings.linedSpacing, in: 15...60, step: 5)
                            .tint(.blue)
                    }
                } header: {
                    Text("Templates")
                } footer: {
                    Text("Default template is used when creating new notes and pages. Spacing adjustments apply to all pages.")
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
