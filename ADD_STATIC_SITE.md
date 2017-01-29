# Create required folders

	sudo mkdir /var/www/storage.hellyer.kiwi
	sudo mkdir /var/www/storage.hellyer.kiwi/public_html
	sudo chown ryan:ryan /mnt/volume-fra1-02/stuff.hellyer.kiwi/* -R

Copy ssl-domain.conf
	sudo nano /etc/nginx/snippets/ssl-stuff.hellyer.kiwi.conf

Copy static-domain.conf - comment out 443 block temporarily and location block in 80 block
	sudo nano /etc/nginx/sites-available/storage.hellyer.kiwi.conf

	sudo ln -s /etc/nginx/sites-available/storage.hellyer.kiwi.conf /etc/nginx/sites-enabled/storage.hellyer.kiwi.conf

Lets Encrypt
	sudo letsencrypt certonly -a webroot --webroot-path=/mnt/volume-fra1-02/stuff.hellyer.kiwi/public_html/ -d stuff.hellyer.kiwi

Uncomment 443 block and location block in 80 block
	sudo nano /etc/nginx/sites-available/storage.hellyer.kiwi.conf
