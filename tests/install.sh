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
  -u, --upgrade   Simulate an upgrade
  -f, --force     Suppress warnings

By default, test will simulate a remote installation from scatch.

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
UPGRADE=0
FORCE=0
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
    -f | --force)
      FORCE=1
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

if test $UPGRADE -eq 0; then
  INSTALL_PATH="/root/dots"
else
  INSTALL_PATH="/root/.dots"
fi

if test $LOCAL -eq 0; then
  SCRIPT="sh -c \"\$(cat $INSTALL_PATH/install.sh)\" - $ARGS"
else
  SCRIPT="sh $INSTALL_PATH/install.sh $ARGS"
fi

if test $RECREATE -eq 1 -o "$(docker images dots:$PLATFORM -q)" = ""; then
  docker build --no-cache --network=host -t dots:$PLATFORM - <$SCRIPT_DIR/Dockerfile.$PLATFORM
fi

if test "$(git status -s)" != "" -a $FORCE -eq 0 -a $LOCAL -eq 0 -a $UPGRADE -eq 1; then
  printf "Changes detected!\n"
  printf "Perform a remote upgrade on local installation will override any changes you've made.\n"
  printf "Run the test script again with --force flag to suppress this check.\n"
  exit 1
fi

docker run -it $KEEP --network=host -v /var/run/docker.sock:/var/run/docker.sock -v $VOLUME:$INSTALL_PATH dots:$PLATFORM sh -c "$SCRIPT"
