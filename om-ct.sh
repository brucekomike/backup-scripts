#!/usr/bin/env bash
# $0 <host>

REMOTE_HOST="$1"
BACKUP_DEST="zz-backup/backup-${REMOTE_HOST}-ct-$(date +%Y%m%d)"

source lib/00-init.sh

read -p "backup ct configs? [Y/n] " answer </dev/tty
if [[ "$answer" = "Y" || "$answer" = "y" || "$answer" = "" ]]; then
  ssh -t "$REMOTE_HOST" "./om-ct/bin/back-configs.sh"
else
  echo "ct configs backup skipped."
fi

read -p "download config backups? [Y/n] " answer </dev/tty
if [[ "$answer" = "Y" || "$answer" = "y" || "$answer" = "" ]]; then
  mkdir -p "$BACKUP_DEST"
  rsync -arzP --stats --ignore-existing $REMOTE_HOST:back-configs $BACKUP_DEST/
else
  echo "download config backups skipped."
fi

read -p "backup ct volumes? [Y/n] " answer </dev/tty
if [[ "$answer" = "Y" || "$answer" = "y" || "$answer" = "" ]]; then
  ssh -t "$REMOTE_HOST" "./om-ct/bin/back-volumes.sh"
else
  echo "ct volumes backup skipped."
fi

read -p "download volume backups? [Y/n] " answer </dev/tty
if [[ "$answer" = "Y" || "$answer" = "y" || "$answer" = "" ]]; then
  mkdir -p "$BACKUP_DEST"
  rsync -arzP --stats --ignore-existing $REMOTE_HOST:back-volumes $BACKUP_DEST/
else
  echo "download volume backups skipped."
fi

read -p "purge backups? [Y/n] " answer </dev/tty
if [[ "$answer" = "Y" || "$answer" = "y" || "$answer" = "" ]]; then
  ssh -t "$REMOTE_HOST" "rm -rf back-configs back-volumes"
else
  echo "purge backups skipped."
fi
