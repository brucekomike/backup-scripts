# $0 <folder>
function cp-remote(){
  local folder="$1"
rsync -arzPh --stats --exclude-from=lib/.rsync-exclude $REMOTE_HOST:$folder/ $BACKUP_DEST/$folder
}
function cp-sftp(){
  local folder="$1"
  sftp $REMOTE_HOST <<EOF
  cd $folder/..
  get $(basename $folder) $BACKUP_DEST/$folder
  quit
EOF
}
function cp-local(){
  local src_folder="$1"
  local dest_folder="$2"
  rsync -arPh --stats --exclude-from=lib/.rsync-exclude $src_folder/ $dest_folder/
}
