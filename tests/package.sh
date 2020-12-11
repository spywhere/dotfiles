#!/bin/bash

set -e

SCRIPT_DIRNAME=$(dirname $0)
SCRIPT_DIR=$(realpath $(pwd)/$SCRIPT_DIRNAME)
VOLUME=$(dirname $SCRIPT_DIR)

usage() {
  cat <<EOF
usage: $0 [flags] <package> <platform> -- [arguments ...]

flags:
  -h, --help      Show this help message

available packages:
EOF
  for file in $VOLUME/docker/*; do
    local name=$(basename $file)
    printf "  %s\n" $name
  done
}

if test "$1" = ""; then
  usage
  exit
fi

while test "$1" != ""; do
  case $1 in
    -h | --help)
      usage
      exit
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
  if test -d $VOLUME/docker/$1; then
    if test "$PACKAGE" != ""; then
      printf "ERROR: only one package is needed\n"
      exit 1
    fi
    PACKAGE="$1"
  else
    case $1 in
      --)
        shift
        break
        ;;
      *)
        break
        ;;
    esac
  fi

  shift
done

if test "$1" = ""; then
  cat <<EOF
package "$PACKAGE" has the following platform supported:
EOF
  for file in $VOLUME/docker/$PACKAGE/Dockerfile.*; do
    if ! test -f $file; then
      continue
    fi
    name=$(basename $file | cut -c12-)
    printf "  %s\n" $name
  done
  cat <<EOF

run: $0 [flags] $PACKAGE <platform> -- [arguments ...]
EOF
  exit
fi

while test "$1" != ""; do
  if test -f $SCRIPT_DIR/Dockerfile.$1; then
    PLATFORM="$1"
    shift
    break
  else
    case $1 in
      --)
        shift
        break
        ;;
      *)
        if test -d $VOLUME/docker/$1; then
          printf "ERROR: package \"$1\" is not supported on \"$PLATFORM\"\n"
        else
          printf "ERROR: unknown package \"$1\"\n"
        fi
        exit 1
        break
        ;;
    esac
  fi

  shift
done

printf "Testing $PACKAGE on $PLATFORM...\n"

ARGS="$@"

dockerfile="$VOLUME/docker/$PACKAGE/Dockerfile.$PLATFORM"
docker build --no-cache -t dots-$PACKAGE:$PLATFORM - <$dockerfile
test_image="$(cat $dockerfile | head -n1 | sed 's/^FROM //g' | sed 's/ AS .*//g')"
binary_file="$(docker image inspect dots-hstr:alpine --format="{{.Config.Labels.BINARY}}")"
dependency_cmd="$(docker image inspect dots-hstr:alpine --format="{{.Config.Labels.DEPS}}")"
test_flags="$(docker image inspect dots-hstr:alpine --format="{{.Config.Labels.TEST}}")"
echo "Running binary container..."
container="$(docker run --rm -d dots-$PACKAGE:$PLATFORM sleep 30 | cut -c-12)"
echo "Binary Container: $container"
echo "Runnng testing container..."
test_container="$(docker run --rm -d $test_image sleep 30 | cut -c-12)"
echo "Test Container: $test_container"
echo "Copying binary from binary container..."
docker cp $container:/usr/bin/$PACKAGE $VOLUME/.deps/$binary_file
echo "Copying binary to testing container..."
docker cp $VOLUME/.deps/$binary_file $test_container:/usr/bin/$binary_file
echo "Testing binary..."
docker exec -it $test_container $dependency_cmd
docker exec -it $test_container $binary_file $test_flags
echo "Cleaning up..."
docker stop "$container" "$test_container"
docker rmi -f dots-$PACKAGE:$PLATFORM
