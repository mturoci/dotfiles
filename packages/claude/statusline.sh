#!/usr/bin/env bash

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name')
dir_name=$(basename "$cwd")

branch=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi

used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
pct_int=0
[ -n "$used_pct" ] && pct_int=$(printf '%.0f' "$used_pct")

cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
cost_fmt=""
[ -n "$cost" ] && cost_fmt=$(printf '%.2f' "$cost")

# Everforest powerline colors (24-bit)
fg_tc='\033[38;2;167;192;128m'    # green accent
bg_tc='\033[48;2;167;192;128m'    # green accent bg
fg_bg='\033[38;2;44;43;42m'       # dark text
fg_light='\033[38;2;58;58;58m'    # light bg as fg (for arrows)
bg_light='\033[48;2;58;58;58m'    # light bg
fg_gray='\033[38;2;98;98;98m'     # gray (thin separators)
fg_kitty='\033[38;2;39;38;39m'    # terminal bg as fg
bg_kitty='\033[48;2;39;38;39m'    # terminal bg
bold='\033[1m'
rst='\033[0m'

sep=''   # powerline arrow (U+E0B0)
thin=''  # powerline thin arrow (U+E0B1)

out=""

# → inactive segment start
out+="${bg_kitty}${fg_light}${sep}"

# dir segment (inactive)
out+="${bg_light}${fg_tc}  ${dir_name} "

# thin separator if git branch exists
if [ -n "$branch" ]; then
  out+="${fg_gray}${thin}"
  out+="${fg_tc}  ${branch} "
fi

# → inactive segment start
out+="${bg_kitty}${fg_light}${sep}"

# model segment (inactive)
out+="${bg_light}${fg_tc}  ${model} "

# active → inactive (context)
out+="${bg_light}${fg_tc}${sep}"

# context segment (inactive)
out+="${bg_light}${fg_tc}  ${pct_int}% "

# thin separator + cost if present
if [ -n "$cost_fmt" ]; then
  out+="${fg_gray}${thin}"
  out+="${fg_tc}  ${cost_fmt} "
fi

# inactive → terminal bg
out+="${bg_kitty}${fg_light}${sep}${rst}"

printf '%b\n' "$out"
