# borg-backup
This repository contains scripts to configure automated backups using BorgBackup. By default, it backs up the live root filesystem directly. Optionally, it can use Logical Volume Manager (LVM) snapshots for consistency. Backups are scheduled via cron and stored on a remote storage box mounted via CIFS.
