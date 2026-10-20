import AppKit

/// Where the external display sits relative to the built-in one.
/// "Below" is deliberately absent: a laptop never sits on top of its monitor.
enum Arrangement: String, CaseIterable {
    case right, above, left, mirror

    var label: String {
        switch self {
        case .right: "外部を右に"
        case .above: "外部を上に"
        case .left: "外部を左に"
        case .mirror: "ミラーリング"
        }
    }

    var next: Arrangement {
        let all = Self.allCases
        return all[(all.firstIndex(of: self)! + 1) % all.count]
    }
}

struct DisplayError: Error, CustomStringConvertible {
    let step: String
    let code: CGError
    var description: String { "\(step) failed (CGError \(code.rawValue))" }
}

/// The built-in panel plus the first external display. Additional externals are left alone.
/// Externals are never told apart by ID, so any monitor gets the same treatment.
struct DisplayPair {
    let builtin: CGDirectDisplayID
    let external: CGDirectDisplayID

    /// Uses the online list (not the active list) so mirrored displays are still found.
    static func current() -> DisplayPair? {
        var count: UInt32 = 0
        guard CGGetOnlineDisplayList(0, nil, &count) == .success, count > 0 else { return nil }
        var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetOnlineDisplayList(count, &ids, &count) == .success else { return nil }
        guard let builtin = ids.first(where: { CGDisplayIsBuiltin($0) != 0 }),
              let external = ids.first(where: { CGDisplayIsBuiltin($0) == 0 })
        else { return nil }
        return DisplayPair(builtin: builtin, external: external)
    }

    var externalIsMain: Bool { CGMainDisplayID() == external }

    /// While mirrored the external may not be its own NSScreen, hence the fallback.
    var externalName: String {
        NSScreen.screens.first {
            $0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID == external
        }?.localizedName ?? "外部ディスプレイ"
    }

    /// nil when the external sits below the built-in, which this app never produces.
    var arrangement: Arrangement? {
        if CGDisplayMirrorsDisplay(external) != kCGNullDirectDisplay
            || CGDisplayMirrorsDisplay(builtin) != kCGNullDirectDisplay {
            return .mirror
        }
        // Global display space: origin at the main display's top-left, y grows downward.
        let b = CGDisplayBounds(builtin), e = CGDisplayBounds(external)
        if e.minX >= b.maxX { return .right }
        if e.maxX <= b.minX { return .left }
        if e.maxY <= b.minY { return .above }
        return nil
    }

    func apply(_ arrangement: Arrangement, externalIsMain: Bool) throws {
        var config: CGDisplayConfigRef?
        let begin = CGBeginDisplayConfiguration(&config)
        guard begin == .success, let config else { throw DisplayError(step: "begin", code: begin) }

        do {
            try check("unmirror", CGConfigureDisplayMirrorOfDisplay(config, external, kCGNullDirectDisplay))
            try check("unmirror", CGConfigureDisplayMirrorOfDisplay(config, builtin, kCGNullDirectDisplay))
            if arrangement == .mirror {
                // The main display is the mirror master.
                let (mirror, master) = externalIsMain ? (builtin, external) : (external, builtin)
                try check("mirror", CGConfigureDisplayMirrorOfDisplay(config, mirror, master))
            } else {
                // Whichever display sits at (0, 0) becomes main.
                let offset = externalOffset(for: arrangement)
                let builtinOrigin = externalIsMain ? CGPoint(x: -offset.x, y: -offset.y) : .zero
                let externalOrigin = externalIsMain ? .zero : offset
                try check("origin", CGConfigureDisplayOrigin(config, builtin, Int32(builtinOrigin.x), Int32(builtinOrigin.y)))
                try check("origin", CGConfigureDisplayOrigin(config, external, Int32(externalOrigin.x), Int32(externalOrigin.y)))
            }
            try check("complete", CGCompleteDisplayConfiguration(config, .permanently))
        } catch {
            CGCancelDisplayConfiguration(config)
            throw error
        }
    }

    /// External origin when the built-in sits at (0, 0). Edges touch.
    private func externalOffset(for arrangement: Arrangement) -> CGPoint {
        let b = pointSize(builtin), e = pointSize(external)
        let centeredX = ((b.width - e.width) / 2).rounded()
        // Bottoms aligned, not centered: the laptop screen physically sits lower than the monitor.
        let bottomY = b.height - e.height
        switch arrangement {
        case .right: return CGPoint(x: b.width, y: bottomY)
        case .left: return CGPoint(x: -e.width, y: bottomY)
        case .above: return CGPoint(x: centeredX, y: -e.height)
        case .mirror: return .zero
        }
    }

    /// Mode size in points. CGDisplayBounds is unreliable while a display is a mirror.
    private func pointSize(_ id: CGDirectDisplayID) -> CGSize {
        guard let mode = CGDisplayCopyDisplayMode(id) else { return CGDisplayBounds(id).size }
        return CGSize(width: mode.width, height: mode.height)
    }

    private func check(_ step: String, _ code: CGError) throws {
        guard code == .success else { throw DisplayError(step: step, code: code) }
    }
}
