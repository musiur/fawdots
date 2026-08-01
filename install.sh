#!/usr/bin/env bash
# Bootstrap script for fawdots on a fresh Arch/Hyprland install.
# Safe to re-run.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

PACMAN_PKGS=(stow hypridle hyprlock pipewire-pulse wireplumber grim slurp wl-clipboard
	satty hyprshot xdg-user-dirs waybar networkmanager network-manager-applet bluez
	bluez-utils blueman pavucontrol ttf-nerd-fonts-symbols dunst)
AUR_PKGS=()

echo "==> Installing pacman packages: ${PACMAN_PKGS[*]}"
sudo pacman -S --needed "${PACMAN_PKGS[@]}"

if [ "${#AUR_PKGS[@]}" -gt 0 ]; then
	if command -v yay >/dev/null 2>&1; then
		echo "==> Installing AUR packages: ${AUR_PKGS[*]}"
		yay -S --needed "${AUR_PKGS[@]}"
	else
		echo "==> yay not found; skipping AUR packages: ${AUR_PKGS[*]}"
		echo "    Install an AUR helper first, then run: yay -S ${AUR_PKGS[*]}"
	fi
fi

echo "==> Enabling NetworkManager and bluetooth"
sudo systemctl enable --now NetworkManager bluetooth

echo "==> Stowing packages into \$HOME"
for pkg in */; do
	pkg="${pkg%/}"
	[[ "$pkg" == ".git" ]] && continue
	stow --restow --target="$HOME" "$pkg"
	echo "    stowed $pkg"
done

echo "==> Setting up XDG user directories (~/Pictures, ~/Downloads, etc.)"
xdg-user-dirs-update

echo "==> Done. Log out/in (or restart Hyprland) to pick up autostart changes."
