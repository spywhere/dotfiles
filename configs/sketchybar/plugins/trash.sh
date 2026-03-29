#!/bin/bash

ICON="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FullTrashIcon.icns"
PROMPT="Are you sure you want to permanently erase the items in the Trash?\n\nYou can\'t undo this action."
CANCEL_BUTTON="Cancel"
DEFAULT_BUTTON="Empty Trash"

if test "$SENDER" = "mouse.clicked"; then
  if test "$MODIFIER" = "none"; then
    prompt_script="var app=Application.currentApplication();app.includeStandardAdditions=true;app.displayDialog('$PROMPT', {buttons: ['$CANCEL_BUTTON', '$DEFAULT_BUTTON'], defaultButton: 2, withIcon: Path('$ICON')});"
    if osascript -l JavaScript -e "$prompt_script"; then
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
