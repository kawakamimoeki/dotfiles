if status is-interactive
    eval (/opt/homebrew/bin/brew shellenv)
end

status --is-interactive; and source (rbenv init -|psub)
status --is-interactive; and source (nodenv init -|psub)

set PATH /Users/kawakami/.nodenv/versions/18.15.0 $PATH
set PATH /opt/homebrew/opt/libpq/bin $PATH
set -x PATH $HOME/Library/Python/3.7/bin $PATH
alias gs="git switch"
alias ga="git add"
alias gc="git commit"
alias n="nvim"
set PATH /Users/kawakami/.nodenv/versions/22.4.1 $PATH
