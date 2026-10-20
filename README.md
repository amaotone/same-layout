# SameLayout

Plug any monitor into your MacBook and get the same layout. macOS remembers arrangements per monitor, so every new screen starts out placed to the right. SameLayout keeps one arrangement and one main display, and re-applies them whenever an external display connects.

- Arrangements: right, above, left, or mirror. Pick one and the main display from the menu bar (1–4 and M work while the menu is open).
- Right and left align bottom edges; above centers horizontally.
- No global hotkey. Bind one with Raycast or similar, e.g. `SameLayout next`.

## Build

```sh
./build.sh            # -> build/SameLayout.app
./build.sh --install  # also copies to ~/Applications
```

To change the app icon, edit `scripts/make-icon.swift` and run `scripts/make-icon.sh`.

## CLI

```sh
SameLayout status
SameLayout next
SameLayout set right|above|left|mirror
SameLayout main builtin|external
```

## Limitations

- Only the first external display is managed.
- In mirror mode the main display is the mirror source.
- The lid must be open.

## License

MIT. See [LICENSE](LICENSE).
