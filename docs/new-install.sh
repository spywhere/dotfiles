#!sh

require_tools=""

add() {
  for item in $1; do
    if test $item = "$2"; then
      echo "$1"
      return
    fi
  done

  echo "$1" \"$2\"
}

brew() {
  require_tools=`add "$require_tools" "homebrew"`
}

dpkg() {
  require_tools=`add "$require_tools" "curl"`
}

brew
dpkg
require_tools=`add "$require_tools" "curl x"`

echo $require_tools
