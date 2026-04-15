#!/usr/bin/env sh
# Infrequently-used helpers — not sourced by default.

# Set TEXINPUTS for teaching materials (LaTeX shared inputs)
configure_tex_inputs() { export TEXINPUTS=$HOME/shared/teaching/dynamics/a_common: ; }

# ── Screen recording and Wacom tablet ────────────────────────────────────────

# ── Wacom tablet ──────────────────────────────────────────────────────────────

wacom_touch() { xsetwacom --set "Wacom Intuos4 6x9 Finger touch" Touch "$1"; }
wacom_pen()   { xsetwacom --set "Wacom Intuos4 6x9 Pen stylus" Mode "$1"; }
wacom_scale() { xsetwacom --set "Wacom Intuos4 6x9 Pen stylus" Area 0 0 "$1" "$2"; }

wacomP550() {
  xsetwacom --set "Wacom PL550" MapToOutput HEAD-0
  xsetwacom --set "Wacom PL550 eraser" MapToOutput HEAD-0
}

# ── Screen recording ──────────────────────────────────────────────────────────

# Record desktop to OGV
ogv() { recordmydesktop --width 1280 --height 720 --fps 24 --no-sound -o "${1:-output.ogv}"; }

# Record to MP4 with audio
mov() { ffmpeg -f x11grab -r 24 -s 1280x720 -i :0.0 -vcodec libx264 "${1:-output.mp4}"; }

# Conversion helpers
OgvToAvi()    { mencoder "$1" -ovc lavc -oac mp3lame -o "${1%.ogv}.avi"; }
OgvToMp4()    { ffmpeg -i "$1" -vcodec libx264 -acodec aac "${1%.ogv}.mp4"; }
OgvToAviAll() { for f in *.ogv; do OgvToAvi "$f"; done; }
OgvToMp4All() { for f in *.ogv; do OgvToMp4 "$f"; done; }
