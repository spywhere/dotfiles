#!/bin/bash

app="Control Center"

if test "$NAME" = "clock"; then
  app="Clock"
fi

script="$(cat <<EOF
const items = Application("System Events").processes["Control Center"].menuBars[0].menuBarItems;
for (let i=0;i<items.length;i++) {
  if (items[i].description().indexOf('$app') >= 0) {
    items[i].click();
	break;
  }
}
EOF
)"

osascript -l JavaScript -e "$script"
