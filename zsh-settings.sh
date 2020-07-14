echo "Loading ZSH settings!"

alias reconfig='. ~/.zshrc'
alias editconfig='vim ~/.zshrc'

NEWLINE=$'\n'
PS1="%10F%m%f:%11F%1~%f${NEWLINE}\$ "

bindkey  "^[[H"   beginning-of-line
bindkey  "^[[F"   end-of-line
bindkey  "^[[3~"  delete-char
bindkey '\e\e[C' forward-word
bindkey '\e\e[D' backward-word
