#!/bin/bash

set -e

usage() {
  cat <<EOF
usage: $0 [flag] [platform] -- [arguments ...]

flags:
  -h, --help      Show this help message
  -r, --recreate  Always recreate test image
  -l, --local     Simulate a local installation
  -u, --upgrade   Simulate a local upgrade

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
LOCAL=0
while test "$1" != ""; do
  case $1 in
    -h | --help)
      usage
      exit
      ;;
    -r | --recrate)
      RECREATE=1
      ;;
    -l | --local)
      LOCAL=1
      ;;
    -u | --upgrade)
      LOCAL=2
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

SCRIPT_DIRNAME=$(dirname $0)
SCRIPT_DIR=$(realpath $(pwd)/$SCRIPT_DIRNAME)
VOLUME=$(dirname $SCRIPT_DIR)

if test $RECREATE -eq 1 -o "$(docker images dots:$PLATFORM -q)" = ""; then
  docker build --no-cache -t dots:$PLATFORM - <Dockerfile.$PLATFORM
fi
if test $LOCAL -eq 0; then
  docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock -v $VOLUME:/root/dots dots:$PLATFORM sh -c "cat /root/dots/install.sh | sh -s -- $@"
elif test $LOCAL -eq 1; then
  docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock -v $VOLUME:/root/dots dots:$PLATFORM sh -c "sh /root/dots/install.sh $@"
else
  docker run -it --rm -v /var/run/docker.sock:/var/run/docker.sock -v $VOLUME:/root/.dots dots:$PLATFORM sh -c "sh /root/.dots/install.sh $@"
fi
