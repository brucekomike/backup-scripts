function check-command(){
  command -v "$1" >/dev/null 2>&1
}

function check-remote-command(){
  ssh "$1" "command -v \"$2\" >/dev/null 2>&1"
}

commandlist=(
  "rsync"
  "date"
  "nano"
  "mkdir"
  "ssh"
)

for cmd in "${commandlist[@]}"; do
  if ! check-command "$cmd"; then
    echo "Error: $cmd is not installed." >&2
    exit 1
  fi
done
BACKUP_CONF="conf/$REMOTE_HOST.conf"

if ! check-remote-command "$REMOTE_HOST" "rsync"; then
  echo "Error: rsync is not installed on $REMOTE_HOST." >&2
  exit 1
fi

if [[ -f "$BACKUP_CONF" ]]; then
  nano "$BACKUP_CONF"
else
  echo "# this is the configuration file for $REMOTE_HOST" > "$BACKUP_CONF"
  echo "# put the dirs that need to be backed up in the following format:" >> "$BACKUP_CONF"
  echo "# /var/www" >> "$BACKUP_CONF"
  echo "# /etc/nginx" >> "$BACKUP_CONF"
  echo "# single dir perline" >> "$BACKUP_CONF"
  echo "# close the editor to start the backup process" >> "$BACKUP_CONF"
  nano "$BACKUP_CONF"
fi
