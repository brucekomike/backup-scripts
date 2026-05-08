function ssh-dump-mariadb(){
  ssh $REMOTE_HOST -t -C "mysqldump -u root -p --all-databases > mariadb.sql"
  rsync -arzP --stats --ignore-existing $REMOTE_HOST:mariadb.sql $BACKUP_DEST/
  ssh $REMOTE_HOST -t -C "rm mariadb.sql" 
}