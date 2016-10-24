#!/bin/bash
clear
cd /mnt/volume-fra1-02/droplet6.hellyer.kiwi/public_html/
wp core update
wp core update-db
wp plugin update --all
wp theme update --all
#need to find some way to check wp core verify-checksums