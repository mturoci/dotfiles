#!/bin/bash

if [[ "$(uname)" == "Darwin" ]]; then
  top_out=$(top -l 1)
  cpu_usage=$(echo "$top_out" | awk '/CPU usage/ {print $3}' | cut -d'%' -f1)
  mem_used=$(echo "$top_out" | awk '/PhysMem/ {print $2}' | cut -d'M' -f1)
  mem_total=$(echo "$top_out" | awk '/PhysMem/ {print $6}' | cut -d'M' -f1)
else
  cpu_idle=$(top -bn 1 | awk '/^%Cpu/ {
    n = split($0, a, ",")
    for (i=1; i<=n; i++) {
      if (a[i] ~ /id/) {
        match(a[i], /[0-9]+\.?[0-9]*/)
        print substr(a[i], RSTART, RLENGTH)
      }
    }
  }')
  cpu_usage=$(echo "scale=1; 100 - $cpu_idle" | bc)
  mem_used=$(free -m | awk '/^Mem:/ {print $3}')
  mem_total=$(free -m | awk '/^Mem:/ {print $2}')
fi

mem_usage=$(echo "scale=2; $mem_used/$mem_total*100" | bc)

if (( $(echo "$cpu_usage < 10.0" | bc -l) )); then
  cpu_usage=" $cpu_usage"
fi

if (( $(echo "$mem_usage < 10.0" | bc -l) )); then
  mem_usage=" $mem_usage"
fi

color_cpu=""
if (( $(echo "$cpu_usage < 25.0" | bc -l) )); then
  color_cpu="#[fg=#a7c080]"
elif (( $(echo "$cpu_usage < 50.0" | bc -l) )); then
  color_cpu="#[fg=yellow]"
elif (( $(echo "$cpu_usage < 75.0" | bc -l) )); then
  color_cpu="#[fg=orange]"
else
  color_cpu="#[fg=red]"
fi

color_mem=""
if (( $(echo "$mem_usage < 25.0" | bc -l) )); then
  color_mem="#[fg=#a7c080]"
elif (( $(echo "$mem_usage < 50.0" | bc -l) )); then
  color_mem="#[fg=yellow]"
elif (( $(echo "$mem_usage < 75.0" | bc -l) )); then
  color_mem="#[fg=orange]"
else
  color_mem="#[fg=red]"
fi

echo "#[fg=#3a3a3a]#[fg=#a7c080,bg=#3a3a3a]  $(date +"%H:%M ")  $color_cpu  $cpu_usage% "
