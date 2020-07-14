echo "Loading BASH settings!"

alias reconfig='. ~/.bashrc'
alias editconfig='vim ~/.bashrc'

#export MYPS='$(echo -n "${PWD/#$HOME/~}" | awk -F "/" '"'"'{if (length($0) > 14) { if (NF>4) print $1 "/" $2 "/.../" $(NF-1) "/" $NF; else if (NF>3) print $1 "/" $2 "/.../" $NF; else print $1 "/.../" $NF; } else print $0;}'"'"')'
#PS1='$(eval "echo ${MYPS}")$ '
#PROMPT_DIRTRIM=2
#PS1="\u@\h:\w\n$"
# Note: \w is full path, \W is just current dir.

GREEN="\[\033[01;32m\]"
WHITE="\[\033[01;37m\]"
YELLOW="\[\033[01;33m\]"

PS1="$GREEN\u$WHITE:$YELLOW\W$WHITE\n\$ "
