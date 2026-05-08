# backup scripts
bash scripts to automate backup process

## variants
### lnmp-full.sh
traditional backup folder backup methed.
- rsync all directory from config file.

### om-ct.sh
used with my om-ct repo
## presets
```
# gitlab
/var/opt/gitlab/backups
# web root
/opt/www
/var/www
# nginx
/etc/nginx
```