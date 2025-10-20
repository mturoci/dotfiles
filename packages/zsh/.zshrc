# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Source .env file if it exists
[[ -f ~/.env ]] && source ~/.env

# PATH configuration
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin:/usr/local/anaconda3/bin:/opt/homebrew/bin
export PATH=$PATH:$HOME/bin/bin
export PATH=$PATH:$HOME/Downloads/zig-macos-x86_64-0.14.0-dev.3271+bd237bced
ZSH_DISABLE_COMPFIX=true

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="agnoster"

# Plugins
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# User configuration

# OpenMP stuff - More info at https://scikit-learn.org/dev/developers/advanced_installation.html#macos
export CC=/usr/bin/clang
export CXX=/usr/bin/clang++
export SKLEARN_NO_OPENMP=TRUE
export MACOSX_DEPLOYMENT_TARGET="10.14"

# Remove custom name@name
export DEFAULT_USER="$(whoami)"

# Show only current dir instead of full path
prompt_dir() {
  prompt_segment blue black "${PWD##*/}"
}

# Autosuggestions custom bindings
bindkey '^[auto' autosuggest-execute

# Enable syntax highlighting
export TESSDATA_PREFIX=/opt/homebrew/Cellar/tesseract/5.3.3/share/tessdata

# Aliases

# Projects
alias qd="cd $HOME/projects/wave"

# Git
alias g="git"
alias gst="git status"
alias grh="git reset --hard"
alias grs="git reset --soft"
alias gs="git stash"
alias gsp="git stash pop"

# Other
alias d="docker"
alias sed="gsed"
alias prj="cd $HOME/projects"
alias python3="python"
alias gemini=/opt/homebrew/Cellar/gemini-cli/0.1.18/bin/gemini

# Additional PATH exports
export PATH="/usr/local/opt/protobuf@3.6/bin:$PATH"
export PATH=$PATH:$HOME/bin
export PATH=$PATH:$HOME/.local/bin
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
export PATH="$HOME/.local/share/nvim-linux64/bin:$PATH"

# Powerlevel10k theme
source "$HOME/powerlevel10k/powerlevel10k.zsh-theme"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

