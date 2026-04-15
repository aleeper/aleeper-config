#!/usr/bin/env sh
# Generic ROS helpers. Not sourced by default — uncomment in zshrc if needed.
# Machine-specific aliases (ROS_MASTER_URI, old PR2 hosts) have been removed.

# List and grep topics
alias gtopic='rostopic list | sort -u | grep'

# Enter a named ROS workspace under ~/ros/
# Usage: ws <workspace_name>
ws() {
  local name="${1:?Usage: ws <workspace_name>}"
  cd "$HOME/ros/$name" || return
  export ROS_WS=$PWD
  export ROS_WORKSPACE=$ROS_WS
  if [ -f setup.bash ]; then
    echo "Sourcing setup.bash"
    source setup.bash
  fi
}
