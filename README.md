# fawdots

Personal dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

Each top-level directory is a "package" whose contents mirror `$HOME`. Stow
symlinks a package's files into place without copying them, so edits in
`~/.config/...` are edits in this repo (as long as the symlink exists).

## Layout

```
fawdots/
  hypr/.config/hypr/       Hyprland (hyprland.lua, hyprpaper.conf, hypridle.conf)
  waybar/.config/waybar/   waybar status bar (config.jsonc, style.css)
  matugen/.config/matugen/ Wallpaper → color scheme pipeline (config.toml, templates/)
  waypaper/.config/waypaper/ GUI wallpaper picker config
  kitty/.config/kitty/     Terminal (kitty.conf includes matugen-generated colors.conf)
  scripts/.local/bin/      matugen-apply, theme-toggle, record-toggle
  install.sh                Bootstrap script for a fresh machine
```

## Notes

- **Notifications**: `dunst` is the notification daemon (dbus-activated, no explicit
  autostart needed). We tried hyprpanel first (which wants to own notifications
  itself, conflicting with dunst) but replaced it with waybar — see below.
- **Audio**: waybar's pulseaudio module needs a PulseAudio-compatible socket, which on
  this system comes from `pipewire-pulse` + `wireplumber` (not installed by default
  alongside plain `pipewire`). Both are in `install.sh`'s package list.
- **Icons**: waybar's network/bluetooth/volume icons are Nerd Font glyphs (Private Use
  Area codepoints). `ttf-nerd-fonts-symbols-common` alone only ships fontconfig rules,
  not glyphs — you also need `ttf-nerd-fonts-symbols` for the actual font file, and the
  family must be named explicitly in CSS (`"Symbols Nerd Font"`) since PUA codepoints
  don't reliably trigger automatic font fallback.

## Bare-minimum Hyprland ecosystem

| Package          | Role                                | Source         |
|------------------|--------------------------------------|-----------------|
| hyprland         | compositor                          | pacman (extra) |
| hyprpaper        | wallpaper daemon                    | pacman (extra) |
| hypridle         | idle management                     | pacman (extra) |
| hyprlock         | lock screen                         | pacman (extra) |
| waybar           | status bar                          | pacman (extra) |
| dunst            | notification daemon                 | pacman (extra) |
| networkmanager   | network management + waybar module  | pacman (extra) |
| bluez            | bluetooth stack + waybar module     | pacman (extra) |
| hyprlauncher     | app launcher (bound to SUPER+A)     | pacman (extra) |
| nautilus         | file manager (SUPER+E)              | pacman (extra) |
| polkit-kde-agent | privilege-escalation prompts        | pacman (extra) |
| cliphist         | clipboard history (SUPER+SHIFT+V)   | pacman (extra) |
| swayosd          | volume/brightness OSD popup         | pacman (extra) |
| hyprpicker       | color picker (SUPER+SHIFT+C)        | pacman (extra) |
| wf-recorder      | screen recording (SUPER+SHIFT+R)    | pacman (extra) |

`hyprpaper`, `hypridle`, and `waybar` are autostarted from `hyprland.lua`.
`SUPER+L` locks the session via `hyprlock`. waybar's layer surface is blurred
via a Hyprland `layer_rule` (namespace `waybar`) for a frosted-glass look —
its background alpha is intentionally low (0.45) so the blur is visible.

We evaluated hyprpanel first for the bar (see git history) but it has a fixed
module set with no active-window-title module and no native network/bluetooth
modules (those need a registered tray icon instead), so we switched to waybar,
which has both plus more flexible CSS.

## Screenshots

| Key | Action |
|---|---|
| `Print` | Draw a region → opens in satty to annotate |
| `SUPER+Print` | Screenshot a window you click on → saved + clipboard |
| `SUPER+SHIFT+Print` | Full monitor screenshot → saved to `~/Pictures` + clipboard |

