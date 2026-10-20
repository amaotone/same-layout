import AppKit

/// `SameLayout status | next | set <arrangement> | main builtin|external` runs once and exits;
/// no arguments starts the menu bar app.
enum Command {
    case status, next
    case set(Arrangement)
    case main(external: Bool)

    init?(_ args: [String]) {
        switch (args.first, args.dropFirst().first) {
        case ("status", nil): self = .status
        case ("next", nil): self = .next
        case ("set", let raw?):
            guard let arrangement = Arrangement(rawValue: raw) else { return nil }
            self = .set(arrangement)
        case ("main", "builtin"): self = .main(external: false)
        case ("main", "external"): self = .main(external: true)
        default: return nil
        }
    }
}

func runCommand(_ args: [String]) -> Int32 {
    guard let command = Command(args) else {
        print("usage: SameLayout status | next | set \(Arrangement.allCases.map(\.rawValue).joined(separator: "|")) | main builtin|external")
        return 2
    }
    guard let pair = DisplayPair.current() else {
        print("no external display")
        return 1
    }
    let target: (Arrangement, Bool)
    switch command {
    case .status:
        print("\(pair.arrangement?.rawValue ?? "below"), main: \(pair.externalIsMain ? "external" : "builtin")")
        for (name, id) in [("builtin", pair.builtin), ("external", pair.external)] {
            print("  \(name): \(CGDisplayBounds(id))")
        }
        return 0
    case .next: target = (pair.arrangement?.next ?? .right, pair.externalIsMain)
    case .set(let arrangement): target = (arrangement, pair.externalIsMain)
    case .main(let external): target = (pair.arrangement ?? .right, external)
    }
    do {
        try pair.apply(target.0, externalIsMain: target.1)
        print("\(target.0.rawValue), main: \(target.1 ? "external" : "builtin")")
        return 0
    } catch {
        print(error)
        return 1
    }
}

let args = Array(CommandLine.arguments.dropFirst())
if !args.isEmpty {
    exit(runCommand(args))
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
