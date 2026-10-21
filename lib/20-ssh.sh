function ssh-dump-mariadb(){
  ssh $REMOTE_HOST $SSH_TTY_FLAG -C "mysqldump -u root -p --all-databases > mariadb.sql"
  rsync -arz $RSYNC_RESUME_FLAG --stats --ignore-existing $REMOTE_HOST:mariadb.sql $BACKUP_DEST/
  ssh $REMOTE_HOST $SSH_TTY_FLAG -C "rm mariadb.sql"
}

function backup-om-ct(){
  if ask "backup ct configs? [Y/n]"; then
    ssh $SSH_TTY_FLAG "$REMOTE_HOST" "./om-ct/bin/back-configs.sh"
  else
    echo "ct configs backup skipped."
  fi

  if ask "download config backups? [Y/n]"; then
    mkdir -p "$BACKUP_DEST"
    rsync -arz $RSYNC_RESUME_FLAG --stats --ignore-existing $REMOTE_HOST:back-configs $BACKUP_DEST/
  else
    echo "download config backups skipped."
  fi

  if ask "backup ct volumes? [Y/n]"; then
    ssh $SSH_TTY_FLAG "$REMOTE_HOST" "./om-ct/bin/back-volumes.sh"
  else
    echo "ct volumes backup skipped."
  fi

  if ask "download volume backups? [Y/n]"; then
    mkdir -p "$BACKUP_DEST"
    rsync -arz $RSYNC_RESUME_FLAG --stats --ignore-existing $REMOTE_HOST:back-volumes $BACKUP_DEST/
  else
    echo "download volume backups skipped."
  fi

  if ask "purge backups? [Y/n]"; then
    ssh $REMOTE_HOST "rm -rf back-configs back-volumes"
  else
    echo "purge backups skipped."
  fi
}