Use multisite sub-folder setup (commented out within wordpress.conf)
Copy redirects



Two servers
	1. Pressabl
	2. Backup
		Domains
			stuff.hellyer.kiwi
				syncs once per hour from local (combined with storage)
				manual sync button (combined with stuff and dev)
				/mnt/string/stuff.hellyer.kiwi/
				static only
			storage.hellyer.kiwi
				* password protected *
				syncs once per hour from local (combined with storage)
				manual sync button (combined with storage and dev)
				/mnt/string/storage.hellyer.kiwi/
				static only
			pressabl
				/mnt/string/pressabl/
				Updates once per week from AWS S3
				Need hosts file to see site
			dev.hellyer.kiwi
				* password protected *
				syncs once per hour from vagrant (combined with storage and stuff)
				manual sync button (combined with storage and stuff)
			client.hellyer.kiwi
				* password protected *
				example site only
				/mnt/string/


		Backups
			Syncs once per week with AWS S3



/home/ryan/Documents/storage.hellyer.kiwi/Important/backup.sh
