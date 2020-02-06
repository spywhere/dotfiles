autoload -Uz compinit
typeset -i updated_at=$(date +'%j' -r ~/.zcompdump 2>/dev/null || stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)
if [ $(date +'%j') != $updated_at ]; then
  compinit -i
else
  compinit -C -i
fi

if [[ ! -f /usr/local/bin/antibody ]]; then
  curl -sfL git.io/antibody | sudo sh -s - -b /usr/local/bin
fi

setopt hist_ignore_all_dups # remove older duplicate entries from history
setopt hist_reduce_blanks # remove superfluous blanks from history items
setopt inc_append_history # save history entries as soon as they are entered
setopt share_history # share history between different instances of the shell

setopt auto_cd # cd by typing directory name if it's not a command
setopt correct_all # autocorrect commands

setopt auto_list # automatically list choices on ambiguous completion
setopt auto_menu # automatically use menu completion
setopt always_to_end # move cursor to end if word had one match
setopt complete_in_word # allow completion from within a word/phrase

zstyle ':completion:*' menu select # select completions with arrow keys
zstyle ':completion:*' group-name '' # group results by category
zstyle ':completion:::::' completer _expand _complete _ignored _approximate # enable approximate matches for completion
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' accept-exact '*(N)' # Speedup path completion

# Cache expensive completions
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.cache/zsh

ZSH_TMUX_AUTOSTART=true
ZSH_TMUX_AUTOCONNECT=false

SPACESHIP_PROMPT_ORDER=(
  user
  dir
  git
  exec_time
  line_sep
  exit_code
  char
)
SPACESHIP_USER_SHOW=needed
SPACESHIP_PROMPT_ADD_NEWLINE=false
SPACESHIP_PROMPT_SEPARATE_LINE=false

source <(antibody init)
antibody bundle denysdovhan/spaceship-prompt
antibody bundle zsh-users/zsh-autosuggestions
antibody bundle zsh-users/zsh-completions
antibody bundle zsh-users/zsh-history-substring-search
antibody bundle zdharma/fast-syntax-highlighting
antibody bundle robbyrussell/oh-my-zsh path:plugins/git
antibody bundle robbyrussell/oh-my-zsh path:plugins/command-not-found
antibody bundle robbyrussell/oh-my-zsh path:plugins/common-aliases
antibody bundle robbyrussell/oh-my-zsh path:plugins/tmux

. $HOME/.aliases
. $HOME/.variables

# Use personalize settings if found as well
[ -f ~/.personal ] && source ~/.personal

# Use fzf if found
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Export binaries
export PATH=$HOME/dotfiles/bin:$PATH

# fbr - checkout git branch (including remote branches)
fcor() {
  local branches branch
  branches=$(git branch --all | grep -v HEAD) &&
  branch=$(echo "$branches" |
           fzf-tmux -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
  git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# fco - checkout git branch/tag
fco() {
  local tags branches target
  branches=$(git --no-pager branch --all --format="%(if)%(HEAD)%(then)%(else)%(if:equals=HEAD)%(refname:strip=3)%(then)%(else)%1B[0;34;1mbranch%09%1B[m%(refname:short)%(end)%(end)" | sed '/^$/d') || return
  tags=$(git --no-pager tag | awk '{print "\x1b[35;1mtag\x1b[m\t" $1}') || return
  target=$((echo "$branches"; echo "$tags") | fzf --no-hscroll --no-multi -n 2 --ansi) || return
  git checkout $(awk '{print $2}' <<<"$target" )
}

# fco_preview - checkout git branch/tag, with a preview showing the commits between the tag/branch and HEAD
fco_preview() {
  local tags branches target
  branches=$(
    git --no-pager branch --all \
      --format="%(if)%(HEAD)%(then)%(else)%(if:equals=HEAD)%(refname:strip=3)%(then)%(else)%1B[0;34;1mbranch%09%1B[m%(refname:short)%(end)%(end)" \
    | sed '/^$/d') || return
  tags=$(
    git --no-pager tag | awk '{print "\x1b[35;1mtag\x1b[m\t" $1}') || return
  target=$(
    (echo "$branches"; echo "$tags") |
    fzf --no-hscroll --no-multi -n 2 \
        --ansi --preview="git --no-pager log -150 --pretty=format:%s '..{2}'") || return
  git checkout $(awk '{print $2}' <<<"$target" )
}

# fcoc - checkout git commit
fcoc() {
  local commits commit
  commits=$(git log --pretty=oneline --abbrev-commit --reverse) &&
  commit=$(echo "$commits" | fzf --tac +s +m -e) &&
  git checkout $(echo "$commit" | sed "s/ .*//")
}
