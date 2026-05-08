#!/bin/bash
# $0 <host>
if [ $# -ne 1 ]; then
  echo "Usage: $0 <host>"
  exit 1
fi
REMOTE_HOST="$1"
BACKUP_DEST="backup/backup-${REMOTE_HOST}-$(date +%Y%m%d)"
mkdir -p "$BACKUP_DEST"
for lib in lib/*.sh; do
  source "$lib"
done

read -p "backup files? [Y/n] " answer
if [[ "$answer" = "Y" || "$answer" = "y" || "$answer" = "" ]]; then
  echo "Starting backup..."
  # skip empty lines and comments
  while IFS= read -r line; do
    if [[ -z "$line" || "$line" =~ ^# ]]; then
      continue
    fi
    echo "Backing up $line..."
    mkdir -p "$BACKUP_DEST$line"
    cp-remote "$line"
  done < "$BACKUP_CONF"
else
  echo "Backup files cancelled."
fi

read -p "backup mariadb? [Y/n] " answer
if [[ "$answer" = "Y" || "$answer" = "y" || "$answer" = "" ]]; then
  ssh-dump-mariadb
fi
