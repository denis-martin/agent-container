# Global zsh config (installed as /etc/zsh/zshrc).
# oh-my-zsh lives in /opt (read-only); caches/dumps go to the mounted home.
export ZSH=/opt/oh-my-zsh
export ZSH_CACHE_DIR="$HOME/.cache/oh-my-zsh"
export ZSH_COMPDUMP="$ZSH_CACHE_DIR/.zcompdump"
mkdir -p "$ZSH_CACHE_DIR/completions"

ZSH_THEME="spaceship"
plugins=(git)
DISABLE_AUTO_UPDATE=true

source "$ZSH/oh-my-zsh.sh"

# Personal overrides
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
