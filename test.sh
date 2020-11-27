print() {
  if test -z "$#"; then
    echo
    return
  fi
  if test "$#" -le 2; then
    printf "$1 $2\n"
    return
  fi
  printf "%-$1s%s\n" "$2" "$3"
}

custom_function=""

. systems/macos.sh

use_custom() {
  custom_function="$1"
}

source packages/docker.sh

if test "$custom_function" != ""; then
  "$custom_function"
fi
