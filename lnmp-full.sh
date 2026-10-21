#!/usr/bin/env bash
# $0 [-s|--silent] <target>
for lib in lib/*.sh; do
  source "$lib"
done
parse-args "$@"
if [ ${#POSITIONAL_ARGS[@]} -ne 1 ]; then
  echo "Usage: $0 [-s|--silent] <target>"
  exit 1
fi
REMOTE_TARGET="${POSITIONAL_ARGS[0]}"
resolve-config

for CONF_FILE in "${CONF_FILES[@]}"; do
  # REMOTE_HOST is the ssh host: the config file name without .conf
  REMOTE_HOST="$(basename "${CONF_FILE%.conf}")"
  resolve-backup-dest "$REMOTE_HOST" "" "$CONF_FILE"

  if ! check-remote-command "$REMOTE_HOST" "rsync"; then
    echo "Error: rsync is not installed on $REMOTE_HOST." >&2
    exit 1
  fi
done

for CONF_FILE in "${CONF_FILES[@]}"; do
  # REMOTE_HOST is the ssh host: the config file name without .conf
  REMOTE_HOST="$(basename "${CONF_FILE%.conf}")"
  resolve-backup-dest "$REMOTE_HOST" "" "$CONF_FILE"

  mkdir -p "$BACKUP_DEST"

  echo "=== $CONF_FILE ==="
  # mapfile keeps a final line that has no trailing newline (read -r would drop it)
  mapfile -t CONF_LINES < "$CONF_FILE"
  for line in "${CONF_LINES[@]}"; do
    # trim leading/trailing whitespace
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    if [[ -z "$line" || "$line" =~ ^# ]]; then
      continue
    fi
    if [[ "$line" == "%om-ct" ]]; then
      backup-om-ct
      continue
    fi
    if [[ "$line" == "%mariadb" ]]; then
      # always requires manual confirmation (needs manual password input)
      if ask-always "backup mariadb on $REMOTE_HOST? [Y/n]"; then
        ssh-dump-mariadb
      else
        echo "mariadb backup skipped."
      fi
      continue
    fi
    if ask "backup $line? [Y/n]"; then
      echo "Backing up $line..."
      mkdir -p "$BACKUP_DEST/$line"
      cp-remote "$line"
    else
      echo "$line skipped."
    fi
  done
done
