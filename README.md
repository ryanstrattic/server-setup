# Things to do first
* Install Ubuntu 16.04 with public key authentication
* Point domain at new IP address
* MOUNT 20 GB DRIVE AND USE THAT INSTEAD OF /VAR/WWW/ - automatically mounts on reboot

Variables which need to be changed before using this tutorial:

Server details

	IPAddress
	/var/www/
	your_email@example.com
	ryanuser
	droplet3.hellyer.kiwi

SQL

	ryansqluser
	SQLRootPassword
	wordpressdb

External backup server

	external_server_username
	IPExternalAddress
	/external/server/path/

GitHub

	git@github.com:ryanhellyer/server-setup.git
	ryanhellyer@gmail.com"
	Ryan Hellyer
	githubrepo
	github@gmail.com
	githubusername

WordPress

	Test Site
	wordpressadmin
	wordpresspassword
	wordpress@gmail.com


Select defaults unless otherwise specified.

# Login as root
	ssh root@IPAddress

# Create public key and copy to external server (used for backing stuff up later)
Choose defaults (no password).

	ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

Copy public key to the ~/.ssh/authorized_keys file on the external server

	cat ~/.ssh/id_rsa.pub

# Setup new user
Create new user, set their password, give them sudo priviledges and log in as them.

	adduser ryanuser # Create new user
	usermod -aG sudo ryanuser
	exit
	ssh ryanuser@IPAddress

Remove the need for a password when logging in as the new user. First we create the new SSH folder, then add our own public key (found on your local computer) to the authorized_keys file.

	mkdir ~/.ssh
	nano ~/.ssh/authorized_keys
	chmod 600 ~/.ssh/authorized_keys

Improve security by changing the line that specifies "PasswordAuthentication". uncomment it, then change its value to "no". Then reload the SSH daemon.
	sudo nano /etc/ssh/sshd_config

	sudo systemctl reload sshd

Confirm the new login works with no password before continuing.

	exit
	ssh ryanuser@IPAddress

# Adjust firewall settings
 Allow OpenSSH and enable UFW by selecting "y"

	sudo ufw allow OpenSSH
	sudo ufw enable

# Install Nginx
	sudo apt-get update
	sudo apt-get install nginx
	sudo ufw allow 'Nginx HTTP'

# Implement new Nginx configuration - copy default.txt
	sudo nano /etc/nginx/sites-available/default

# Setup Lets Encrypt
	sudo apt-get install letsencrypt
	sudo mkdir /var/www/droplet3.hellyer.kiwi/
	sudo mkdir /var/www/droplet3.hellyer.kiwi/public_html/
	sudo service nginx restart
	sudo letsencrypt certonly -a webroot --webroot-path=/var/www/droplet3.hellyer.kiwi/public_html/ -d droplet3.hellyer.kiwi

Generate Diffie Hellman group - takes a while!

	sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

Copy from "ssl-domain.conf".

	sudo nano /etc/nginx/snippets/ssl-droplet3.hellyer.kiwi.conf

Copy from "ssl-params.conf".

	sudo nano /etc/nginx/snippets/ssl-params.conf


Removing default config now that we've obtained our TLS certificate

	sudo rm /etc/nginx/sites-available/default

Allow Nginx HTTPS through the firewall

	sudo ufw allow 'Nginx Full'

Reboot Nginx (PROBABLY NOT NECESSARY)

	sudo service nginx restart

# Install Varnish
Add Varnish repository to aptitude.

	curl https://repo.varnish-cache.org/ubuntu/GPG-key.txt | sudo apt-key add -
	sudo sh -c 'echo "deb https://repo.varnish-cache.org/ubuntu/ trusty varnish-4.0" >> /etc/apt/sources.list.d/varnish-cache.list'
	sudo apt-get update
	sudo apt-get install varnish

Change the port to "80" and manually set config file location to "user.vcl".
DAEMON_OPTS="-a :80 \
-f /etc/varnish/user.vcl \

	sudo nano /etc/default/varnish

Copy "user.vcl".

	sudo nano /etc/varnish/user.vcl

Reboot Nginx

	sudo service nginx restart

	sudo mkdir /etc/systemd/system/varnish.service.d/

Copy "customexec.conf".

	sudo nano /etc/systemd/system/varnish.service.d/customexec.conf

Restart Varnish

	sudo systemctl daemon-reload
	sudo service varnish restart

