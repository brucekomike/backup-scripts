# $0 <folder>
function cp-remote(){
  local folder="$1"
  rsync -arzP --stats --ignore-existing --exclude-from=lib/.rsync-exclude $REMOTE_HOST:$folder/ $BACKUP_DEST/$folder
}
function cp-local(){
  local src_folder="$1"
  local dest_folder="$2"
  rsync -arzP --stats --ignore-existing --exclude-from=lib/.rsync-exclude $src_folder/ $dest_folder/
}
