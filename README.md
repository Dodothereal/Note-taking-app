# Note Taking App

A powerful native iOS note-taking application built with SwiftUI, featuring advanced drawing capabilities, folder organization, and customizable settings.

## Features

### 📝 Note Creation & Editing
- Create unlimited notes with multi-page support
- Canvas-based drawing with PencilKit integration
- Add, delete, and reorder pages within notes
- Import PDF files as notes
- Export notes as PDF

### 🎨 Customization
- **Folder Colors**: Customize each folder with individual colors (11 presets + custom color picker)
- **Templates**: Choose from Blank, Grid, Dotted, or Lined page templates
- **Night Mode**: Toggle dark mode with selective inversion for drawings, text, and images
- **Zoom Control**: Adjustable zoom levels (1x-20x) with configurable resolution scale

### 📁 Organization
- Create nested folder hierarchies
- **Sorting Options**:
  - Last Modified
  - Name (A-Z)
  - Date Created
- Breadcrumb navigation for easy folder traversal
- Grid view with thumbnail previews

### 🗑️ Trash Management
- Recently Deleted folder for safe deletion
- Configurable retention period (7-90 days or forever)
- Permanent deletion and restoration options

### ⚙️ Settings
- Max zoom level (1x-20x)
- Resolution scale for ultra-sharp rendering (1x-8x)
- Template spacing customization (grid & line spacing)
- Default template selection
- Night mode with granular inversion controls

### 💎 UI/UX
- Liquid glass effects throughout the app
- Smooth animations and haptic feedback
- Context menus for quick actions
- Drag and drop support
- Clean, modern interface

## Requirements

- iOS 14.0+
- Xcode 15.0+
- Swift 5.9+

## Project Structure

```
NoteTakingApp/
├── Models/
│   ├── Note.swift
│   ├── Folder.swift
│   ├── AppSettings.swift
│   ├── TextAnnotation.swift
│   ├── ImageAnnotation.swift
│   └── ShapeAnnotation.swift
├── ViewModels/
│   └── NotesViewModel.swift
├── Views/
│   ├── GridView.swift
│   ├── GridItemView.swift
│   ├── NoteEditorView.swift
│   ├── SettingsView.swift
│   └── TrashView.swift
├── Managers/
│   └── StorageManager.swift
└── NoteTakingAppApp.swift
```

## Installation

1. Clone this repository
   ```bash
   git clone https://github.com/Dodothereal/Note-taking-app.git
   ```
2. Open `NoteTakingApp.xcodeproj` in Xcode
3. Build and run the project on your simulator or device

## Usage

### Creating & Managing Notes
- Tap the **+ Note** button to create a new note
- Tap the **+ Folder** button to create a new folder
- Long-press or right-click items for context menu options
- Import PDFs using the **Import PDF** option in the note menu

### Customizing Folders
- Long-press any folder and select **Change Color**
- Choose from 11 preset colors or use the custom color picker

### Sorting Items
- Tap the **Sort** button (arrow up/down icon) in the toolbar
- Select your preferred sorting method

### Note Settings
- Use the slider icon in the note editor to access:
  - Page template selection
  - Page management (add/delete)
  - Background customization

### Night Mode
- Enable in Settings
- Toggle individual inversion for drawings, text, and images

## License

This project is available for personal and educational use.
