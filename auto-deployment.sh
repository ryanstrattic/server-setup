#!/bin/sh
# Auto-deployment from Git
clear
cd /var/www/droplet3.hellyer.kiwi/public_html/
git pull origin master >> /dev/null 