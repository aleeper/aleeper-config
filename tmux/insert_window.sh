#!/bin/bash
# Reorder tmux windows: move current window to a target index,
# shifting intervening windows to fill the gap.
target="$1"
session="$(tmux display-message -p '#S')"
current_index="$(tmux display-message -p '#I')"
current_id="$(tmux display-message -p '#{window_id}')"

# Temporarily move current window out of the way
tmux move-window -s "$current_id" -t 999

if [ "$current_index" -lt "$target" ]; then
  for i in $(seq $((current_index + 1)) "$target"); do
    tmux move-window -s "$i" -t $((i - 1))
  done
  tmux move-window -s 999 -t "$target"
elif [ "$current_index" -gt "$target" ]; then
  for i in $(seq "$((current_index - 1))" -1 "$target"); do
    tmux move-window -s "$i" -t $((i + 1))
  done
  tmux move-window -s 999 -t "$target"
else
  tmux move-window -s 999 -t "$target"
fi
