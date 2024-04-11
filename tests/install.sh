#!/bin/bash

set -e

SCRIPT_DIRNAME=$(dirname "$0")
SCRIPT_DIR=$(realpath "$(pwd)/$SCRIPT_DIRNAME")

usage() {
  cat <<EOF
usage: $0 [flags] <platform> -- [arguments ...]

flags:
  -h, --help         Show this help message
  -r, --recreate     Always recreate test image
  -k, --keep         Do not autoremove the container
  -l, --local        Simulate an installation using local packages and setups
  -u, --upgrade      Simulate an installer upgrade
  -i, --installer    Simulate an installation from a local installer
  -e, --env <value>  Set environment variables

By default, test will simulate a remote installation from scatch.

supported platforms:
EOF
  for file in "$SCRIPT_DIR"/Dockerfile.*; do
    local name
    name=$(basename "$file" | cut -c12-)
    printf "  %s\n" "$name"
  done
}

if test "$1" = ""; then
  usage
  exit
fi

RECREATE=0
KEEP="--rm"
DOCKER_FLAGS="-it"
LOCAL=0
UPGRADE=0
INSTALLER=0
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
      UPGRADE=1
      ;;
    -i | --installer)
      INSTALLER=1
      ;;
    -e | --env)
      if test "$1" = "-e"; then
        case $2 in
          -*)
            printf "ERROR: flag \"%s\" required a value but received a flag \"%s\" instead\n" "$1" "$2"
            printf "  Use \"--env %s\" to force passing a value with a dash prefix" "$2"
            exit 1
            ;;
          *)
            ;;
        esac
      fi
      if test -z "$2"; then
        printf "ERROR: flag \"%s\" required a value\n" "$1"
        exit 1
      fi
      shift
      DOCKER_FLAGS="$DOCKER_FLAGS --env $1"
      ;;
    -*)
      printf "ERROR: unknown flag \"%s\"\n" "$1"
      exit 1
      ;;
    *)
      break
      ;;
  esac

  shift
done

while test "$1" != ""; do
  if test -f "$SCRIPT_DIR/Dockerfile.$1"; then
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
        printf "ERROR: unexpected flag \"%s\" after the platform\n" "$1"
        exit 1
        ;;
      *)
        printf "ERROR: unknown platform \"%s\"\n" "$1"
        exit 1
        ;;
    esac
  fi

  shift
done

if test -z "$PLATFORM"; then
  printf "ERROR: platform is required\n"
  exit 1
fi

printf "Testing on %s...\n" "$PLATFORM"

VOLUME=$(dirname "$SCRIPT_DIR")
ARGS="$*"

if test $INSTALLER -eq 0; then
  INSTALL_PATH="/root/installer"
else
  INSTALL_PATH="/root/.installer"
  DOCKER_FLAGS="$DOCKER_FLAGS --env INSTALLER_DIR=$INSTALL_PATH"
fi
if test $UPGRADE -eq 0; then
  SCRIPT="sh $INSTALL_PATH/install.sh $ARGS"
else
  SCRIPT="sh -c \"\$(cat $INSTALL_PATH/install.sh)\" - $ARGS"
fi

if test $LOCAL -eq 0; then
  DOTS_PATH="/root/dots"
else
  DOTS_PATH="/root/.dots"
fi

if test $RECREATE -eq 1 -o "$(docker images "dots:$PLATFORM" -q)" = ""; then
  docker build --no-cache --network=host -t "dots:$PLATFORM" - <"$SCRIPT_DIR/Dockerfile.$PLATFORM"
fi

# shellcheck disable=SC2086
docker run $DOCKER_FLAGS "$KEEP" --network=host -v /var/run/docker.sock:/var/run/docker.sock -v "$VOLUME:$DOTS_PATH" -v "$VOLUME:$INSTALL_PATH" "dots:$PLATFORM" sh -c "$SCRIPT"
