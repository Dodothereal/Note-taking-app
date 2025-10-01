import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var showingTrash = false
    @StateObject private var viewModel = NotesViewModel()

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

                        Slider(value: $settings.resolutionScale, in: 1...8, step: 0.5)
                            .tint(.blue)
                    }
                } header: {
                    Text("Performance & Quality")
                } footer: {
                    Text("Lower values save battery and improve performance. Higher values (up to 8x) provide ultra-sharp text and drawings. Requires reopening notes to take effect.")
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

                Section {
                    Toggle("Enable Night Mode", isOn: $settings.nightModeEnabled)

                    if settings.nightModeEnabled {
                        Toggle("Invert Drawings", isOn: $settings.nightModeInvertDrawings)
                            .disabled(false)
                        Toggle("Invert Text", isOn: $settings.nightModeInvertText)
                            .disabled(false)
                        Toggle("Invert Images", isOn: $settings.nightModeInvertImages)
                            .disabled(false)
                    }
                } header: {
                    Text("Night Mode")
                } footer: {
                    Text("Night mode changes the background to black. Enable the toggles below to invert drawings, text, and images for better visibility on dark backgrounds.")
                }

                Section {
                    Button {
                        showingTrash = true
                    } label: {
                        HStack {
                            Label("Recently Deleted", systemImage: "trash")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)

                    Picker("Keep Deleted Items", selection: Binding(
                        get: { settings.trashRetentionDays ?? -1 },
                        set: { newValue in
                            settings.trashRetentionDays = newValue == -1 ? nil : newValue
                        }
                    )) {
                        Text("Forever").tag(-1)
                        Text("7 Days").tag(7)
                        Text("14 Days").tag(14)
                        Text("30 Days").tag(30)
                        Text("60 Days").tag(60)
                        Text("90 Days").tag(90)
                    }
                } header: {
                    Text("Trash")
                } footer: {
                    Text("Deleted notes and folders are stored in Recently Deleted. Set how long to keep them before permanent deletion.")
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
            .sheet(isPresented: $showingTrash) {
                TrashView(viewModel: viewModel)
            }
        }
    }
}
