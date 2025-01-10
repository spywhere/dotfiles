#!/bin/sh

set -e

if
  ! (command -v force_print >/dev/null 2>&1) ||
  ! (force_print 3 a b >/dev/null 2>&1) ||
  test "$(force_print 3 a b)" != "a  b";
then
  printf "Please run this script through \"install.sh\" instead"
  exit 1
fi

has_string '4210bbbd-7376-4c55-ac3a-093552be821c' gpt --uuid

use_bin 'gpt' 'https://raw.githubusercontent.com/spywhere/gpt/main/gpt'
