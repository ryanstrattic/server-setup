#!/bin/bash
clear

# Setup
BACKUP_DIR="/mnt/volume-fra1-02/"
BACKUP_RUNNING_FILE="$BACKUP_DIR/backup-running.txt"
DATE=$(date +"%Y-%m-%d")
BACKUP_SQL_FILE=$BACKUP_DIR/database-backup-$DATE.sql

# Dump the database
mysqldump -u ryan -p66536653 -h localhost wordpress > $BACKUP_SQL_FILE

# Only run if backup not already running
if [ ! -f $BACKUP_RUNNING_FILE ]
	then
	touch $BACKUP_RUNNING_FILE
	rsync $BACKUP_DIR/* -avzhe ssh root@31.220.42.178:/home/ryan/droplet6test/
fi

# Backup task complete, so remove any files created during backup process
rm $BACKUP_RUNNING_FILE
rm $BACKUP_SQL_FILE
