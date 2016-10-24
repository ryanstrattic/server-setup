
# Things to do first
* Install Ubuntu 16.04 with public key authentication
* Point domain at new IP address
* MOUNT 20 GB DRIVE AND USE THAT INSTEAD OF /mnt/volume-fra1/ - automatically mounts on reboot

# Notes and required improvements
* Implementation time tested at 50 minutes
* List all variables at start of document
* Just replace whole .vlc file instead of editing
* Just replace whole nginx.conf and default instead of editing

== https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-16-04
== https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-16-04
== https://www.digitalocean.com/community/tutorials/how-to-configure-varnish-cache-4-0-with-ssl-termination-on-ubuntu-14-04
== https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-16-04

var 138.68.65.194 = 
/mnt/volume-fra1/ = 
var ryanhellyer@gmail.com = 
var ryan = 
var ryan = 
var droplet6.hellyer.kiwi = 
root = 
31.220.42.178 = 
/home/ryan/droplet6test/ = 
git@github.com:ryanhellyer/server-setup.git
[Git email] ryanhellyer@gmail.com"
[GitHub name] Ryan Hellyer
[WordPress site title] Test Site
[WordPress username] ryan
[WordPress password[ 66536653
[WordPress user email] ryanhellyer@gmail.com

Select defaults unless otherwise specified.

# Login as root
	ssh root@138.68.65.194 # Log in as root

# Create public key and copy to external server (used for backing stuff up later)
Choose defaults (no password).
	ssh-keygen -t rsa -b 4096 -C "ryanhellyer@gmail.com"
Copy public key to the ~/.ssh/authorized_keys file on the external server
	cat ~/.ssh/id_rsa.pub

# Setup new user
Create new user, set their password, give them sudo priviledges and log in as them.
	adduser ryan
	usermod -aG sudo ryan
	exit
	ssh ryan@138.68.65.194
Remove the need for a password when logging in as the new user. First we create the new SSH folder, then add our own public key (found on your local computer) to the authorized_keys file.
	mkdir ~/.ssh
	nano ~/.ssh/authorized_keys
	chmod 600 ~/.ssh/authorized_keys
Improve security by changing the line that specifies "PasswordAuthentication". uncomment it, then change its value to "no". Then reload the SSH daemon.
	sudo nano /etc/ssh/sshd_config

	sudo systemctl reload sshd
Confirm the new login works with no password before continuing.
	exit
	ssh ryan@138.68.65.194

# Adjust firewall settings
 Allow OpenSSH and enable UFW by selecting "y"
	sudo ufw allow OpenSSH
	sudo ufw enable

# Install Nginx
	sudo apt-get update
	sudo apt-get install nginx
	sudo ufw allow 'Nginx HTTP'

# Install PHP 7
Install PHP FPM and PHP MySQL
	sudo apt-get install php-fpm php-mysql
Uncomment and change "cgi.fix_pathinfo" to "0" for improved security.
	sudo nano /etc/php/7.0/fpm/php.ini
Replace with "nginx.conf"
	sudo nano /etc/nginx/nginx.conf
	sudo mkdir /etc/nginx/global/
Copy "restrictions.conf"
	sudo nano /etc/nginx/global/restrictions.conf
Copy "wordpress.conf"
	sudo nano /etc/nginx/global/wordpress.conf
Replace with "default.txt".
	sudo nano /etc/nginx/sites-available/default
sudo service nginx restart

# Setup https via Lets Encrypt
	sudo apt-get install letsencrypt
	sudo mkdir /mnt/volume-fra1/droplet6.hellyer.kiwi/
	sudo mkdir /mnt/volume-fra1/droplet6.hellyer.kiwi/public_html/
	sudo letsencrypt certonly -a webroot --webroot-path=/mnt/volume-fra1/droplet6.hellyer.kiwi/public_html/ -d droplet6.hellyer.kiwi
Generate Diffie Hellman group - takes a while!
	sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
Copy from "domain.conf".
	sudo nano /etc/nginx/snippets/ssl-droplet6.hellyer.kiwi.conf
Copy from "ssl-params.conf".
	sudo nano /etc/nginx/snippets/ssl-params.conf
Allow Nginx HTTPS through the firewall
	sudo ufw allow 'Nginx Full'
Reboot Nginx
	sudo service nginx restart
Renew - not sure if this is needed
	sudo letsencrypt renew
Setup auto renewal of http certificates - copy "sudo-crontab.txt".
	sudo crontab -e

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
Replace with "user.vcl".
	sudo nano /etc/varnish/user.vcl
Reboot Nginx - NECESSARY HERE?
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
	[mysql] SET PASSWORD FOR 'root'@'localhost' = PASSWORD('MyNewRootPassword');
	[mysql] exit;
Check password works
	mysql -u root -pMyNewRootPassword
Create new database and add new user to it
	[mysql]CREATE DATABASE wordpressdb;
	[mysql]GRANT ALL PRIVILEGES ON wordpressdb.* To 'ryan'@'localhost' IDENTIFIED BY 'MyNewPassword';
	[mysql] exit;

# Check new user can log in
	mysql -u ryan -pMyNewPassword
	[mysql] exit;

# Install WP CLI (it'd be nice to setup auto-updating in future)
	cd /mnt/volume-fra1/
	sudo curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
	php wp-cli.phar --info # Check it works
	sudo chmod +x wp-cli.phar
	sudo mv wp-cli.phar /usr/local/bin/wp

	sudo chown ryan:ryan html/
	cd /mnt/volume-fra1/droplet6.hellyer.kiwi/public_html/
	wp core download
	wp core config --dbname=wordpressdb --dbuser=ryan --dbpass=66536653 --dbhost=localhost --dbprefix=test
	sudo nano /mnt/volume-fra1/droplet6.hellyer.kiwi/wp-config.php # needed so that WordPress knows we're using https and isn't confused by Varnish. Should probably be fixed in Varnish config
		if ( isset( $_SERVER['HTTP_X_FORWARDED_PROTO'] ) && $_SERVER['HTTP_X_FORWARDED_PROTO'] == 'https' ) {
			$_SERVER['HTTPS']='on';
		}
	sudo mv /mnt/volume-fra1/droplet6.hellyer.kiwi/public_html/wp-config.php /mnt/volume-fra1/wp-config.php # No point in storing wp-config.php in the web root

Add "wp-config.php" to beginning of file.
	sudo nano /mnt/volume-fra1/droplet6.hellyer.kiwi/wp-config.php
Install WordPress.
	wp core install --url=https://droplet6.hellyer.kiwi --title="Test Site" --admin_user=ryan --admin_password=66536653 --admin_email=ryanhellyer@gmail.com
Set permalinks.
	wp rewrite structure '/%postname%/'

# Make Git work with 
	ssh-keygen -t rsa -b 4096 -C "ryanhellyer@gmail.com"

# Install Redis
Install the Redis object cache. This results in a substantial improvement in the loading of dynamic WordPress pages.
	sudo apt-get install redis-server redis-tools php-redis
	wp plugin install wp-redis --activate
	mv wp-content/plugins/wp-redis/object-cache.php wp-content/object-cache.php

# Uninstall default plugins
	wp plugin uninstall hello
	wp plugin uninstall akismet

# Setup Cron jobs for WP CLI
Copy "wordpress-updates.sh".
	sudo nano /mnt/volume-fra1/wordpress-updates.sh

# Backup stuff to external server
Copy "wordpress-backups.sh".
	sudo nano /mnt/volume-fra1/wordpress-backups.sh

# Automate updates and backups
Copy "crontab.txt".
	sudo crontab -e

# Implement real Cron jobs
sudo nano /mnt/volume-fra1/wp-config.php
	/**
	 * Disabling WP Cron.
	 * Tasks will be handled by a real Cron instead (which loads the wp-cron.php file).
	 */
	define('DISABLE_WP_CRON', true);
sudo crontab -e
	# Firing up the WordPress Cron system
	* * * * * wget -q -O - https://droplet6.hellyer.kiwi/wp-cron.php?doing_wp_cron

# Auto-deployment from GitHub
cat ~/.ssh/id_rsa.pub # Copy to GitHub - https://github.com/settings/ssh
git clone git@github.com:ryanhellyer/server-setup.git .
git config --user.email "ryanhellyer@gmail.com"
git config --user.name "Ryan Hellyer"
Copy "auto-deployment.sh"
sudo nano /mnt/volume-fra1/auto-deployment.sh




# Copy Pressabl network over
wp search-replace
