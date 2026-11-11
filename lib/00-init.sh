# shared init: arg parsing, env checks, config resolution, interactive/silent helpers

# parse [-s|--silent] from "$@"; sets SILENT, POSITIONAL_ARGS and mode flags; call at top of an entry script
function parse-args(){
  SILENT=0
  POSITIONAL_ARGS=()
  while [ $# -gt 0 ]; do
    case "$1" in
      -s) SILENT=1 ;;
      --silent) SILENT=1 ;;
      *) POSITIONAL_ARGS+=("$1") ;;
    esac
    shift
  done

  # -P prompts to restart, which blocks unattended runs
  if [ "$SILENT" -eq 1 ]; then
    RSYNC_RESUME_FLAG="--partial"
    SSH_TTY_FLAG=""
  else
    RSYNC_RESUME_FLAG="-P"
    SSH_TTY_FLAG="-t"
  fi
}

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

# ask "prompt": returns success for yes, skips the prompt in silent mode
function ask(){
  local prompt="$1"
  local answer=""
  if [ "$SILENT" -eq 1 ]; then
    echo "$prompt (silent: yes)"
  else
    read -p "$prompt " answer </dev/tty
  fi
  if [[ "$answer" = "Y" || "$answer" = "y" || "$answer" = "" ]]; then
    return 0
  fi
  return 1
}

# ask-always "prompt": always prompts manually, even in silent mode
# (e.g. steps requiring manual password input)
function ask-always(){
  local prompt="$1"
  local answer=""
  read -p "$prompt " answer </dev/tty
  if [[ "$answer" = "Y" || "$answer" = "y" || "$answer" = "" ]]; then
    return 0
  fi
  return 1
}

# sets BACKUP_DEST for a config file: zz-backup/backup-<host>[-suffix]-YYYYMMDD
# configs inside conf/<group>/ get their own subfolder: zz-backup/<group>/backup-<host>...
function resolve-backup-dest(){
  local host="$1"
  local suffix="${2:-}"
  local conf_file="${3:-}"
  local conf_dir="$(dirname "$conf_file")"
  if [[ "$(basename "$conf_dir")" != "conf" ]]; then
    BACKUP_DEST="zz-backup/$(basename "$conf_dir")/backup-${host}${suffix}-$(date +%Y%m%d)"
  else
    BACKUP_DEST="zz-backup/backup-${host}${suffix}-$(date +%Y%m%d)"
  fi
}

# resolves CONF_FILES from REMOTE_TARGET (a conf location name):
#   conf/<target>.conf (single file) | conf/<target> (single file) | conf/<target>/ (group)
# opens nano for a single new file in interactive mode
function resolve-config(){
  CONF_BASE="conf/$REMOTE_TARGET"
  CONF_FILES=()
  if [[ -f "$CONF_BASE.conf" ]]; then
    CONF_FILES=("$CONF_BASE.conf")
  elif [[ -f "$CONF_BASE" ]]; then
    CONF_FILES=("$CONF_BASE")
  elif [[ -d "$CONF_BASE" ]]; then
    while IFS= read -r conf_file; do
      CONF_FILES+=("$conf_file")
    done < <(find "$CONF_BASE" -type f -name '*.conf' | sort)
  fi

  if [ ${#CONF_FILES[@]} -eq 0 ]; then
    if [ "$SILENT" -eq 1 ]; then
      echo "Error: no config file or group found for $REMOTE_TARGET." >&2
      exit 1
    fi
    echo "# this is the configuration file for $REMOTE_TARGET" > "$CONF_BASE.conf"
    echo "# put the dirs that need to be backed up in the following format:" >> "$CONF_BASE.conf"
    echo "# /var/www" >> "$CONF_BASE.conf"
    echo "# /etc/nginx" >> "$CONF_BASE.conf"
    echo "# single dir perline" >> "$CONF_BASE.conf"
    echo "# %mariadb  -> trigger a mariadb dump for this host (passwordless unix_socket when sudo -n works)" >> "$CONF_BASE.conf"
    echo "# %om-ct    -> run the om-ct backup steps for this host" >> "$CONF_BASE.conf"
    echo "# close the editor to start the backup process" >> "$CONF_BASE.conf"
    CONF_FILES=("$CONF_BASE.conf")
  fi

  if [ "$SILENT" -eq 1 ]; then
    echo "Using config: ${CONF_FILES[*]}"
  elif [ ${#CONF_FILES[@]} -gt 1 ]; then
    echo "Config group: ${#CONF_FILES[@]} config files in $CONF_BASE/:"
    printf '  %s\n' "${CONF_FILES[@]}"
    echo "Edit the conf files directly to modify the group."
  else
    nano "${CONF_FILES[0]}"
  fi
}
