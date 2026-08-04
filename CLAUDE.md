# fawdots

Personal Hyprland dotfiles, GNU Stow–managed, macOS-inspired look and feel.
Read `README.md` first — it's the user-facing reference for layout, keybinds,
and the theme-sync pipeline. This file is oriented at a Claude session
picking up the repo cold: architecture reasoning, hard-won gotchas, and
where things stand across machines.

## What this is

A from-scratch Hyprland setup built interactively over one long session:
core ecosystem (hypridle/hyprlock, wallpaper via swaybg) → waybar (replaced hyprpanel
partway through) → screenshots (hyprshot/satty) → bluetooth/audio/network
management → wallpaper-driven theme sync (waypaper + matugen, covering
waybar, hyprlock, Hyprland borders, kitty, GTK3/GTK4 apps, with a
light/dark toggle) → clipboard history, OSD, color picker, screen
recording, polkit agent. Multi-machine via `install.sh`.

## Architecture

- **Stow packages**: each top-level dir mirrors `$HOME` (e.g.
  `hypr/.config/hypr/...`). `install.sh` stows all of them in a loop.
- **matugen is the theme engine**: `matugen/.config/matugen/config.toml`
  registers templates; each on wallpaper change (or toggle) regenerates a
  target file. Generated files (`waybar/colors.css`, `hypr/colors.lua`,
  `hypr/hyprlock.conf`, `kitty/colors.conf`, `gtk-3.0`/`gtk-4.0` `gtk.css`
  + `settings.ini`) are **not** stow-tracked — only their templates are.
  `hyprlock.conf` is a full-file template (was a static file in `hypr/`
  originally, moved out) rather than a partial patch, since hyprlock's
  `source =` include support was never verified live and we didn't want
  to risk it.
- **Two wrapper scripts are the only things that should ever call
  matugen** (`scripts/.local/bin/`):
  - `matugen-apply [wallpaper]` — resolves wallpaper (arg, or last one
    waypaper picked, read from `~/.config/waypaper/config.ini`) and mode
    (`~/.local/state/fawdots/theme-mode`, default `dark`), then runs
    matugen. Afterward, patches `gtk-3.0/settings.ini`'s `gtk-theme=` line
    via `sed` and syncs the matching gsettings key — matugen's template
    engine has **no conditionals** (verified: only `{{value|filter}}`
    pipelines, no `{{if}}` block), so the light/dark theme *name* can't be
    chosen inside a template.
  - `theme-toggle` — flips the mode file, calls `matugen-apply` (no arg,
    reuses current wallpaper), syncs GNOME's `color-scheme` gsettings key.
  - Both have `set -euo pipefail`. If `matugen-apply` can't resolve a
    wallpaper (e.g. `~/Pictures/Wallpapers` is empty and none was ever
    picked), it exits 1 — and since `theme-toggle` calls it unguarded,
    `theme-toggle` aborts silently too, before the gsettings sync or
    notification. This is the actual cause behind "theme toggle does
    nothing" reports — always check `~/Pictures/Wallpapers` first.
