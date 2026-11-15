#!/bin/bash

# Extract CPU and memory usage - handles both macOS and Linux
if [[ "$(uname)" == "Darwin" ]]; then
  # macOS using top
  top_out=$(top -l 1)
  
  # Extract CPU usage: "CPU usage: XX.XX% user, YY.YY% sys, ZZ.ZZ% idle"
  cpu_usage=$(echo "$top_out" | grep "CPU usage" | awk '{print $3}' | cut -d'%' -f1)
  
  # Extract memory info from PhysMem line
  # PhysMem format: "PhysMem: XXXM used, YYYM free"
  phys_mem=$(echo "$top_out" | grep "PhysMem")
  mem_used=$(echo "$phys_mem" | awk '{print $2}' | cut -d'M' -f1)
  mem_free=$(echo "$phys_mem" | awk '{print $4}' | cut -d'M' -f1)
  
  # Total is used + free
  mem_total=$(awk "BEGIN {printf \"%.0f\", $mem_used + $mem_free}" 2>/dev/null)
  
  # Handle case where mem_total might be empty or zero
  if [[ -z "$mem_total" ]] || [[ "$mem_total" == "0" ]]; then
    mem_usage="0"
  else
    # Calculate memory percentage
    mem_usage=$(awk "BEGIN {printf \"%.1f\", ($mem_used/$mem_total)*100}" 2>/dev/null)
  fi
else
  # Linux using top and free
  
  # Extract CPU idle percentage from top output
  # top output format: "%Cpu(s):  X.X us,  X.X sy,  0.0 ni, X.X id, ..."
  cpu_idle=$(top -bn 1 2>/dev/null | awk '/^%Cpu/ {
    n = split($0, a, ",")
    for (i=1; i<=n; i++) {
      if (a[i] ~ /id/) {
        match(a[i], /[0-9]+\.?[0-9]*/)
        print substr(a[i], RSTART, RLENGTH)
        break
      }
    }
  }' | head -1)
  
  # Handle empty cpu_idle
  if [[ -z "$cpu_idle" ]]; then
    cpu_idle="0"
  fi
  
  # Calculate CPU usage as 100 - idle
  cpu_usage=$(awk "BEGIN {printf \"%.1f\", 100 - $cpu_idle}" 2>/dev/null)
  
  # Extract memory info
  mem_info=$(free -m | awk '/^Mem:/ {print $3, $2}')
  mem_used=$(echo "$mem_info" | awk '{print $1}')
  mem_total=$(echo "$mem_info" | awk '{print $2}')
  
  # Handle case where mem_total might be empty
  if [[ -z "$mem_total" ]] || [[ "$mem_total" == "0" ]]; then
    mem_usage="0"
  else
    # Calculate memory percentage
    mem_usage=$(awk "BEGIN {printf \"%.1f\", ($mem_used/$mem_total)*100}" 2>/dev/null)
  fi
fi

# Ensure we have valid numbers, default to 0 if extraction failed
cpu_usage=${cpu_usage:-0}
mem_usage=${mem_usage:-0}

# Pad single-digit percentages with a space for alignment
cpu_padded="$cpu_usage"
mem_padded="$mem_usage"

cpu_int=$(printf "%.0f" "$cpu_usage" 2>/dev/null)
if [[ -z "$cpu_int" ]]; then
  cpu_int=0
fi

if [[ $cpu_int -lt 10 ]]; then
  cpu_padded=" $cpu_usage"
fi

mem_int=$(printf "%.0f" "$mem_usage" 2>/dev/null)
if [[ -z "$mem_int" ]]; then
  mem_int=0
fi

if [[ $mem_int -lt 10 ]]; then
  mem_padded=" $mem_usage"
fi

# Set CPU color based on usage threshold
if [[ $cpu_int -lt 25 ]]; then
  color_cpu="#[fg=#a7c080]"
elif [[ $cpu_int -lt 50 ]]; then
  color_cpu="#[fg=yellow]"
elif [[ $cpu_int -lt 75 ]]; then
  color_cpu="#[fg=orange]"
else
  color_cpu="#[fg=red]"
fi

# Set memory color based on usage threshold
if [[ $mem_int -lt 25 ]]; then
  color_mem="#[fg=#a7c080]"
elif [[ $mem_int -lt 50 ]]; then
  color_mem="#[fg=yellow]"
elif [[ $mem_int -lt 75 ]]; then
  color_mem="#[fg=orange]"
else
  color_mem="#[fg=red]"
fi

# Output the status bar
echo "#[fg=#3a3a3a]#[fg=#a7c080,bg=#3a3a3a]  $(date +"%H:%M ")  $color_cpu  $cpu_padded%  $color_mem  $mem_padded%"
