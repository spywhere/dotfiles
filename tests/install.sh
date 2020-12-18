#!/bin/bash

set -e

SCRIPT_DIRNAME=$(dirname $0)
SCRIPT_DIR=$(realpath $(pwd)/$SCRIPT_DIRNAME)

usage() {
  cat <<EOF
usage: $0 [flags] <platform> -- [arguments ...]

flags:
  -h, --help      Show this help message
  -r, --recreate  Always recreate test image
  -k, --keep      Do not autoremove the container
  -l, --local     Simulate a local installation
  -u, --upgrade   Simulate a local upgrade

supported platforms:
EOF
  for file in $SCRIPT_DIR/Dockerfile.*; do
    local name=$(basename $file | cut -c12-)
    printf "  %s\n" $name
  done
}

if test "$1" = ""; then
  usage
  exit
fi

RECREATE=0
KEEP="--rm"
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
    -k | --keep)
      KEEP=""
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
  if test -f $SCRIPT_DIR/Dockerfile.$1; then
    if test "$PLATFORM" != ""; then
      printf "ERROR: only one platform is needed\n"
      exit 1
    fi
    PLATFORM="$1"
  else
    case $1 in
      --)
        shift
        break
        ;;
      -*)
        printf "ERROR: unexpected flag \"$1\" after the platform\n"
        exit 1
        ;;
      *)
        printf "ERROR: unknown platform \"$1\"\n"
        exit 1
        ;;
    esac
  fi

  shift
done

printf "Testing on $PLATFORM...\n"

VOLUME=$(dirname $SCRIPT_DIR)
ARGS="$@"

if test $RECREATE -eq 1 -o "$(docker images dots:$PLATFORM -q)" = ""; then
  docker build --no-cache -t dots:$PLATFORM - <$SCRIPT_DIR/Dockerfile.$PLATFORM
fi
if test $LOCAL -eq 0; then
  docker run -it $KEEP -v /var/run/docker.sock:/var/run/docker.sock -v $VOLUME:/root/dots dots:$PLATFORM sh -c "sh -c \"\$(cat /root/dots/install.sh)\" - $ARGS"
elif test $LOCAL -eq 1; then
  docker run -it $KEEP -v /var/run/docker.sock:/var/run/docker.sock -v $VOLUME:/root/dots dots:$PLATFORM sh -c "sh /root/dots/install.sh $ARGS"
else
  docker run -it $KEEP -v /var/run/docker.sock:/var/run/docker.sock -v $VOLUME:/root/.dots dots:$PLATFORM sh -c "sh /root/.dots/install.sh $ARGS"
fi
