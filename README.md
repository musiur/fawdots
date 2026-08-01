# fawdots

Personal dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

Each top-level directory is a "package" whose contents mirror `$HOME`. Stow
symlinks a package's files into place without copying them, so edits in
`~/.config/...` are edits in this repo (as long as the symlink exists).

## Layout

```
fawdots/
  hypr/.config/hypr/       Hyprland (hyprland.lua, hyprpaper.conf, hypridle.conf, hyprlock.conf)
  hyprpanel/.config/hyprpanel/   hyprpanel status bar/panel config
  install.sh                Bootstrap script for a fresh machine
```

## Notes

- **Notifications**: hyprpanel owns the DBus Notifications interface. `dunst` conflicts
  with it (both try to claim it), so `install.sh` masks `dunst.service` via
  `systemctl --user mask`. If you'd rather use dunst, unmask it and disable
  notifications in hyprpanel's `config.json` instead.
- **Audio**: hyprpanel's audio module needs a PulseAudio-compatible socket, which on
  this system comes from `pipewire-pulse` + `wireplumber` (not installed by default
  alongside plain `pipewire`). Both are in `install.sh`'s package list.

## Bare-minimum Hyprland ecosystem

| Package    | Role                          | Source          |
|------------|--------------------------------|------------------|
| hyprland   | compositor                     | pacman (extra)   |
| hyprpaper  | wallpaper daemon                | pacman (extra)   |
| hypridle   | idle management                 | pacman (extra)   |
| hyprlock   | lock screen                     | pacman (extra)   |
| hyprpanel  | status bar / panel / OSD        | AUR              |
| hyprlauncher | app launcher (bound to SUPER+R) | pacman (extra) |

`hyprpaper`, `hypridle`, and `hyprpanel` are autostarted from `hyprland.lua`.
`SUPER+L` locks the session via `hyprlock`.

## Screenshots

| Key | Action |
|---|---|
| `Print` | Full monitor screenshot → saved to `~/Pictures` + clipboard |
| `SUPER+Print` | Screenshot a window you click on → saved + clipboard |
| `SUPER+SHIFT+Print` | Draw a region → opens in satty to annotate |

Annotation uses [satty](https://github.com/gabm/Satty) (not swappy — swappy's
panel is a fixed side dock with no config to make it a single top toolbar;
satty has a compact top toolbar out of the box). satty also has no crop
tool — select a smaller region with slurp instead. Annotated screenshots
save to `~/Pictures/satty-<timestamp>.png` and copy to clipboard on demand
via satty's toolbar/keybinds (see `satty --man` for the full list).

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
