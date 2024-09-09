#!/bin/sh
FOOBAR_ENV="0x1337"

if [ -n "$2" ] && [ -s "$2" ]; then
  cast wallet dk "$1" --unsafe-password $(gpg -qd $2) | sed 's/.*:.\s*//g'
else
  cast wallet dk "$1" --unsafe-password $(cat "$ETH_PASSWORD") | sed 's/.*:.\s*//g'
fi
