#!/bin/sh
# Claude Code status line
# Format: $<monthly> month | $<daily> today <bar> | $<session> session | ctx <pct>% <bar>
#
# Uses cost.total_cost_usd from the JSON input (exact cost from Claude Code).
# Each session writes its cost to ~/.claude/cost-tracking/<date>_<session>.cost
# Daily and monthly totals are summed from those files.

MONTHLY_BUDGET=800
DAILY_BUDGET=25
TRACKING_DIR="$HOME/.claude/cost-tracking"
mkdir -p "$TRACKING_DIR"

input=$(cat)

session_id=$(echo "$input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('session_id',''))" 2>/dev/null)
session_cost=$(echo "$input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('cost',{}).get('total_cost_usd',0))" 2>/dev/null || echo 0)
ctx_pct=$(echo "$input" | python3 -c "import sys,json; d=json.load(sys.stdin); v=d.get('context_window',{}).get('used_percentage'); print(int(round(v)) if v is not None else '')" 2>/dev/null)

# Persist session cost to a dated file so we can sum across sessions
today=$(date +%Y-%m-%d)
month=$(date +%Y-%m)

if [ -n "$session_id" ]; then
  session_file="$TRACKING_DIR/${today}_${session_id}.cost"
  printf '%s\n' "$session_cost" > "$session_file"
fi

# Sum all session files for today and this month
daily_total=$(awk '{s+=$1} END {printf "%.4f", s+0}' "$TRACKING_DIR"/${today}_*.cost 2>/dev/null || echo "0.0000")
monthly_total=$(awk '{s+=$1} END {printf "%.4f", s+0}' "$TRACKING_DIR"/${month}-*.cost 2>/dev/null || echo "0.0000")

# Format: monthly to 2 decimal places, daily to 1, session to 2
monthly_fmt=$(awk -v v="$monthly_total" 'BEGIN {printf "%.2f", v}')
daily_fmt=$(awk -v v="$daily_total" 'BEGIN {printf "%.1f", v}')
session_fmt=$(awk -v v="$session_cost" 'BEGIN {printf "%.2f", v+0}')

# ANSI colors (POSIX-safe)
ESC=$(printf '\033')
YELLOW="${ESC}[33m"
RED="${ESC}[31m"
RESET="${ESC}[0m"

# Returns a colored 5-char bar for a given pct (0-100+)
bar() {
  pct="$1"
  filled=$(awk -v p="$pct" 'BEGIN { f=int(p/10); if(f>10) f=10; print f }')
  empty=$((10 - filled))
  over=$(awk -v p="$pct" 'BEGIN { print (p > 100) ? "+" : " " }')
  if awk -v p="$pct" 'BEGIN { exit !(p >= 90) }'; then
    color="$RED"
  elif awk -v p="$pct" 'BEGIN { exit !(p >= 70) }'; then
    color="$YELLOW"
  else
    color=""
  fi
  b=""
  i=0
  while [ $i -lt "$filled" ]; do b="${b}="; i=$((i+1)); done
  i=0
  while [ $i -lt "$empty" ];  do b="${b}-"; i=$((i+1)); done
  printf "${color}[${b}]${RESET}"
}

# Color for monthly cost: yellow at 80% of budget ($640), red at 100% ($800)
monthly_threshold=$(awk -v v="$monthly_total" -v b="$MONTHLY_BUDGET" \
  'BEGIN { pct = v / b * 100; if (pct >= 100) print "red"; else if (pct >= 80) print "yellow"; else print "none" }')
case "$monthly_threshold" in
  red)    monthly_color="$RED" ;;
  yellow) monthly_color="$YELLOW" ;;
  *)      monthly_color="" ;;
esac

# Color for daily cost: yellow at $20, red at $25
daily_threshold=$(awk -v v="$daily_total" \
  'BEGIN { if (v >= 25) print "red"; else if (v >= 20) print "yellow"; else print "none" }')
case "$daily_threshold" in
  red)    daily_color="$RED" ;;
  yellow) daily_color="$YELLOW" ;;
  *)      daily_color="" ;;
esac

out=""
if [ -n "$ctx_pct" ]; then
  ctx_bar=$(bar "$ctx_pct")
  out="| ctx ${ctx_pct}% ${ctx_bar} "
fi

out="${out}| \$${session_fmt} session | ${daily_color}\$${daily_fmt}${RESET} today | ${monthly_color}\$${monthly_fmt}${RESET} month"

printf '%s\n' "${out}"
