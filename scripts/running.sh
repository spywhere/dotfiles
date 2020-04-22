if command docker 2>/dev/null; then
  docker_start=""
  docker_info=$(docker info 2>&1)
  if [ $? -eq 0 ]; then
    docker_start=""
  fi
  if echo $docker_info | grep "refused"; then
    docker_start=""
  fi

  if [ $docker_start -z ]; then
    printf ""
  else
    printf "  %s" $docker_start
  fi
else
  printf ""
fi
