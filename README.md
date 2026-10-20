# DisplayCycle

Menu bar app that cycles a MacBook's built-in display and one external display through right → above → left → mirror, and switches which one is the main display. (No "below": the laptop never sits above the monitor.)

- No global hotkey. To bind a key, point a Raycast Script Command (or similar) at the CLI, e.g. `DisplayCycle next` or `DisplayCycle main external`
- With the menu open, 1–4 pick an arrangement and M switches the main display
- The menu bar icon and menu items draw the arrangement with laptop and monitor symbols
- The menu shows the external monitor's real name (e.g. "DELL S2725QC")
- Any non-built-in display counts as "the external display". The chosen arrangement and main display are stored once, not per display, so it carries over to unfamiliar monitors (e.g. hot desks).
- When an external display connects, the last chosen arrangement and main display are re-applied.
- Right/left align the bottom edges (the laptop screen sits physically lower); above centers horizontally.

## Build

```sh
./build.sh            # -> build/DisplayCycle.app
./build.sh --install  # also copies to ~/Applications
```

## CLI

```sh
DisplayCycle status
DisplayCycle next
DisplayCycle set right|above|left|mirror
DisplayCycle main builtin|external
```

## Limitations

- Only the first external display is managed; others are left untouched.
- In mirror mode the main display is the mirror source.
- Requires the lid to be open (the built-in display must be online).
