#!/usr/bin/env bash
# $0 <host>
if [ $# -ne 1 ]; then
  echo "Usage: $0 <host>"
  exit 1
fi
REMOTE_HOST="$1"
BACKUP_DEST="zz-backup/backup-${REMOTE_HOST}-$(date +%Y%m%d)"
mkdir -p "$BACKUP_DEST"
for lib in lib/*.sh; do
  source "$lib"
done

while IFS= read -r line; do
  if [[ -z "$line" || "$line" =~ ^# ]]; then
    continue
  fi
  read -p "backup $line? [Y/n] " answer </dev/tty
  if [[ "$answer" = "Y" || "$answer" = "y" || "$answer" = "" ]]; then
    echo "Backing up $line..."
    mkdir -p "$BACKUP_DEST/$line"
    cp-remote "$line"
  else
    echo "$line skipped."
  fi
done < "$BACKUP_CONF"

read -p "backup mariadb? [Y/n] " answer </dev/tty
if [[ "$answer" = "Y" || "$answer" = "y" || "$answer" = "" ]]; then
  ssh-dump-mariadb
else
  echo "mariadb backup skipped."
fi
