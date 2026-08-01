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
