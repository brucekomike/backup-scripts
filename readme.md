# backup scripts
bash scripts to automate backup process

## usage
```
./lnmp-full.sh [-s|--silent] <target>
```

### flags
- `-s`, `--silent`: run unattended — skip opening the config file in nano and
  assume "Y" for all prompts. Fails fast if no config file/group exists for the host.

A config file can contain regular directories (one per line) plus special
flags:
- `%mariadb`: run the mariadb dump steps for that host. Always asks for
  manual confirmation, even in silent mode (because the password must be
  typed in manually).
- `%om-ct`: run the om-ct backup steps (back up and download ct configs
  and volumes) for that host.

## config group
instead of a single `conf/<host>.conf` file, create a `conf/<host>/` folder
containing multiple `*.conf` files. All of them are executed (in sorted order),
effectively running the group of configs for the host.

## backup destination
- single file: `conf/bk-401.conf` → `zz-backup/backup-bk-401-YYYYMMDD/`
- group: `conf/oss/ossmedia.conf` → `zz-backup/oss/backup-ossmedia-YYYYMMDD/`
  each config group gets its own subfolder under `zz-backup/`.

## ssh host name
the ssh host is derived from the config file name (without the `.conf` suffix).
- single file: `conf/bk-401.conf` → ssh host `bk-401`
- group: `conf/myhost/db1.conf`, `conf/myhost/db2.conf` → ssh hosts `db1`, `db2`

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