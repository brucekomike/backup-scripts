# mariadb-dump on current installs, mysqldump on older ones
function remote-dump-bin(){
  local bin
  for bin in mariadb-dump mysqldump; do
    if check-remote-command "$REMOTE_HOST" "$bin"; then
      echo "$bin"
      return 0
    fi
  done
  return 1
}

# root@localhost authenticating with the unix_socket plugin needs no password,
# but it does need to be OS root - passwordless sudo is what makes that unattended
function mariadb-socket-available(){
  ssh "$REMOTE_HOST" "sudo -n true" >/dev/null 2>&1
}

# dumps over the unix socket when MARIADB_SOCKET=1, otherwise asks for the root password
function ssh-dump-mariadb(){
  local bin
  if ! bin="$(remote-dump-bin)"; then
    echo "Error: neither mariadb-dump nor mysqldump found on $REMOTE_HOST." >&2
    return 1
  fi

  if [ "${MARIADB_SOCKET:-0}" -eq 1 ]; then
    echo "dumping all databases as root over the unix socket..."
    # the redirect is done by the login shell, so mariadb.sql stays owned by the login user
    if ssh $REMOTE_HOST -C "sudo -n $bin --all-databases > mariadb.sql"; then
      fetch-mariadb-dump
      return 0
    fi
    # a failed dump leaves a truncated file that --ignore-existing would keep forever
    ssh $REMOTE_HOST "rm -f mariadb.sql"
    if [ "${SILENT:-0}" -eq 1 ]; then
      echo "Error: unix_socket dump failed and --silent cannot type the root password." >&2
      return 1
    fi
    echo "unix_socket dump failed, falling back to the root password." >&2
  fi

  ssh $REMOTE_HOST $SSH_TTY_FLAG -C "$bin -u root -p --all-databases > mariadb.sql"
  fetch-mariadb-dump
}

function fetch-mariadb-dump(){
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