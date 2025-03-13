#!/usr/bin/env bash
export BORG_REPO=/mnt/data/backup
export BORG_PASSPHRASE_FILE=/home/daniel/.config/borg/passphrase

# Create a new backup archive with a timestamp
borg create -v --stats --compression zstd ::'{hostname}-{now:%Y-%m-%d_%H:%M:%S}' /home/daniel 

# Optionally, prune old backups
borg prune -v --list --keep-daily=7 --keep-weekly=4 --keep-monthly=6
