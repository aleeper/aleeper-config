#!/bin/bash
# Reorder tmux windows: move current window to a target index,
# shifting intervening windows to fill the gap.
target="$1"
current_index="$(tmux display-message -p '#I')"
current_id="$(tmux display-message -p '#{window_id}')"

# Disable auto-renumbering during moves so indices stay stable
#tmux set-option -g renumber-windows off

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

# Re-enable auto-renumbering
#tmux set-option -g renumber-windows on
