#!/usr/bin/env bash

input=$(cat)

q() { jq -r "$1" <<<"$input"; }

human() {
  local n=$1
  if [ -z "$n" ] || [ "$n" = "null" ]; then echo "0"; return; fi
  awk -v n="$n" 'BEGIN {
    if (n >= 1000000) printf "%.1fM", n / 1000000
    else if (n >= 1000) printf "%.1fK", n / 1000
    else printf "%d", n
  }' | sed 's/\.0\([KM]\)/\1/'
}

reset_in() {
  local at=$1
  if [ -z "$at" ] || [ "$at" = "null" ]; then return; fi
  local secs=$(( at - $(date +%s) ))
  [ "$secs" -lt 0 ] && secs=0
  if [ "$secs" -ge 86400 ]; then
    printf "%dd%dh" $((secs / 86400)) $((secs % 86400 / 3600))
  elif [ "$secs" -ge 3600 ]; then
    printf "%dh%dm" $((secs / 3600)) $((secs % 3600 / 60))
  else
    printf "%dm" $((secs / 60))
  fi
}

pct_color() {
  local p=${1%.*}
  if [ "$p" -ge 80 ]; then printf '\033[31m'
  elif [ "$p" -ge 50 ]; then printf '\033[33m'
  else printf '\033[32m'
  fi
}

reset=$'\033[0m'
dim=$'\033[2m'
sep=" ${dim}·${reset} "

cwd=$(q '.workspace.current_dir // .cwd')
dir=${cwd/#$HOME/\~}
branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
model=$(q '.model.display_name')
effort=$(q '.effort.level // empty')
fast=$(q '.fast_mode // false')
size=$(q '.context_window.context_window_size // 0')
remaining=$(q '.context_window.remaining_percentage // empty')
total_in=$(q '.context_window.total_input_tokens // 0')
total_out=$(q '.context_window.total_output_tokens // 0')
five=$(q '.rate_limits.five_hour.used_percentage // empty')
five_at=$(q '.rate_limits.five_hour.resets_at // empty')
week=$(q '.rate_limits.seven_day.used_percentage // empty')
week_at=$(q '.rate_limits.seven_day.resets_at // empty')

parts=()
parts+=("$(printf '\033[36m%s\033[0m' "$dir")")
[ -n "$branch" ] && parts+=("$(printf '\033[35m%s\033[0m' "$branch")")

model_text="$model"
[ -n "$effort" ] && model_text="$model_text $effort"
[ "$fast" = "true" ] && model_text="$model_text fast"
parts+=("$(printf '\033[34m%s\033[0m' "$model_text")")

parts+=("$(human "$size") window")
if [ -n "$remaining" ]; then
  used=$((100 - ${remaining%.*}))
  parts+=("$(pct_color "$used")${remaining%.*}% left${reset}")
fi
parts+=("$(human "$total_in") in")
parts+=("$(human "$total_out") out")
parts+=("$(human $((total_in + total_out))) used")

if [ -n "$five" ]; then
  parts+=("5h $(pct_color "$five")${five%.*}%${reset}${dim} $(reset_in "$five_at")${reset}")
fi
if [ -n "$week" ]; then
  parts+=("weekly $(pct_color "$week")${week%.*}%${reset}${dim} $(reset_in "$week_at")${reset}")
fi

out=""
for part in "${parts[@]}"; do
  if [ -z "$out" ]; then out="$part"; else out="$out$sep$part"; fi
done
printf '%s\n' "$out"