Annotation uses [satty](https://github.com/gabm/Satty) (not swappy — swappy's
panel is a fixed side dock with no config to make it a single top toolbar;
satty has a compact top toolbar out of the box). satty also has no crop
tool — select a smaller region with slurp instead. Annotated screenshots
save to `~/Pictures/satty-<timestamp>.png` and copy to clipboard on demand
via satty's toolbar/keybinds (see `satty --man` for the full list).

## Other productivity keybinds

| Key | Action |
|---|---|
| `SUPER+SHIFT+V` | Clipboard history picker |
| `SUPER+SHIFT+C` | Pick a color from screen, copies hex to clipboard, sends a notification |
| `SUPER+SHIFT+R` | Toggle screen recording, saves to `~/Videos/recording-<timestamp>.mp4` |

- **Clipboard history**: `wl-paste --watch cliphist store` runs in autostart,
  building a history. `SUPER+SHIFT+V` runs
  `cliphist list | hyprlauncher --dmenu | cliphist decode | wl-copy` —
  hyprlauncher already supports a dmenu-compatible mode (`--dmenu`), so no
  separate picker app (wofi/rofi/fuzzel) was needed.
- **Color picker**: `hyprpicker -a -n` (autocopy + notify).
- **Screen recording**: `scripts/.local/bin/record-toggle` checks whether
  `wf-recorder` is already running — if so it sends `SIGINT` (lets it
  finalize the file cleanly) and notifies where it saved; otherwise it
  starts a new timestamped recording.
- **Volume/brightness OSD**: `swayosd-server` runs in autostart;
  `XF86Audio*`/`XF86MonBrightness*` keys call `swayosd-client`, which both
  shows the popup and performs the actual change (so it replaces, not
  supplements, the old direct `wpctl`/`brightnessctl` calls). Those old
  calls are kept as an `||` fallback in case `swayosd-server` isn't
  reachable over D-Bus for some reason — seen transiently while restarting
  it repeatedly during setup/testing, not an issue in normal use.
- **Polkit agent**: `polkit-kde-agent` was already installed on this system
  but nothing was actually starting it, so privileged GUI actions (e.g.
  NetworkManager system connections, disk mounting) would silently fail
  with no password prompt. Added to autostart
  (`/usr/lib/polkit-kde-authentication-agent-1`).

## Theme / wallpaper sync

`SUPER+W` opens [waypaper](https://github.com/anufrievroman/waypaper) (AUR),
a thumbnail picker over `~/Pictures/Wallpapers` (drop your own images there —
none are bundled). `SUPER+SHIFT+D` toggles light/dark mode for whichever
wallpaper is currently set.

Both actions funnel through two scripts in `scripts/.local/bin/`:

- **`matugen-apply [wallpaper]`** — the single place that knows how to
  invoke matugen. Reads the current light/dark mode from
  `~/.local/state/fawdots/theme-mode` (defaults to `dark`); if no wallpaper
  is passed, reads the last one waypaper picked from
  `~/.config/waypaper/config.ini`. Runs
  `matugen image <wallpaper> --config ~/.config/matugen/config.toml --prefer saturation --mode <mode>`.
  (`--prefer saturation` avoids an interactive terminal prompt when an image
  has multiple equally-dominant colors — no TTY is available when waypaper
  or a keybind invokes this as a background process.)
- **`theme-toggle`** — flips the mode file, calls `matugen-apply` (no
  wallpaper arg, so it reuses the current one), and syncs GNOME's
  `color-scheme` gsettings key (some GTK apps check that instead of, or in
  addition to, `gtk.css`).

waypaper's `post_command` (in `waypaper/.config/waypaper/config.ini`) is
just `~/.local/bin/matugen-apply "$wallpaper"` — picking a new wallpaper
keeps whatever mode is currently active.

matugen regenerates these files from templates in
`matugen/.config/matugen/templates/`, all keyed off `colors.*.default.*`
(which respects `--mode`) so every target flips with the toggle too:

- `~/.config/waybar/colors.css` — `@define-color` values that
  `waybar/style.css` imports (`@import url("colors.css");`) and uses via
  `alpha(@background, 0.45)` etc. Restarts waybar via `post_hook`.
- `~/.config/hypr/hyprlock.conf` — the *entire* file, background image
  path + accent colors, regenerated fresh each time (not a partial
  patch — hyprlock has no `source =` dependency we wanted to risk
  leaving unverified, so the template owns the whole file).
- `~/.config/hypr/colors.lua` — `hyprland.lua` does
  `local colors = require("colors")` and uses `colors.active_border` /
  `colors.inactive_border` for window border colors. `post_hook` runs
  `hyprctl reload`.
- `~/.config/kitty/colors.conf` — 16-color ANSI palette derived from
  matugen's base16 output (base16-shell's standard mapping, e.g.
  `color1`/red = `base08`). `kitty/kitty.conf` does `include colors.conf`.
  Picked up on kitty's next launch (no live-reload hook).
