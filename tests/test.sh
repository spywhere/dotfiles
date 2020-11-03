#!/bin/bash

set -e

usage() {
  cat <<EOF
usage: $0 [flag] [platform] -- [arguments ...]

flags:
  -h, --help      Show this help message
  -r, --recreate  Always recreate test image

supported platforms:
  alpine
  raspios
EOF
}

if test "$1" = ""; then
  usage
  exit
fi

RECREATE=0
while test "$1" != ""; do
  case $1 in
    -h | --help)
      usage
      exit
      ;;
    -r | --recrate)
      RECREATE=1
      ;;
    -*)
      printf "ERROR: unknown flag \"$1\"\n"
      exit 1
      ;;
    *)
      break
      ;;
  esac

  shift
done

while test "$1" != ""; do
  case $1 in
    alpine | raspios)
      if test "$PLATFORM" != ""; then
        printf "ERROR: only one platform is needed\n"
        exit 1
      fi
      PLATFORM="$1"
      ;;
    --)
      shift
      break
      ;;
    *)
      printf "ERROR: unknown platform \"$1\"\n"
      exit 1
      ;;
  esac

  shift
done

printf "Testing on $PLATFORM...\n"

if test $RECREATE -eq 1 -o "$(docker images dots:$PLATFORM -q)" = ""; then
  docker build --no-cache -t dots:$PLATFORM - <Dockerfile.$PLATFORM
fi
docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock -v ~/.dots:/root dots:$PLATFORM sh -c "cat /root/install.sh | sh -s -- $@"
