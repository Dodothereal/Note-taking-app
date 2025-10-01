import Foundation

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var maxZoomLevel: Double {
        didSet {
            UserDefaults.standard.set(maxZoomLevel, forKey: "maxZoomLevel")
        }
    }

    @Published var resolutionScale: Double {
        didSet {
            UserDefaults.standard.set(resolutionScale, forKey: "resolutionScale")
        }
    }

    @Published var gridSpacing: Double {
        didSet {
            UserDefaults.standard.set(gridSpacing, forKey: "gridSpacing")
        }
    }

    @Published var linedSpacing: Double {
        didSet {
            UserDefaults.standard.set(linedSpacing, forKey: "linedSpacing")
        }
    }

    @Published var defaultTemplate: String {
        didSet {
            UserDefaults.standard.set(defaultTemplate, forKey: "defaultTemplate")
        }
    }

    @Published var trashRetentionDays: Int? {
        didSet {
            if let days = trashRetentionDays {
                UserDefaults.standard.set(days, forKey: "trashRetentionDays")
            } else {
                UserDefaults.standard.removeObject(forKey: "trashRetentionDays")
            }
            UserDefaults.standard.set(trashRetentionDays != nil, forKey: "hasTrashRetention")
        }
    }

    @Published var nightModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(nightModeEnabled, forKey: "nightModeEnabled")
        }
    }

    @Published var nightModeInvertDrawings: Bool {
        didSet {
            UserDefaults.standard.set(nightModeInvertDrawings, forKey: "nightModeInvertDrawings")
        }
    }

    @Published var nightModeInvertText: Bool {
        didSet {
            UserDefaults.standard.set(nightModeInvertText, forKey: "nightModeInvertText")
        }
    }

    @Published var nightModeInvertImages: Bool {
        didSet {
            UserDefaults.standard.set(nightModeInvertImages, forKey: "nightModeInvertImages")
        }
    }

    private init() {
        // Load saved value or use default
        let savedZoom = UserDefaults.standard.double(forKey: "maxZoomLevel")
        self.maxZoomLevel = savedZoom > 0 ? savedZoom : 10.0

        let savedResolution = UserDefaults.standard.double(forKey: "resolutionScale")
        self.resolutionScale = savedResolution > 0 ? savedResolution : 3.0

        let savedGrid = UserDefaults.standard.double(forKey: "gridSpacing")
        self.gridSpacing = savedGrid > 0 ? savedGrid : 20.0

        let savedLined = UserDefaults.standard.double(forKey: "linedSpacing")
        self.linedSpacing = savedLined > 0 ? savedLined : 30.0

        let savedTemplate = UserDefaults.standard.string(forKey: "defaultTemplate")
        self.defaultTemplate = savedTemplate ?? "blank"

        // Trash retention: nil means keep forever
        let hasRetention = UserDefaults.standard.bool(forKey: "hasTrashRetention")
        if hasRetention {
            let days = UserDefaults.standard.integer(forKey: "trashRetentionDays")
            self.trashRetentionDays = days > 0 ? days : 30
        } else {
            self.trashRetentionDays = nil // Keep forever by default
        }

        // Night mode settings
        self.nightModeEnabled = UserDefaults.standard.bool(forKey: "nightModeEnabled")
        self.nightModeInvertDrawings = UserDefaults.standard.object(forKey: "nightModeInvertDrawings") as? Bool ?? true
        self.nightModeInvertText = UserDefaults.standard.object(forKey: "nightModeInvertText") as? Bool ?? true
        self.nightModeInvertImages = UserDefaults.standard.object(forKey: "nightModeInvertImages") as? Bool ?? false
    }

    var defaultPageTemplate: PageTemplate {
        PageTemplate(rawValue: defaultTemplate) ?? .blank
    }
}
