import SwiftUI

/// Original 24-point vector artwork in Assets.xcassets. Semantic names retain
/// compatibility with report markers; no SF Symbols are used by app-owned icons.
extension Image {
    init(forma name: String) {
        self.init(FormaIcon.assetName(for: name))
        self = self.renderingMode(.template)
    }
}

enum FormaIcon {
    static func assetName(for name: String) -> String {
        names[name] ?? "forma-info"
    }

    private static let names: [String: String] = [
        "1.circle.fill": "forma-stage-1",
        "2.circle.fill": "forma-stage-2",
        "3.circle.fill": "forma-stage-3",
        "antenna.radiowaves.left.and.right": "forma-antenna",
        "app.badge": "forma-app",
        "arrow.clockwise": "forma-retry",
        "arrow.down": "forma-down",
        "arrow.down.forward.circle.fill": "forma-down-circle",
        "arrow.left": "forma-left",
        "arrow.right": "forma-right",
        "arrow.triangle.branch": "forma-branch",
        "arrow.up": "forma-up",
        "arrow.up.forward.circle.fill": "forma-up-circle",
        "arrow.up.right": "forma-up-right",
        "bolt.fill": "forma-bolt",
        "calendar": "forma-calendar",
        "chart.bar.doc.horizontal": "forma-report",
        "chart.line.downtrend.xyaxis": "forma-chart-down",
        "chart.line.uptrend.xyaxis": "forma-chart",
        "chart.xyaxis.line": "forma-chart",
        "checkmark": "forma-check",
        "checkmark.circle.fill": "forma-check-circle",
        "checkmark.seal.fill": "forma-check-circle",
        "chevron.right": "forma-chevron",
        "circle": "forma-circle",
        "circle.lefthalf.filled": "forma-half",
        "doc.text.magnifyingglass": "forma-report-search",
        "dumbbell.fill": "forma-strength",
        "exclamationmark": "forma-alert",
        "exclamationmark.circle.fill": "forma-alert",
        "exclamationmark.triangle.fill": "forma-warning",
        "figure.strengthtraining.traditional": "forma-strength",
        "flame": "forma-flame",
        "flame.fill": "forma-flame",
        "fork.knife": "forma-food",
        "gearshape": "forma-settings",
        "info.circle": "forma-info",
        "info.circle.fill": "forma-info",
        "magnifyingglass": "forma-search",
        "map.fill": "forma-map",
        "pencil": "forma-edit",
        "percent": "forma-percent",
        "person.2.crop.horizontal": "forma-people",
        "person.crop.circle": "forma-profile",
        "person.fill": "forma-person",
        "plus": "forma-plus",
        "ruler": "forma-ruler",
        "sparkle": "forma-spark",
        "sparkles": "forma-spark",
        "speaker.wave.2.fill": "forma-speaker",
        "target": "forma-target",
        "waveform.path": "forma-wave",
        "waveform.path.ecg": "forma-heart",
        "xmark": "forma-close",
        "xmark.circle.fill": "forma-close-circle",
    ]
}
