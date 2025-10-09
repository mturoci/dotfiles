#!/bin/bash

cpu_usage=$(top -l 1 | awk '/CPU usage/ {print $3}' | cut -d'%' -f1)
mem_used=$(top -l 1 | awk '/PhysMem/ {print $2}' | cut -d'M' -f1)
mem_total=$(top -l 1 | awk '/PhysMem/ {print $6}' | cut -d'M' -f1)

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

# echo " #[fg=#3a3a3a]#[fg=#a7c080,bg=#3a3a3a]  $(date +"%H:%M ") $color_mem  $mem_usage% $color_cpu  $cpu_usage% "
echo " #[fg=#3a3a3a]#[fg=#a7c080,bg=#3a3a3a]  $(date +"%H:%M ") $color_cpu  $cpu_usage% "