- **waypaper's `post_command`** is just `~/.local/bin/matugen-apply
  "$wallpaper"` — picking a new wallpaper keeps whatever mode is active.

## Hard-won gotchas (don't re-debug these)

- **Stow whole-dir-symlink quirk**: if a target dir doesn't exist yet,
  stow symlinks the *whole directory*; if it already exists (real dir),
  stow symlinks files individually. This means some matugen-generated
  files land physically inside the repo (needs `.gitignore`, e.g.
  `waybar/.config/waybar/colors.css`) while others land purely in
  `$HOME`, outside the repo entirely (e.g. `hypr/colors.lua`,
  `gtk-3.0/gtk.css`) — depends on whether that target dir pre-existed
  when it was first stowed. Check both when adding a new generated file.
- **A fresh Hyprland install auto-generates its own
  `~/.config/hypr/hyprland.lua`** on first launch. Plain `stow --restow`
  refuses to overwrite it (not a symlink, no `--adopt`). `install.sh`'s
  stow loop handles this automatically: on conflict, falls back to
  `stow --adopt` (pulls the existing file into the repo) then immediately
  `git checkout -- "$pkg"` (discards what was pulled in, repo content
  wins) — scoped to just the conflicting package, not the whole repo, so
  it can't clobber legitimate uncommitted state elsewhere (e.g. waypaper's
  config.ini, which gets rewritten by waypaper's own GUI).
- **GTK3 stock Adwaita does not reliably dark-mode from
  `gtk-application-prefer-dark-theme` alone anymore** — verified by
  actually launching pavucontrol and screenshotting it (stayed white).
  Dark-mode maintenance effectively moved to libadwaita/GTK4. Fix:
  `adw-gtk-theme` (official repo), switched via `gtk-theme=adw-gtk3` /
  `adw-gtk3-dark` — set by `matugen-apply`'s sed patch, not matugen
  itself (see conditionals note above).
- **GTK4/libadwaita reads dark-mode preference via the XDG Desktop
  Portal** (`org.freedesktop.appearance` `color-scheme`), not directly
  from gsettings. On this system `xdg-desktop-portal-gtk` is what
  actually answers that query (confirmed via `busctl` + `GDK_DEBUG`
  tracing), not `xdg-desktop-portal-hyprland` — both need to be
  installed. Nautilus still doesn't visually respond to the toggle
  despite every layer of this chain (dconf → gsettings → portal → GDK)
  checking out correctly and even `GTK_THEME` force-override having no
  effect — treated as an unresolved nautilus/libadwaita-version issue,
  not a config problem, after exhausting config-side explanations.
- **dunst's default `mouse_left_click = close_current`** silently
  dismisses actionable notifications instead of confirming them — broke
  Bluetooth pairing (passkey confirm notification). Fixed with
  `mouse_left_click = do_action, close_current` plus a rule pinning
  `action_name = confirm` for `appname = "Bluetooth"` (do_action alone
  falls back to a context menu when there's no single default action,
  and that menu wasn't rendering usably here).
- **swayosd occasionally fails to connect** (`ServiceUnknown`) after
  rapid manual start/stop during testing — resolved by a clean
  `pkill + restart`, not a real bug. Volume/brightness keybinds keep a
  `swayosd-client ... || wpctl/brightnessctl ...` fallback regardless.
- **hyprpaper's main thread could get stuck spinning at 100% CPU**
  indefinitely (confirmed live: pegged one core for 13+ minutes, CPU temp
  sat at 81°C, laptop chassis noticeably hot to the touch) — happened more
  than once, trigger never isolated (not simply "large wallpaper": a fresh
  `hyprpaper` process handling the same 7680×4191/28MB image settled to
  <1% CPU within seconds, so it's a runtime state bug, not an
  image-size issue). Rather than chase it further, replaced hyprpaper
  entirely with **swaybg** (`waypaper`'s `backend = swaybg`), which only
  ever does one static blit per output and has no daemon/IPC surface to
  get stuck in. Autostart changed from `hl.exec_cmd("hyprpaper")` to
  `hl.exec_cmd("waypaper --restore")` — swaybg takes the wallpaper path
  as a CLI arg with no persistent config file, so `--restore` (waypaper's
  built-in "relaunch last wallpaper+backend" flag) replaces what
  `hyprpaper.conf`'s static `preload`/`wallpaper` lines used to do.
  `hypr/.config/hypr/hyprpaper.conf` was deleted (no longer used).
  matugen theming is unaffected either way — `post_command` (which runs
  matugen-apply) fires off waypaper's own wallpaper-change hook,
  independent of which backend actually renders the image.
- **hyprlauncher supports `--dmenu`** (stdin, newline-separated, dmenu
  convention) — used directly for cliphist's picker
  (`cliphist list | hyprlauncher --dmenu | cliphist decode | wl-copy`).
  No separate picker app (wofi/rofi/fuzzel) needed.
- **Package-list completeness is an ongoing risk**: several packages
  (`hyprlauncher`, `hyprpaper`, `playerctl`, `brightnessctl`,
  `xdg-desktop-portal*`) were already installed on the machine this repo
  was originally built on, *before* the repo existed — so their absence
  from `install.sh` was invisible here and only surfaced installing on a
  second (laptop) machine from scratch. When adding anything new that
  ends up "just working," explicitly check `pacman -Q <name>` before
  assuming it's covered, and periodically cross-check every package
  named in README's table against `install.sh`'s actual array.
- **No wallpaper images are bundled** (deliberately — not fetching image
  content). `~/Pictures/Wallpapers` starts empty on every machine; seed
  it with `/usr/share/hypr/wall{0,1,2}.png` (Hyprland's own bundled
  placeholders) to unblock waypaper/theme-toggle testing immediately.
- **`hyprland.lua` (native Lua config, not the classic `.conf` keyword
  format) means `hyprctl keyword ...` is rejected outright** —
  `keyword can't work with non-legacy parsers. Use eval.` This breaks
  **any** external tool that live-applies changes via `hyprctl keyword`,
  which is nearly all of them — confirmed broken: **`nwg-displays`**
  (its Apply button silently no-ops; the UI just redraws showing the
  unchanged real state, which looks exactly like "it reverted" but
  never actually applied). Don't install GUI monitor/workspace tools
  expecting them to work here — edit the relevant `hl.*()` block in
  `hyprland.lua` directly and `hyprctl reload` (that command does work).
  Per-output monitor rules use `output = "desc:<Make> <Model>"` (from
  `hyprctl monitors`' `description:` field) to scope a rule to one
  panel instead of the wildcard `output = ""` block, so other machines
  sharing this repo aren't affected by a fix for one specific screen.
- **`wireplumber.service` / `pipewire-pulse.service` can sit enabled but
  never actually start** (no journal entries at all, `inactive (dead)`)
  — same class of issue as the "needs a fresh login" services listed
  under Multi-machine status below, just for audio instead. Symptom:
  Bluetooth audio devices connect and then immediately disconnect
  (`bluetoothd` logs `a2dp-sink profile connect failed ... Protocol not
  available`, since nothing registered the profile) — or plain silence
  with no obvious cause. Fix: `systemctl --user start wireplumber
  pipewire-pulse`. Also note: restarting `wireplumber` mid-session (not
  a fresh start) can leave the PipeWire IPC briefly deadlocked —
  `wpctl`/`pw-dump` hang instead of erroring. Recovery: stop
  `wireplumber pipewire-pulse pipewire pipewire.socket
  pipewire-pulse.socket`, wait, then start `wireplumber` first, then
  `pipewire-pulse`.
- **Bluetooth audio can negotiate AAC, report the sink as `RUNNING` with
  correct volume/routing, and still be silent** — `libfdk-aac` was
  properly installed and linked, so this wasn't a missing-codec issue,
  just a bad AAC path for this specific adapter/device pairing (CMF
  Neckband Pro). Confirmed by switching the card profile to SBC live
  (`pactl set-card-profile bluez_card.<MAC> a2dp-sink-sbc`) — worked
  immediately. Made permanent via
  `wireplumber/.config/wireplumber/wireplumber.conf.d/51-bluez-codecs.conf`
  (`bluez5.codecs = [ sbc, sbc_xq ]`, dropping AAC from the negotiable
  set entirely). This is a blanket fix for *any* Bluetooth device on
  this machine, not just this one neckband — if a future device
  actually needs AAC and works fine with it, this file is the first
  place to check.

## Multi-machine status

- **Primary desktop** (where this repo was built): fully configured,
  everything in this doc verified live here.
- **Laptop** (second machine): mid-setup via `install.sh`. Hit and fixed,
  in order: stow conflict with autogenerated `hyprland.lua` →
  `hyprlauncher: command not found` → wallpaper backend not found
  (missing `hyprpaper`) → empty `~/Pictures/Wallpapers` (waypaper picker
  empty + `theme-toggle` silently no-op). Each was a real gap fixed in
  `install.sh`/repo, not a laptop-specific issue — `git pull &&
  ./install.sh` (idempotent, safe to re-run) plus a fresh login (for
  autostart-only services: `hyprpaper`, `swayosd-server`, `cliphist`
  watcher, `blueman-applet`, polkit agent) is the standard catch-up path.

## Conventions when extending this repo

- New app config → new stow package: `mkdir -p
  newapp/.config/newapp`, move existing config in, `stow newapp`.
- New package requirement → add to `install.sh`'s `PACMAN_PKGS` (or
  `AUR_PKGS` if AUR-only) **and** to the table in `README.md` — keep
  them in sync, per the gotcha above.
- New matugen-templated file → add a `[templates.NAME]` block to
  `matugen/.config/matugen/config.toml`, put the template in
  `matugen/.config/matugen/templates/`, and check whether its output
  path's parent dir already exists in `$HOME` on a fresh machine (decides
  whether the generated file needs a `.gitignore` entry — see stow
  quirk above).
- Verify live before claiming something works: `hyprctl reload` /
  restarting the relevant daemon and screenshotting
  (`hyprshot -m output -m active -o /tmp -f x.png --silent`) is cheap and
  has caught real bugs repeatedly in this repo's history (icon
  codepoints, GTK3 dark mode, portal routing) that looked correct on
  paper.