# Setup automatic security updates
Follow the prompts to enable automatic security upgrades.

	sudo apt-get install unattended-upgrades
	sudo dpkg-reconfigure -plow unattended-upgrades

# Install MariaDB
	sudo apt-get install mariadb-server

Set MariaDB root password

	sudo mysql -u root
	[mysql] use mysql;
	[mysql] update user set plugin='' where User='root'; # Forcing password usage
	[mysql] flush privileges;
	[mysql] SET PASSWORD FOR 'root'@'localhost' = PASSWORD('SQLRootPassword');

Create new database and add new user to it

	[mysql]CREATE DATABASE wordpressdb;
	[mysql]GRANT ALL PRIVILEGES ON wordpressdb.* To 'ryansqluser'@'localhost' IDENTIFIED BY 'MyNewPassword';
	[mysql] exit;

# Install PHP 7
Install PHP FPM and PHP MySQL

	sudo apt-get install php-fpm php-mysql

Change "cgi.fix_pathinfo" to "0" for improved security.

	sudo nano /etc/php/7.0/fpm/php.ini

Replace existing files with "nginx.conf", "restrictions.conf" and "wordpress.conf"

	sudo mkdir /etc/nginx/global/
	sudo nano /etc/nginx/global/restrictions.conf
	sudo nano /etc/nginx/nginx.conf
	sudo nano /etc/nginx/global/wordpress.conf

Replace with "domain.txt".

	sudo nano /etc/nginx/sites-available/droplet3.hellyer.kiwi.conf

Softlink to enable the site

	sudo ln -s /etc/nginx/sites-available/droplet3.hellyer.kiwi.conf /etc/nginx/sites-enabled/droplet3.hellyer.kiwi.conf

# Install WP CLI (it'd be nice to setup auto-updating in future)
	cd /var/www/
	sudo curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
	sudo chmod +x wp-cli.phar
	sudo mv wp-cli.phar /usr/local/bin/wp

	sudo chown ryan:ryan droplet3.hellyer.kiwi/public_html/
	cd /var/www/droplet3.hellyer.kiwi/public_html/
	wp core download
	wp core config --dbname=wordpressdb --dbuser=ryansqluser --dbpass=66536653 --dbhost=localhost --dbprefix=test

Move wp-config.php outside of the web root

	sudo mv /var/www/droplet3.hellyer.kiwi/public_html/wp-config.php /var/www/droplet3.hellyer.kiwi/wp-config.php

Add "wp-config.php" to beginning of file.

	sudo nano /var/www/droplet3.hellyer.kiwi/wp-config.php

Install WordPress.

	wp core install --url=https://droplet3.hellyer.kiwi --title="Test Site" --admin_user=wordpressadmin --admin_password=wordpresspassword --admin_email=wordpress@gmail.com

Set permalinks.
	wp rewrite structure '/%postname%/'
	sudo chown www-data:www-data uploads -R

Set permissions and ownership

	sudo chown www-data:www-data wp-content/uploads -R
	sudo chmod 744 wp-content/uploads -R
#	sudo chmod 400 ../../wp-config.php - this is causing problems

# Make Git work

	ssh-keygen -t rsa -b 4096 -C "ryanhellyer@gmail.com"

# Install Redis
Install the Redis object cache. This results in a substantial improvement in the loading of dynamic WordPress pages.

	sudo apt-get install redis-server redis-tools php-redis
	wp plugin install wp-redis --activate
	mv wp-content/plugins/wp-redis/object-cache.php wp-content/object-cache.php
	sudo service php7.0-fpm restart

# Remove and add plugins
	wp plugin uninstall hello
	wp plugin uninstall akismet
	wp plugin install google-authenticator --activate

# Setup Cron jobs for WP CLI
Copy "wordpress-updates.sh".

	sudo nano /var/www/wordpress-updates.sh

# Backup stuff to external server
Copy "wordpress-backups.sh".

	sudo nano /var/www/wordpress-backups.sh

# Automate stuff
Copy "crontab.txt".

	sudo crontab -e

# Auto-deployment from GitHub
ssh-keygen -t rsa -b 4096 -C "ryanhellyer@gmail.com"

Copy to GitHub - https://github.com/settings/ssh

	cat ~/.ssh/id_rsa.pub

	git clone git@github.com:githubrepo/server-setup.git .
	git config --user.email "github@gmail.com"
	git config --user.name "githubusername"

Copy "auto-deployment.sh"

	sudo nano /mnt/volume-nyc1-01/auto-deployment.sh



# Copy Pressabl network over

	wp search-replace
