if command vcgencmd 2>/dev/null; then
  echo $(vcgencmd measure_temp | sed -e "s/temp=//" -e "s/.0'C//")
else
  echo ""
fi
