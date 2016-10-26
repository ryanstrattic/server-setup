#!/bin/bash
clear

# Backing up configuration files
zip --password "ttsbjW1231!#" /home/ryan/Documents/storage/Important/filezilla-passwords-rh1s.zip /home/ryan/.filezilla/site$
zip --password "ttsbjW1231!#" /home/ryan/Documents/storage/Important/wifi-passwords-rh1s.zip /etc/NetworkManager/system-conn$
zip --password "ttsbjW1231!#" /home/ryan/Documents/storage/Important/hosts-file-rh1s.zip /etc/hosts
chown ryan:ryan /home/ryan/Documents/storage/Important/* -R

# Syncing storage.hellyer.kiwi
BACKUP_DIR="/home/ryan/Documents/storage.hellyer.kiwi/"
BACKUP_RUNNING_FILE="$BACKUP_DIR/backup-running.txt"
if [ ! -f $BACKUP_RUNNING_FILE ]
	then
	touch $BACKUP_RUNNING_FILE
	rsync $BACKUP_DIR/* -avzhe ssh external_server_username@IPExternalAddress:/external/server/path/
fi
rm $BACKUP_RUNNING_FILE

# Syncing stuff.hellyer.kiwi
BACKUP_DIR="/home/ryan/Documents/stuff.hellyer.kiwi/"
BACKUP_RUNNING_FILE="$BACKUP_DIR/stuff-running.txt"
if [ ! -f $BACKUP_RUNNING_FILE ]
	then
	touch $BACKUP_RUNNING_FILE
	rsync $BACKUP_DIR/* -avzhe ssh external_server_username@IPExternalAddress:/external/server/path/
fi
rm $BACKUP_RUNNING_FILE
