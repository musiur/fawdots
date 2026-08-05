export ZSH="/usr/share/oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)
source "$ZSH/oh-my-zsh.sh"

# Pacman-managed, not Oh My Zsh custom plugins — kept in sync via install.sh's
# PACMAN_PKGS instead of a git-cloned plugin dir. syntax-highlighting must be
# sourced last per its own docs.
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

command -v neofetch >/dev/null 2>&1 && neofetch
