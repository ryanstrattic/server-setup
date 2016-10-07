# Ryan's draft server setup

Do not bother following this server setup. It is very much a work in progress and probably includes many errors and security flaws. This is just here for my (Ryan's) use.



Point domain at new IP address

== https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-16-04

# Setup new user
	Ubuntu 16.04 with public key authentication
	ssh root@IPAddress # Log in as root
	adduser ryan # Create new user (set password, choose defaults for rest)
	usermod -aG sudo ryan # Give new user sudo priviledges

# Check new users login
	exit # Log out of root
	ssh ryan@IPAddress # Log in as new user

# Set user to not require pasword
mkdir ~/.ssh
nano ~/.ssh/authorized_keys # Add own public key
chmod 600 ~/.ssh/authorized_keys # Set file permissions
sudo nano /etc/ssh/sshd_config
# Find the line that specifies PasswordAuthentication, uncomment, then change its value to "no".
sudo systemctl reload sshd # Reload the SSH daemon

# Check that login now works with no password
exit
ssh ryan@139.59.213.98 # Log back in (this time we don't need a password)

# Adjust firewall settings
sudo ufw allow OpenSSH # Allow OpenSSH
sudo ufw enable # Enable UFW (select "y")

== https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-16-04

# Install Nginx
sudo apt-get update
sudo apt-get install nginx (select "Y")

# Allow Nginx in UFW firewall
sudo ufw allow 'Nginx HTTP'

# Check IP address shows Nginx default page

== https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-16-04
# Setup Lets Encrypt
sudo apt-get install letsencrypt # select default "Y"
sudo nano /etc/nginx/sites-available/default
		location ~ /.well-known {
			allow all;
		}
sudo letsencrypt certonly -a webroot --webroot-path=/var/www/html -d digitalocean.hellyer.kiwi # Create certificates

# Check Lets Encrypt certificates were indeed created
sudo ls -l /etc/letsencrypt/live/digitalocean.hellyer.kiwi

sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048 # Generate Diffie Hellman group - takes a while!

sudo nano /etc/nginx/snippets/ssl-digitalocean.hellyer.kiwi.conf
			ssl_certificate /etc/letsencrypt/live/digitalocean.hellyer.kiwi/fullchain.pem;
			ssl_certificate_key /etc/letsencrypt/live/digitalocean.hellyer.kiwi/privkey.pem;
sudo nano /etc/nginx/snippets/ssl-params.conf
			# from https://cipherli.st/
			# and https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html

			ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
			ssl_prefer_server_ciphers on;
			ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
			ssl_ecdh_curve secp384r1;
			ssl_session_cache shared:SSL:10m;
			ssl_session_tickets off;
			ssl_stapling on;
			ssl_stapling_verify on;
			resolver 8.8.8.8 8.8.4.4 valid=300s;
			resolver_timeout 5s;
			# Disable preloading HSTS for now.  You can use the commented out header line that includes
			# the "preload" directive if you understand the implications.
			#add_header Strict-Transport-Security "max-age=63072000; includeSubdomains; preload";
			add_header Strict-Transport-Security "max-age=63072000; includeSubdomains";
			add_header X-Frame-Options DENY;
			add_header X-Content-Type-Options nosniff;
			ssl_dhparam /etc/ssl/certs/dhparam.pem;

sudo nano /etc/nginx/sites-available/default # Replace server block start with this ... 
			server {
				# SSL configuration
				listen 443 ssl http2 default_server;
				listen [::]:443 ssl http2 default_server;
				include snippets/ssl-digitalocean.hellyer.kiwi.conf;
				include snippets/ssl-params.conf;

# Allow Nginx HTTPS through the firewall
sudo ufw allow 'Nginx Full'
			# sudo ufw delete allow 'Nginx HTTP' # I think this causes problems with Varnish later

# Reboot Nginx
sudo service nginx restart

# Check if https working by visiting https://digitalocean.hellyer.kiwi/ (not http as that'll get redirected later)

# Auto renew Lets Encrypt
sudo letsencrypt renew
sudo crontab -e # Select "2"
		# Add these lines to the crontab
		30 2 * * 1 /usr/bin/letsencrypt renew >> /var/log/le-renew.log
		35 2 * * 1 /bin/systemctl reload nginx

== https://www.digitalocean.com/community/tutorials/how-to-configure-varnish-cache-4-0-with-ssl-termination-on-ubuntu-14-04

# Install Varnish
sudo apt-get install apt-transport-https # Should already be installed anyway, but just in case ...
curl https://repo.varnish-cache.org/ubuntu/GPG-key.txt | sudo apt-key add -
sudo sh -c 'echo "deb https://repo.varnish-cache.org/ubuntu/ trusty varnish-4.0" >> /etc/apt/sources.list.d/varnish-cache.list'
sudo apt-get update
sudo apt-get install varnish # Select default "Y"

sudo nano /etc/default/varnish # Change the port and manually set config file location
		DAEMON_OPTS="-a :80 \
		-f /etc/varnish/user.vcl \


sudo cp /etc/varnish/default.vcl /etc/varnish/user.vcl
sudo nano /etc/varnish/user.vcl # Note that many tutorials online for this do not work due to not being for Varnish 4
		sub vcl_backend_response {
			set beresp.ttl = 10s;
			set beresp.grace = 1h;
		}

		sub vcl_recv {

			# Redirect http to https
			if ( (req.http.host ~ "^(?i)london1.hellyer.kiwi") && req.http.X-Forwarded-Proto !~ "(?i)https") {
				return (synth(750, ""));
			}

		}

		sub vcl_synth {

			# Redirect http to https
			if (resp.status == 750) {
				set resp.status = 301;
				set resp.http.Location = "https://london1.hellyer.kiwi" + req.url;
				return(deliver);
			}
		}

sudo nano /etc/nginx/site-enabled/default
		# Add to main server block
        location / {
            proxy_pass http://127.0.0.1:80;
            proxy_set_header X-Real-IP  $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto https;
            proxy_set_header X-Forwarded-Port 443;
            proxy_set_header Host $host;
        }

        # Add as second server block
		server {
		        listen 127.0.0.1:8080;

		        root /var/www/html/;
		        index index.html;

		        location / {
		               try_files $uri $uri/ =404;
		        }

		}


sudo service nginx restart
sudo mkdir /etc/systemd/system/varnish.service.d/
sudo nano /etc/systemd/system/varnish.service.d/customexec.conf
		[Service]
		Type=forking
		ExecStart=
		ExecStart=/usr/sbin/varnishd -a :80 -T localhost:6082 -f /etc/varnish/user.vcl -S /etc/varnish/secret -s malloc,256m
sudo systemctl daemon-reload
sudo service varnish restart









# Setup automatic security updates
sudo apt-get install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
#Follow prompt to enable automatic security upgrades.



# Install MariaDB
sudo apt-get install mariadb-server

# Set MariaDB root password
sudo mysql -u root
[mysql] use mysql;
[mysql] update user set plugin='' where User='root'; # Forcing password usage
[mysql] flush privileges;
[mysql] SET PASSWORD FOR 'root'@'localhost' = PASSWORD('MyNewRootPassword');
[mysql] exit;

# Check password works
mysql -u root -pMyNewRootPassword

# Create new database and add new user to it
[mysql]CREATE DATABASE wordpress;
[mysql]GRANT ALL PRIVILEGES ON wordpress.* To 'ryan'@'localhost' IDENTIFIED BY 'MyNewPassword';
[mysql] exit;

# Check new user can log in
mysql -u ryan -pMyNewPassword
[mysql] exit;




# Install PHP 7
sudo apt-get install php-fpm php-mysql # Select default "Y"

sudo nano /etc/php/7.0/fpm/php.ini
		#Set this to 0. Needed for security reasons.
		cgi.fix_pathinfo=0

sudo nano /etc/nginx/sites-enabled/default
		# Change Varnish server block to this: - note this should probably be done earlier to simplify install
		server {
		        listen 127.0.0.1:8080;

		        root /var/www/html/;
		        index index.php;

		        location / {
		               try_files $uri $uri/ =404;
		        }

		    location ~ \.php$ {
		        include snippets/fastcgi-php.conf;
		        fastcgi_pass unix:/run/php/php7.0-fpm.sock;
		    }

		}





sudo nano /etc/nginx/nginx.conf # Copied from WordPress.org
		# Generic startup file.
		user www-data www-data;

		#usually equal to number of CPUs you have. run command "grep processor /proc/cpuinfo | wc -l" to find it
		worker_processes  2;

		error_log  /var/log/nginx/error.log;
		pid        /var/run/nginx.pid;

		# Keeps the logs free of messages about not being able to bind().
		#daemon     off;

		events {
			worker_connections  1024;
		}

		http {
		#	rewrite_log on;

			include mime.types;
			default_type       application/octet-stream;
			access_log         /var/log/nginx/access.log;
			sendfile           on;
		#	tcp_nopush         on;
			keepalive_timeout  3;
		#	tcp_nodelay        on;
		#	gzip               on;
		        #php max upload limit cannot be larger than this       
			client_max_body_size 13m;
			index              index.php index.html index.htm;

			# Upstream to abstract backend connection(s) for PHP.
			upstream php {
		                #this should match value of "listen" directive in php-fpm pool
				server unix:/tmp/php-fpm.sock;
		#		server 127.0.0.1:9000;
			}

			include sites-enabled/*;
		}

sudo mkdir /etc/nginx/global/
sudo nano /etc/nginx/global/restrictions.conf
		# Global restrictions configuration file.
		# Designed to be included in any server {} block.
		location = /favicon.ico {
			log_not_found off;
			access_log off;
		}

		location = /robots.txt {
			allow all;
			log_not_found off;
			access_log off;
		}

		# Deny all attempts to access hidden files such as .htaccess, .htpasswd, .DS_Store (Mac).
		# Keep logging the requests to parse later (or to pass to firewall utilities such as fail2ban)
		location ~ /\. {
			deny all;
		}

		# Deny access to any files with a .php extension in the uploads directory
		# Works in sub-directory installs and also in multisite network
		# Keep logging the requests to parse later (or to pass to firewall utilities such as fail2ban)
		location ~* /(?:uploads|files)/.*\.php$ {
			deny all;
		}
sudo nano /etc/nginx/global/wordpress.conf
		# WordPress single site rules.
		# Designed to be included in any server {} block.

		# This order might seem weird - this is attempted to match last if rules below fail.
		# http://wiki.nginx.org/HttpCoreModule
		location / {
			try_files $uri $uri/ /index.php?$args;
		}

		# Add trailing slash to */wp-admin requests.
		rewrite /wp-admin$ $scheme://$host$uri/ permanent;

		# Directives to send expires headers and turn off 404 error logging.
		location ~* ^.+\.(ogg|ogv|svg|svgz|eot|otf|woff|mp4|ttf|rss|atom|jpg|jpeg|gif|png|ico|zip|tgz|gz|rar|bz2|doc|xls|exe|ppt|tar|mid|midi|wav|bmp|rtf)$ {
		       access_log off; log_not_found off; expires max;
		}

		# Uncomment one of the lines below for the appropriate caching plugin (if used).
		#include global/wordpress-wp-super-cache.conf;
		#include global/wordpress-w3-total-cache.conf;

		# Pass all .php files onto a php-fpm/php-fcgi server.
		location ~ \.php$ {
			include snippets/fastcgi-php.conf;
			fastcgi_pass unix:/run/php/php7.0-fpm.sock;
		}

sudo nano /etc/nginx/sites-available/default # Replace everything with this ... 
		server {
			# SSL configuration
			listen 443 ssl http2;
			listen [::]:443 ssl http2;
			include snippets/ssl-london1.hellyer.kiwi.conf;
			include snippets/ssl-params.conf;

			index index.php;

			location ~ /.well-known {
				allow all;
			}

			server_name london1.hellyer.kiwi;


		        location / {
		            proxy_pass http://127.0.0.1:80;
		            proxy_set_header X-Real-IP  $remote_addr;
		            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		            proxy_set_header X-Forwarded-Proto https;
		            proxy_set_header X-Forwarded-Port 443;
		            proxy_set_header Host $host;
		        }

		}

		server {
		        listen 127.0.0.1:8080;

		        root /var/www/html/;
		        index index.php;

		        location / {
		               try_files $uri $uri/ =404;
		        }

			include global/restrictions.conf;
			include global/wordpress.conf;

		}


# Install WP CLI (it'd be nice to setup auto-updating in future)
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
php wp-cli.phar --info # Check it works
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp

cd /var/www/html/
wp core download
wp core config --dbname=wordpress --dbuser=ryan --dbpass=66536653 --dbhost=localhost --dbprefix=test3
# add to wp-config.php - needed so that WordPress knows we're using https and isn't confused by Varnish. Should probably be fixed in Varnish config
		if ( isset( $_SERVER['HTTP_X_FORWARDED_PROTO'] ) && $_SERVER['HTTP_X_FORWARDED_PROTO'] == 'https' ) {
		        $_SERVER['HTTPS']='on';
		}
wp core install --url=https://london1.hellyer.kiwi --title="Test Site" --admin_user=ryan --admin_password=66536653 --admin_email=ryanhellyer@gmail.com
wp rewrite structure '/%postname%/'

# Make Git work with 
ssh-keygen -t rsa -b 4096 -C "your_email@example.com" # Need

# Install Redis
sudo apt-get install redis-server redis-tools php-redis # Select default "Y"
