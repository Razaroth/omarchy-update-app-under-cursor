# omarchy-update-app-under-cursor

Hold **SUPER + right-click** on any window to update the app you're using —
no need to know its package name.

Built for [Omarchy](https://omarchy.org/) (Arch + Hyprland), but works on any
Hyprland setup with the same tooling.

## What it does

Points at a window and figures out what "the app" really is, then runs the
update in a terminal so you can authenticate and watch the result:

| What's under the cursor          | What gets updated                         |
| -------------------------------- | ----------------------------------------- |
| Terminal running a CLI/TUI app   | The app running inside it (e.g. `cliamp`) |
| Idle terminal                    | The terminal itself (e.g. `foot`)         |
| Browser web app (e.g. Discord)   | A matching native package, installed or updated |
| Normal / Electron app            | The package owning its binary             |
| Flatpak app                      | `flatpak update <app>`                    |
| Snap app                         | `sudo snap refresh <app>`                 |

Update backends: repo packages via `sudo pacman -Sy <pkg>`, AUR packages via
`yay -S --cleanafter <pkg>`, plus flatpak and snap. If nothing can be
identified, you get a notification instead.

## How it works

1. Reads the cursor position with `hyprctl cursorpos` and finds the window
   underneath via `hyprctl clients -j` (topmost, most-recently-focused match).
2. Identifies the app from `/proc/<pid>/cmdline` (not `/proc/<pid>/exe`, which
   YAMA's ptrace scope blocks for non-descendant processes):
   - **Terminal windows** (foot, kitty, alacritty, ghostty, …) are detected by
     class and walked down their process tree to the deepest package-owning
     binary, so a terminal running `cliamp` updates `cliamp`, not `foot`.
   - **Chromium-family web apps** (`chrome-*`, `brave-*`, …) are detected by
     class and resolved to a matching native package name.
   - **Chromium** folds its whole command line into `argv[0]`, so the first
     word is used.
3. Opens `omarchy-launch-terminal` running the update command, so sudo can
   prompt in the visible terminal.

## Requirements

- Omarchy (or a Hyprland setup with `omarchy-launch-terminal` and
  `omarchy-notification-send`)
- `hyprctl` (Hyprland)
- `jq`, `pacman`, `pgrep`
- `yay` — required only for AUR packages
- `flatpak` / `snap` — required only for those app types

## Install

```bash
git clone https://github.com/Razaroth/omarchy-update-app-under-cursor
cd omarchy-update-app-under-cursor
./install.sh
```

Or install it as an [Omarchy shell plugin](https://github.com/basecamp/omarchy) —
the repo carries a plugin `manifest.json`, so `omarchy plugin add` will clone,
validate, and register it under `~/.config/omarchy/plugins/`:

```bash
omarchy plugin add https://github.com/Razaroth/omarchy-update-app-under-cursor --enable
```

The plugin is a headless `service` (no UI); run `install.sh` as well so the
SUPER + right-click binding and the `omarchy-update-app-under-cursor` command
are available on your PATH.

The installer:

- copies the script to `~/.local/bin/omarchy-update-app-under-cursor`
- appends a `SUPER + mouse:273` binding block to
  `~/.config/hypr/bindings.lua` (including an `hl.unbind` to replace the
  default **resize window** binding — idempotent, safe to re-run)
- reloads Hyprland and checks `hyprctl configerrors`

## Usage

Hold **SUPER** and **right-click** any window. A terminal opens running the
update for the app under the cursor. If the window can't be identified, a
desktop notification explains why.

## Uninstall

```bash
./uninstall.sh
```

This removes the script and the binding block, restoring the default
SUPER + right-click *resize window* behavior.

## Troubleshooting

- **"Couldn't identify app"** — the running command isn't owned by a package
  (e.g. a `mise`/language-manager shim). Nothing was changed.
- **Wrong app resolved** — open an issue with the window title, the
  `omarchy-update-app-under-cursor` output, and `ps -ef` for that window's
  process tree.

## License

MIT
