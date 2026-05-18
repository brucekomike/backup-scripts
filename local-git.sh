#!/usr/bin/env bash
# $0 <src> <dest>
if [ $# -ne 2 ]; then
  echo "Usage: $0 <src> <dest>"
  exit 1
fi
SRC="$1"
DEST="$2"

if [ ! -d "$DEST" ]; then
    echo "Destination directory $DEST does not exist."
    exit 1
fi

DEST="$DEST/$(basename "$SRC")$(date +%Y%m%d)"

if [ ! -d "$SRC" ]; then
    echo "Source directory $SRC does not exist."
    exit 1
fi
mkdir -p "$DEST"


source lib/10-file.sh

cp-local "$SRC" "$DEST"