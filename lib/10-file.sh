# $0 <folder>
function cp-remote(){
  local folder="$1"
  rsync -arzP --stats --ignore-existing --exclude-from=lib/.rsync-exclude $REMOTE_HOST:$folder/ $BACKUP_DEST$folder
}
