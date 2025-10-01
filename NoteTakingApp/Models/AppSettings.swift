import Foundation

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var maxZoomLevel: Double {
        didSet {
            UserDefaults.standard.set(maxZoomLevel, forKey: "maxZoomLevel")
        }
    }

    private init() {
        // Load saved value or use default
        let saved = UserDefaults.standard.double(forKey: "maxZoomLevel")
        self.maxZoomLevel = saved > 0 ? saved : 10.0
    }
}
