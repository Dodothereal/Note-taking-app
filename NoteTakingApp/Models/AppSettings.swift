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
    }

    var defaultPageTemplate: PageTemplate {
        PageTemplate(rawValue: defaultTemplate) ?? .blank
    }
}
