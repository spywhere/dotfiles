if command vcgencmd 2>/dev/null; then
  temp=$(vcgencmd measure_temp | sed -e "s/temp=//" -e "s/'C//")
  printf "%sc  " "$temp"
else
  printf ""
fi
