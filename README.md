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

| Package        | Role                             | Source        |
|----------------|-----------------------------------|----------------|
| hyprland       | compositor                        | pacman (extra) |
| hyprpaper      | wallpaper daemon                   | pacman (extra) |
| hypridle       | idle management                    | pacman (extra) |
| hyprlock       | lock screen                        | pacman (extra) |
| waybar         | status bar                         | pacman (extra) |
| dunst          | notification daemon                | pacman (extra) |
| networkmanager | network management + waybar module | pacman (extra) |
| bluez          | bluetooth stack + waybar module    | pacman (extra) |
| hyprlauncher   | app launcher (bound to SUPER+R)    | pacman (extra) |

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

## Theme / wallpaper sync

`SUPER+W` opens [waypaper](https://github.com/anufrievroman/waypaper) (AUR),
a thumbnail picker over `~/Pictures/Wallpapers` (drop your own images there —
none are bundled). Picking a wallpaper:

1. Sets it via `hyprctl hyprpaper ...` IPC (waypaper's hyprpaper backend
   talks to the already-running hyprpaper instance, doesn't edit its config).
2. Runs `matugen image "$wallpaper" ...` as a post-command (configured in
   `waypaper/.config/waypaper/config.ini`), which extracts a Material You
   color palette from the image.
3. matugen regenerates two files from templates in
   `matugen/.config/matugen/templates/`:
   - `~/.config/waybar/colors.css` — `@define-color` values that
     `waybar/style.css` imports (`@import url("colors.css");`) and uses via
     `alpha(@background, 0.45)` etc. Restarts waybar via `post_hook`.
   - `~/.config/hypr/hyprlock.conf` — the *entire* file, background image
     path + accent colors, regenerated fresh each time (not a partial
     patch — hyprlock has no `source =` dependency we wanted to risk
     leaving unverified, so the template owns the whole file).

Both generated files are **not** stow-tracked (they're build artifacts, not
source) — only the templates that produce them are in the repo. On a fresh
machine, `install.sh` runs matugen once against the built-in
`/usr/share/hypr/wall2.png` so waybar/hyprlock have colors before you've
picked a real wallpaper.

`--prefer saturation` is passed to matugen to avoid an interactive terminal
prompt when an image has multiple equally-dominant colors (no TTY is
available when waypaper invokes it as a background process).

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
