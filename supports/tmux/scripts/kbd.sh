#!/bin/sh

if test "$(command -v defaults 2>/dev/null)"; then
  kbd_layout="$(defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleCurrentKeyboardLayoutInputSourceID | sed 's/^com\.apple\.keylayout\.//g')"
  # show the layout if not English
  if test "$kbd_layout" != "ABC"; then
    printf "%s" "$kbd_layout"
  fi
fi
