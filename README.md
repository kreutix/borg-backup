# Backup Configuration Guide

This repository contains scripts to configure automated backups using BorgBackup. It backs up the root filesystem (`/`) via a temporary mount point. Optionally, it can use Logical Volume Manager (LVM) snapshots for consistency. Backups are scheduled via cron and stored on a remote storage box mounted via CIFS.

## Overview

- **Backup Tool**: BorgBackup (encrypted, deduplicated backups)
- **Schedule**: Daily at 3:00 AM (configurable via cron)
- **Storage**: Remote storage box mounted at `/mnt/storagebox/borg/<BACKUP_NAME>`
- **Snapshot (Optional)**: LVM snapshot of the root filesystem (enabled with `USE_LVM=true`)
- **Retention**: Keeps 30 daily backups
- **Scripts**: Provided in this repository
- **Environment**: Configured via a `.env` file

## Repository Contents

- `borg.sh`: Wrapper script for BorgBackup commands.
- `create_backup.sh`: Main backup script.
- `create_snapshot.sh`: Creates an LVM snapshot (LVM only).
- `remove_snapshot.sh`: Removes the LVM snapshot (LVM only).
- `create_bind_mount.sh`: Creates a bind mount of `/` (no LVM).
- `remove_bind_mount.sh`: Removes the bind mount (no LVM).
- `.env.example`: Example configuration file template.

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
     ```

2. **Create the `.env` File**
   - Copy the example configuration file to create your `.env`:
     ```bash
     cp .env.example .env
     ```
   - Edit the `.env` file and adjust the settings:
     - **Required**: Replace `your-secure-passphrase` with a strong passphrase.
     - **Optional (LVM)**: Uncomment and adjust the LVM variables if enabling snapshots. Defaults to bind mount if `USE_LVM` is unset or `false`.
     - **Note**: If `USE_LVM=true`, all LVM variables must be set. Ensure `BIND_MOUNT_POINT` and `LVM_MOUNT_POINT` are dedicated directories.
   - Secure the file:
     ```bash
     chmod 600 /backup/.env
     ```

3. **Mount the Remote Storage Box**
   - Create a credentials file for the CIFS mount:
     ```bash
     echo "username=your-username" > /etc/storagebox-credentials.txt
     echo "password=your-password" >> /etc/storagebox-credentials.txt
     chmod 600 /etc/storagebox-credentials.txt
     ```
   - Add the following line to `/etc/fstab` (replace `<STORAGEBOX_ID>` with your storage box ID and `<BACKUP_NAME>` with your backup name from `.env`):
     ```
     //<STORAGEBOX_ID>.your-storagebox.de/backup/borg/<BACKUP_NAME> /mnt/storagebox/borg/<BACKUP_NAME> cifs credentials=/etc/storagebox-credentials.txt,uid=0,gid=0,file_mode=0660,dir_mode=0770,iocharset=utf8,rw 0 0
     ```
   - Source the `.env` file and mount the storage:
     ```bash
     source /backup/.env
     mkdir -p "/mnt/storagebox/borg/${BACKUP_NAME}"
     mount "/mnt/storagebox/borg/${BACKUP_NAME}"
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

### Default Setup (Bind Mount)

By default, the backup uses a bind mount of `/` at `$BIND_MOUNT_POINT` (e.g., `/backup/root.bind`) to exclude mounted filesystems like `/mnt` or `/proc`.

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

This setup uses an LVM snapshot for a consistent backup of the root filesystem.

1. **Verify LVM Setup**
   - Ensure your root filesystem is on an LVM volume (check with `lvs`).
   - Update the LVM variables in `.env` to match your system.

2. **Configure `.env`**
   - Uncomment and adjust the LVM settings in `/backup/.env`, e.g.:
     ```bash
     export USE_LVM=true
     export LVM_VG=vg0
     export LVM_LV=root
     export LVM_SNAPSHOT_NAME=root.snapshot
     export LVM_SNAPSHOT_SIZE=10G
     export LVM_MOUNT_POINT=/backup/root.snapshot
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

## Stopping the Backup
- **Manual Run**: Press `Ctrl+C` to stop `create_backup.sh`. It will attempt to clean up the bind mount or snapshot.
- **Cron Job**: Find the PID with `ps aux | grep create_backup.sh` and run `kill <PID>`. For stubborn processes, use `kill -9 <PID>`.
- **Cleanup**: If interrupted, manually unmount with `umount $BIND_MOUNT_POINT` (no LVM) or `umount $LVM_MOUNT_POINT; lvremove -f /dev/$LVM_VG/$LVM_SNAPSHOT_NAME` (LVM).

## Notes

- **Default (Bind Mount)**: Uses a bind mount of `/` to back up only the root filesystem, excluding `/mnt`, `/dev`, etc.
- **With LVM**: Snapshots ensure filesystem consistency but require sufficient free space in the volume group. Set `USE_LVM=true` and configure all LVM variables.
- **Security**: Keep the `.env` file and CIFS credentials secure.
- **Logs**: Cron job output is emailed to the root user by default. Redirect output to a file if needed (e.g., `>> /var/log/backup.log 2>&1`).

## Troubleshooting

- **Mount Issues**: Verify the CIFS mount with `mount | grep /mnt/storagebox`.
- **Borg Errors**: Check the passphrase and repository path in `.env`.
- **LVM Errors**: Ensure enough free space exists (`vgdisplay`) and all LVM variables in `.env` are set correctly.