- `~/.config/gtk-3.0/gtk.css` and `~/.config/gtk-4.0/gtk.css` —
  `@define-color` overrides for Adwaita's/libadwaita's named colors
  (`theme_selected_bg_color`, `accent_color`, etc.), which GTK apps load
  automatically. This is what themes pavucontrol, blueman-manager,
  nm-connection-editor, and other GTK apps.
- `~/.config/gtk-3.0/settings.ini` and `~/.config/gtk-4.0/settings.ini` —
  `gtk-application-prefer-dark-theme={{is_dark_mode}}`. These used to be
  static stow-tracked files; they're matugen templates now so the toggle
  actually flips them (GLib's key-file boolean parser accepts the literal
  `true`/`false` strings matugen outputs, so no conversion needed).

  GTK3's stock Adwaita theme does **not** reliably darken from this flag
  alone anymore — dark-mode maintenance effectively moved to
  libadwaita/GTK4, and plain "Adwaita" for GTK3 is legacy at this point
  (confirmed by actually launching pavucontrol and screenshotting it: it
  stayed white with only the boolean set). The fix is
  [adw-gtk-theme](https://github.com/lassekongo83/adw-gtk3) (official
  repo), a GTK3 port of libadwaita that ships proper `adw-gtk3` /
  `adw-gtk3-dark` variants. matugen's template engine has no conditionals
  (verified — it only does `{{ value | filter }}` pipelines, no `{{if}}`
  block despite that syntax existing in some template engines), so
  `matugen-apply` picks the theme name itself after matugen runs: writes
  `gtk-theme=adw-gtk3(-dark)` into `gtk-3.0/settings.ini` via `sed` and
  sets the matching `org.gnome.desktop.interface gtk-theme` gsetting.
  GTK4/libadwaita apps don't have this problem — they only ever have one
  visual theme and switch its light/dark rendering internally based on
  the prefer-dark-theme/color-scheme signal, which already worked.

Generated files are **not** stow-tracked (they're build artifacts, not
source) — only the templates that produce them are in the repo (there's no
`gtk-3.0`/`gtk-4.0` stow package at all anymore, matugen creates those
directories itself). On a fresh machine, `install.sh` runs matugen once
against the built-in `/usr/share/hypr/wall2.png` so every target has colors
before you've picked a real wallpaper.

## Usage on a new machine

```sh
git clone git@github.com:<you>/fawdots.git ~/Documents/fawdots
cd ~/Documents/fawdots
./install.sh
```

`install.sh` installs the package set (pacman + yay) and stows every package
directory into `$HOME`. It's safe to re-run.

## Adding a new package

```sh
mkdir -p newapp/.config/newapp
mv ~/.config/newapp/* newapp/.config/newapp/
stow newapp
```

## Restowing after changes

```sh
stow -R hypr     # re-link after adding/removing files in hypr/
stow -D hypr      # unlink (remove symlinks) without deleting repo files
```
