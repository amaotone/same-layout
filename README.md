# SameLayout

Plug any monitor into your MacBook and get the same layout. macOS remembers arrangements per monitor, so every unfamiliar screen (hot desks, meeting rooms) starts out placed to the right. SameLayout keeps one arrangement and one main-display choice for "MacBook + one external display" and re-applies them whenever an external display connects, whichever monitor it is.

- Arrangements: external to the right, above, or left of the MacBook, or mirrored. No "below": the laptop never sits above the monitor.
- Right/left align the bottom edges (the laptop screen sits physically lower); above centers horizontally.
- Pick the arrangement and the main display from the menu bar. With the menu open, 1–4 pick an arrangement and M switches the main display.
- The icon draws the arrangement: the large rectangle is the external display, the small one the MacBook.
- The menu shows the external monitor's real name (e.g. "DELL S2725QC").
- No global hotkey. To bind a key, point a Raycast Script Command (or similar) at the CLI, e.g. `SameLayout next` or `SameLayout main external`.

## Build

```sh
./build.sh            # -> build/SameLayout.app
./build.sh --install  # also copies to ~/Applications
```

The app icon is generated: edit `scripts/make-icon.swift`, then run `scripts/make-icon.sh` to rewrite `Resources/AppIcon.icns`.

## CLI

```sh
SameLayout status
SameLayout next
SameLayout set right|above|left|mirror
SameLayout main builtin|external
```

## Limitations

- Only the first external display is managed; others are left untouched.
- In mirror mode the main display is the mirror source.
- Requires the lid to be open (the built-in display must be online).

## License

MIT. See [LICENSE](LICENSE).
