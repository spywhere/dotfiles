#!/bin/bash

if test "$SENDER" = "mouse.clicked"; then
  action="$(osascript -l JavaScript -e "var app=Application.currentApplication();app.includeStandardAdditions=true;app.displayDialog('Are you sure you want to permanently erase the items in the Trash?\n\nYou can\'t undo this action.', {buttons: ['Cancel', 'Empty Trash'], defaultButton: 2, withIcon: Path('/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FullTrashIcon.icns')});")"
  if test "$action" = "Empty Trash"; then
    osascript -l JavaScript -e 'var finder=Application("Finder");if(finder.trash.items.length>0){finder.empty();}'
    sketchybar --set "$NAME" icon.drawing=off
  fi
  exit
fi

DRAWING="off"
if test "$(osascript -l JavaScript -e 'Application("Finder").trash.items.length > 0')" = "true"; then
  DRAWING="on"
fi

sketchybar --set "$NAME" icon.drawing="$DRAWING"
