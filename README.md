# Backup Configuration Guide

This repository contains scripts to configure automated backups using BorgBackup. By default, it backs up the live root filesystem directly. Optionally, it can use Logical Volume Manager (LVM) snapshots for consistency. Backups are scheduled via cron and stored on a remote storage box mounted via CIFS.

## Overview

- **Backup Tool**: BorgBackup (encrypted, deduplicated backups)
- **Schedule**: Daily at 3:00 AM (configurable via cron)
- **Storage**: Remote storage box mounted at `/mnt/storagebox`
- **Snapshot (Optional)**: LVM snapshot of the root filesystem (enabled with `USE_LVM=true`)
- **Retention**: Keeps 30 daily backups
- **Scripts**: Provided in this repository
- **Environment**: Configured via a `.env` file

## Repository Contents

- `borg.sh`: Wrapper script for BorgBackup commands.
- `create_backup.sh`: Main backup script.
- `create_snapshot.sh`: Creates an LVM snapshot (LVM only).
- `remove_snapshot.sh`: Removes the LVM snapshot (LVM only).

## Prerequisites

1. **Root Access**: You need root privileges to set up the scripts and cron job.
2. **BorgBackup**: Install BorgBackup (`borg`) on your system.
   - On Debian/Ubuntu: `apt install borgbackup`
   - On Fedora: `dnf install borgbackup`
3. **CIFS Support**: Install `cifs-utils` for mounting the remote storage box.
   - On Debian/Ubuntu: `apt install cifs-utils`
   - On Fedora: `dnf install cifs-utils`
4. **Remote Storage**: A storage box (e.g., Hetzner Storage Box) accessible via CIFS.
5. **LVM (Optional)**: Required only if using LVM snapshots.
6. **Git**: To clone this repository.

## Setup Instructions

### Common Steps

1. **Clone the Repository**
   - Clone this repository to `/backup`:
     ```bash
     git clone https://github.com/kreutix/borg-backup.git /backup
     cd /backup
     chmod +x *.sh
     ```

2. **Create the `.env` File**
   - Create a `.env` file in `/backup` with the following content:
     ```bash
     export BORG_PASSPHRASE="your-secure-passphrase"
     export BORG_REPO=/mnt/storagebox/borg/s1
     ```
   - Replace `your-secure-passphrase` with a strong passphrase.
   - Optionally, add `export USE_LVM=true` if you want to use LVM snapshots (default is `false` if not set).
   - Secure the file:
     ```bash
     chmod 600 /backup/.env
     ```
   - The `borg.sh` and `create_backup.sh` scripts source this file automatically.

3. **Mount the Remote Storage Box**
   - Create a credentials file for the CIFS mount:
     ```bash
     echo "username=your-username" > /etc/storagebox-credentials.txt
     echo "password=your-password" >> /etc/storagebox-credentials.txt
     chmod 600 /etc/storagebox-credentials.txt
     ```
   - Add the following line to `/etc/fstab` (replace `<STORAGEBOX_ID>` with your storage box ID):
     ```
     //<STORAGEBOX_ID>.your-storagebox.de/backup /mnt/storagebox cifs credentials=/etc/storagebox-credentials.txt,uid=0,gid=0,file_mode=0660,dir_mode=0770,iocharset=utf8,rw 0 0
     ```
   - Mount the storage:
     ```bash
     mkdir -p /mnt/storagebox
     mount /mnt/storagebox
     ```

4. **Initialize the Borg Repository**
   - Source the `.env` file and initialize the repository:
     ```bash
     source /backup/.env
     /backup/borg.sh init --encryption=repokey
     ```

5. **Set Up the Cron Job**
   - Edit the root crontab:
     ```bash
     crontab -e
     ```
   - Add the following line to run the backup daily at 3:00 AM:
     ```
     0 3 * * * /backup/create_backup.sh
     ```

### Default Setup (No LVM)

By default, the backup runs directly on the root filesystem (`/`) without LVM snapshots (`USE_LVM` is `false` or unset).

1. **Test the Setup**
   - Manually run the backup script:
     ```bash
     /backup/create_backup.sh
     ```
   - Check the Borg repository for the new backup:
     ```bash
     /backup/borg.sh list
     ```

### Optional Setup with LVM

This setup uses LVM snapshots for a consistent backup of the root filesystem.

1. **Verify LVM Setup**
   - Ensure your root filesystem (`/`) is on an LVM volume (e.g., `/dev/vg0/root`).
   - Check with:
     ```bash
     lvs
     ```
   - Adjust `create_snapshot.sh` and `remove_snapshot.sh` if your volume group or logical volume names differ.

2. **Configure `.env`**
   - Add the following line to `/backup/.env`:
     ```bash
     export USE_LVM=true
     ```

3. **Test the Setup**
   - Manually run the backup script:
     ```bash
     /backup/create_backup.sh
     ```
   - Check the Borg repository for the new backup:
     ```bash
     /backup/borg.sh list
     ```

## Notes

- **Default (No LVM)**: Backups run directly on `/` if `USE_LVM` is `false` or not set. This is simpler but may include inconsistent data if files change during the backup.
- **With LVM**: Snapshots ensure filesystem consistency but require sufficient free space in the volume group. Set `USE_LVM=true`.
- **Security**: Keep the `.env` file and CIFS credentials secure.
- **Logs**: Cron job output is emailed to the root user by default. Redirect output to a file if needed (e.g., `>> /var/log/backup.log 2>&1`).

## Troubleshooting

- **Mount Issues**: Verify the CIFS mount with `mount | grep /mnt/storagebox`.
- **Borg Errors**: Check the passphrase and repository path in `.env`.
- **LVM Errors**: Ensure enough free space exists (`vgdisplay`) and `USE_LVM` is set correctly.
