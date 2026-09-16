# Omaduo

An [Ormus](https://ormus.solutions) plugin for [Omarchy](https://omarchy.org).

Bar widget and panel for the ASUS Zenbook Duo (UX8406CA): ScreenPad layout
when the keyboard is on or off the magnet, portrait rotate, and the palm-rest
trackpad (pad plus its relative mouse node).

It talks to Hyprland through `hyprctl eval`. The widget hides its controls
when the machine is not a Duo. No sudo or pkexec is required for status,
rotate, or trackpad. ScreenPad WMI backlight still uses the existing
passwordless `sudo -n tee` path from the old `duo-layout` helper.

## Install

```bash
omarchy plugin add https://github.com/Ormus-Solutions/omaduo.git --enable
```

Or copy this directory to `~/.config/omarchy/plugins/omaduo/`, then:

```bash
omarchy plugin validate ~/.config/omarchy/plugins/omaduo
omarchy-shell shell rescanPlugins
omarchy plugin enable omaduo --before ormus.duo-rotate
```

Shell enablement is not compositor activation. Existing Duo binds on this
machine stay in `~/.config/hypr/bindings.lua` until you run:

```bash
~/.config/omarchy/plugins/omaduo/bin/omaduo activate
```

That writes a marked `-- omaduo:begin` / `-- omaduo:end` block. First write
copies `bindings.lua` and `autostart.lua` to `*.bak.omaduo`. Dry-run prints
the block without writing.

```bash
~/.config/omarchy/plugins/omaduo/bin/omaduo dry-run
~/.config/omarchy/plugins/omaduo/bin/omaduo deactivate
```

## Remove

```bash
omarchy plugin remove omaduo
```

That removes the plugin folder and its shell.json entry. It does not revert
Hyprland. Deactivate first if you ran activate. Safe to delete by hand:

- `~/.local/state/omarchy/omaduo-activated`
- `~/.local/state/omarchy/toggles/duo-rotate`
- `~/.local/state/omarchy/toggles/duo-rotate.dir`
- `~/.local/state/omarchy/toggles/hypr/duo-touchpad-disabled.lua`

## Usage

Left-click the laptop glyph to open the panel.

- **Layout** tab: portrait screens, flip 90/270, re-apply ScreenPad layout
- **Input** tab: palm-rest trackpad
- **Keys** tab: chords (Super+R, Super+Alt+T, F4, F5/F6)

Right-click the bar icon toggles portrait. Middle-click toggles the trackpad.
`1` `2` `3` switch tabs. `r` refreshes.

IPC: `omarchy-shell omaduo open|close|toggle|show|hide`.

CLI: `omaduo status|inspect|layout|rotate|touchpad|kbd-backlight|dry-run|activate|deactivate`.

## Dependencies

Stock Omarchy: `hyprctl`, `python3`, `jq` unused. `brightnessctl` for the
ScreenPad mirror. `bluetoothctl` only if `~/.config/moon-duo/bt-keyboard.mac`
exists. DMI board or product must contain `UX8406CA`.

## What it executes

| Binary | Writes |
|--------|--------|
| `bin/layout` | Hyprland monitor eval; optional ScreenPad brightness via `sudo -n` |
| `bin/rotate` | `~/.local/state/omarchy/toggles/duo-rotate*` then layout |
| `bin/touchpad` | Hyprland device eval; `duo-touchpad-disabled.lua` when off |
| `bin/kbd-backlight` | HID feature report; `~/.local/state/moon-duo/kbd-backlight*` |
| `bin/brightness-mirror` | DRM/WMI backlight nodes |
| `bin/bt-connect` | `bluetoothctl connect` for the bonded MAC |
| `bin/omaduo activate` | marked blocks in `~/.config/hypr/bindings.lua` and `autostart.lua` |

It never edits `/usr/share/omarchy/` or `/etc`.

## License

MIT. See `LICENSE`.
