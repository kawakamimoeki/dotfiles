bindkey -r '^G'
bindkey -r '^B'

# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/zshrc.pre.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.pre.zsh"

# Fig post block. Keep at the bottom of this file.
[[ -f "$HOME/.fig/shell/zshrc.post.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.post.zsh"

function login-bastion-staging() {
  INSTANCE_ID=$(AWS_PROFILE=staging aws ec2 describe-instances --region ap-northeast-1 --output json --filters "Name=instance-state-code,Values=16" --filters "Name=tag:Name,Values=bastion*"| jq -r '.Reservations[].Instances[] | [.Tags[] | select(.Key == "Name").Value][] + "\t" + .InstanceId' | sort | peco | cut -f 2)
  AWS_PROFILE=staging aws ssm start-session --target ${INSTANCE_ID}
}

function login-bastion-production() {
  INSTANCE_ID=$(AWS_PROFILE=production aws ec2 describe-instances --region ap-northeast-1 --output json --filters "Name=instance-state-code,Values=16" --filters "Name=tag:Name,Values=bastion*"| jq -r '.Reservations[].Instances[] | [.Tags[] | select(.Key == "Name").Value][] + "\t" + .InstanceId' | sort | peco | cut -f 2)
  AWS_PROFILE=production aws ssm start-session --target ${INSTANCE_ID}
}


eval "$(starship init zsh)"

# fzf history
function fzf-select-history() {
    BUFFER=$(history -n -r 1 | fzf --query "$LBUFFER" --reverse)
    CURSOR=$#BUFFER
    zle reset-prompt
}
zle -N fzf-select-history
bindkey '^r' fzf-select-history
export PATH="$HOME/.rbenv/bin:$PATH" 
eval "$(rbenv init - zsh)"
export PATH="$HOME/.nodenv/bin:$PATH"
alias firefox="/Applications/Firefox.app/Contents/MacOS/firefox"
eval "$(nodenv init -)"
source <(fzf --zsh)
export PATH="$HOME/.config/git-fuzzy/bin:$PATH"
source $(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
source ~/.secrets
alias dj="ddgr -n 5 -r jp-jp"
alias de="ddgr -n 5 -r us-en"
alias r="ranger ."
alias ail="ls -t | head -1 | xargs nvim"
alias ain="touch $(date +ai-%Y-%m-%d--%H-%M-%S.md); ls -t | head -1 | xargs nvim"
alias n="nvim"
alias safari="open -a Safari"

source /opt/homebrew/share/antigen/antigen.zsh
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle rupa/z z.sh

