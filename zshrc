# load custom executable functions
for function in ~/.zsh/functions/*; do
  source $function
done

# extra files in ~/.zsh/configs/pre , ~/.zsh/configs , and ~/.zsh/configs/post
# these are loaded first, second, and third, respectively.
_load_settings() {
  _dir="$1"
  if [ -d "$_dir" ]; then
    if [ -d "$_dir/pre" ]; then
      for config in "$_dir"/pre/**/*(N-.); do
        . $config
      done
    fi

    for config in "$_dir"/**/*(N-.); do
      case "$config" in
        "$_dir"/pre/*)
          :
          ;;
        "$_dir"/post/*)
          :
          ;;
        *)
          if [ -f $config ]; then
            . $config
          fi
          ;;
      esac
    done

    if [ -d "$_dir/post" ]; then
      for config in "$_dir"/post/**/*(N-.); do
        . $config
      done
    fi
  fi
}
_load_settings "$HOME/.zsh/configs"

# makes color constants available
autoload -U colors
colors

# enable colored output from ls, etc
export CLICOLOR=1

# history settings
setopt hist_ignore_all_dups inc_append_history
HISTFILE=~/.zhistory
HISTSIZE=4096
SAVEHIST=4096

# awesome cd movements from zshkit
setopt autocd autopushd pushdminus pushdsilent pushdtohome cdablevars
DIRSTACKSIZE=5

# Enable extended globbing
setopt extendedglob

# Allow [ or ] whereever you want
unsetopt nomatch

# vi mode
bindkey -v
bindkey "^F" vi-cmd-mode
bindkey jj vi-cmd-mode

# handy keybindings
bindkey "^A" beginning-of-line
bindkey "^E" end-of-line
bindkey "^R" history-incremental-search-backward
bindkey "^P" history-search-backward
bindkey "^Y" accept-and-hold
bindkey "^N" insert-last-word
bindkey -s "^T" "^[Isudo ^[A" # "t" for "toughguy"

# use vim as the visual editor
export VISUAL=vim
export EDITOR=$VISUAL
export GPG_TTY=$(tty)

# disable autoupdates
export HOMEBREW_NO_AUTO_UPDATE=1
export PATH="$HOME/.bin:$PATH"
export PATH="$HOME/.asdf/shims:$PATH"

# mkdir .git/safe in the root of repositories you trust
export PATH=".git/safe/../../bin:$PATH"

# export GEM_HOME=$HOME/.gem
# export PATH=$HOME/.gem/bin:$PATH
export GEM_HOME="$HOME/.asdf/installs/ruby/$(asdf current ruby | tail -1 | awk '{print $2}')/lib/ruby/gems"
export GEM_PATH="$GEM_HOME"

if command -v ngrok &>/dev/null; then
  eval "$(ngrok completion)"
fi

# Local config
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# aliases
[[ -f ~/.aliases ]] && source ~/.aliases


[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Added by serverless binary installer
export PATH="$HOME/.serverless/bin:$PATH"

# bun completions
[ -s "/Users/david/.bun/_bun" ] && source "/Users/david/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# AI Config
[[ -f ~/.ai_config.local ]] && source ~/.ai_config.local

# Custom Keys
[[ -f ~/.keys.local ]] && source ~/.keys.local

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/david/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/david/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/david/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/david/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<


# Created by `pipx` on 2024-05-13 03:25:10
export PATH="$PATH:/Users/david/.local/bin"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/david/.cache/lm-studio/bin"

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/david/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/david/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/david/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/david/google-cloud-sdk/completion.zsh.inc'; fi

asdf_version() {
  asdf current "$1" | awk '{print $2}' | tail -n1
}

export PATH="$(asdf where ruby)/bin:$PATH"
export GEM_PATH=/Users/david/.asdf/installs/ruby/$(asdf_version ruby)/lib/ruby/gems/3.4.0

export PATH="$HOME/.asdf/installs/golang/$(asdf_version golang)/bin:$PATH"

# opencode
export PATH=/Users/david/.opencode/bin:$PATH

. "$HOME/.atuin/bin/env"

eval "$(atuin init zsh)"

alias claude="/Users/david/.claude/local/claude"
