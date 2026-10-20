import AppKit

/// `DisplayCycle status | next | set <arrangement> | main builtin|external` runs once and exits;
/// no arguments starts the menu bar app.
func runCommand(_ args: [String]) -> Int32 {
    guard let pair = DisplayPair.current() else {
        print("no external display")
        return 1
    }
    let current = pair.arrangement ?? .right
    let usage = "usage: DisplayCycle status | next | set \(Arrangement.allCases.map(\.rawValue).joined(separator: "|")) | main builtin|external"
    let target: (Arrangement, Bool)
    switch (args.first, args.dropFirst().first) {
    case ("status", _):
        print("\(pair.arrangement?.rawValue ?? "below"), main: \(pair.externalIsMain ? "external" : "builtin")")
        for (name, id) in [("builtin", pair.builtin), ("external", pair.external)] {
            print("  \(name): \(CGDisplayBounds(id))")
        }
        return 0
    case ("next", _):
        target = (pair.arrangement?.next ?? .right, pair.externalIsMain)
    case ("set", let raw?) where Arrangement(rawValue: raw) != nil:
        target = (Arrangement(rawValue: raw)!, pair.externalIsMain)
    case ("main", "builtin"), ("main", "external"):
        target = (current, args[1] == "external")
    default:
        print(usage)
        return 2
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
if let command = args.first, ["status", "next", "set", "main"].contains(command) {
    exit(runCommand(args))
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
