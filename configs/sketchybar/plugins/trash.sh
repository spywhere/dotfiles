#!/bin/bash

if test "$SENDER" = "mouse.clicked"; then
  if test "$MODIFIER" = "none"; then
    action="$(osascript -l JavaScript -e "var app=Application.currentApplication();app.includeStandardAdditions=true;app.displayDialog('Are you sure you want to permanently erase the items in the Trash?\n\nYou can\'t undo this action.', {buttons: ['Cancel', 'Empty Trash'], defaultButton: 2, withIcon: Path('/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FullTrashIcon.icns')});")"
    if test "$action" = "buttonReturned:Empty Trash"; then
      osascript -l JavaScript -e 'var finder=Application("Finder");if(finder.trash.items.length>0){finder.empty();}'
      sketchybar --set "$NAME" drawing=off
    fi
  else
    osascript -l JavaScript -e 'Application("Finder").trash.open();'
  fi
  exit
fi

TRASH_ITEMS="$(osascript -l JavaScript -e 'Application("Finder").trash.items.length')"
if test "$TRASH_ITEMS" -gt 0; then
  sketchybar --set "$NAME" drawing=on label="$TRASH_ITEMS"
else
  sketchybar --set "$NAME" drawing=off
fi
