import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let defaults = UserDefaults.standard
    private var statusItem: NSStatusItem!
    /// Our own reconfiguration also fires display callbacks; ignore them for a moment.
    private var lastApplied = Date.distantPast

    private var preferred: Arrangement {
        get { defaults.string(forKey: "preferred").flatMap(Arrangement.init) ?? .right }
        set { defaults.set(newValue.rawValue, forKey: "preferred") }
    }

    private var preferExternalMain: Bool {
        get { defaults.bool(forKey: "externalIsMain") }
        set { defaults.set(newValue, forKey: "externalIsMain") }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        refreshIcon()

        let context = Unmanaged.passUnretained(self).toOpaque()
        CGDisplayRegisterReconfigurationCallback({ display, flags, context in
            guard let context, !flags.contains(.beginConfigurationFlag) else { return }
            let delegate = Unmanaged<AppDelegate>.fromOpaque(context).takeUnretainedValue()
            let connected = flags.contains(.addFlag) && CGDisplayIsBuiltin(display) == 0
            DispatchQueue.main.async { delegate.refreshIcon() }
            guard connected else { return }
            // Let macOS finish placing the new display before overriding it.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { delegate.externalConnected() }
        }, context)
    }

    private func refreshIcon() {
        guard let button = statusItem.button else { return }
        if let pair = DisplayPair.current() {
            button.image = LayoutIcon.image(pair.arrangement ?? preferred)
        } else {
            button.image = NSImage(systemSymbolName: "laptopcomputer", accessibilityDescription: "DisplayCycle")
        }
    }

    private func externalConnected() {
        guard Date().timeIntervalSince(lastApplied) > 3 else { return }
        apply(preferred, externalIsMain: preferExternalMain)
    }

    private func apply(_ arrangement: Arrangement, externalIsMain: Bool) {
        guard let pair = DisplayPair.current() else { return }
        lastApplied = Date()
        do {
            try pair.apply(arrangement, externalIsMain: externalIsMain)
            preferred = arrangement
            preferExternalMain = externalIsMain
        } catch {
            NSLog("DisplayCycle: \(error)")
            NSSound.beep()
        }
        refreshIcon()
    }

    // MARK: - Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        if #available(macOS 14, *) {
            menu.addItem(.sectionHeader(title: "DisplayCycle"))
        } else {
            menu.addItem(withTitle: "DisplayCycle", action: nil, keyEquivalent: "")
        }
        menu.addItem(.separator())

        if let pair = DisplayPair.current() {
            let current = pair.arrangement
            let externalIsMain = pair.externalIsMain

            for (index, arrangement) in Arrangement.allCases.enumerated() {
                let item = NSMenuItem(title: arrangement.label, action: #selector(choose(_:)), keyEquivalent: "\(index + 1)")
                item.keyEquivalentModifierMask = []
                item.image = LayoutIcon.image(arrangement)
                item.representedObject = arrangement.rawValue
                item.state = arrangement == current ? .on : .off
                menu.addItem(item)
            }

            menu.addItem(.separator())
            let mains = [("メイン：MacBook", "laptopcomputer", false), ("メイン：\(pair.externalName)", "display", true)]
            for (title, symbol, external) in mains {
                let isMain = external == externalIsMain
                // Only the other display gets M, so pressing M always switches.
                let item = NSMenuItem(title: title, action: #selector(chooseMain(_:)), keyEquivalent: isMain ? "" : "m")
                item.keyEquivalentModifierMask = []
                item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
                item.representedObject = external
                item.state = isMain ? .on : .off
                menu.addItem(item)
            }
        } else {
            menu.addItem(withTitle: "外部ディスプレイが接続されていません", action: nil, keyEquivalent: "")
        }

        menu.addItem(.separator())
        let login = NSMenuItem(title: "ログイン時に起動", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        login.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(login)

        menu.addItem(.separator())
        menu.addItem(withTitle: "終了", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        for item in menu.items where item.action != #selector(NSApplication.terminate(_:)) {
            item.target = self
        }
    }

    @objc private func choose(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let arrangement = Arrangement(rawValue: raw),
              let pair = DisplayPair.current() else { return }
        apply(arrangement, externalIsMain: pair.externalIsMain)
    }

    @objc private func chooseMain(_ sender: NSMenuItem) {
        guard let external = sender.representedObject as? Bool, let pair = DisplayPair.current() else { return }
        apply(pair.arrangement ?? preferred, externalIsMain: external)
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("DisplayCycle: launch at login: \(error)")
            NSSound.beep()
        }
    }
}
