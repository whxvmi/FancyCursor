import Cocoa

struct FancyCursorSettings: Codable {
    var colorData: Data
    var birthRate: CGFloat
    var lifetime: CGFloat
    var velocity: CGFloat
    var scale: CGFloat
    var alphaSpeed: CGFloat

    var color: NSColor {
        get {
            if let c = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData) {
                return c
            }
            return .systemPink
        }
        set {
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: false) {
                colorData = data
            }
        }
    }

    static let `default` = FancyCursorSettings(
        colorData: try! NSKeyedArchiver.archivedData(
            withRootObject: NSColor.systemPink,
            requiringSecureCoding: false
        ),
        birthRate: 60,
        lifetime: 0.6,
        velocity: 0,
        scale: 0.35,
        alphaSpeed: -1.0
    )
}

extension FancyCursorSettings {
    private static let key = "FancyCursorUserSettings"

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }

    static func load() -> FancyCursorSettings {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let settings = try? JSONDecoder().decode(FancyCursorSettings.self, from: data) {
            return settings
        }
        return .default
    }
}
