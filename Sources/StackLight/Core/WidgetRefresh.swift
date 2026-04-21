import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Thin cross-platform wrapper so `AppState` can poke the widget timeline
/// without importing WidgetKit on macOS (where it isn't available).
enum WidgetRefresh {
    static func reloadAll() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    static func reload(kind: String) {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
        #endif
    }
}
