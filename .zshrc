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

source ~/antigen.zsh

antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle rupa/z z.sh

eval "$(starship init zsh)"
