if command vcgencmd 1>/dev/null 2>&1; then
  echo $(vcgencmd measure_temp | sed -e "s/temp=//" -e "s/'C//")
else
  echo ""
fi
