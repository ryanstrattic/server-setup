#!/bin/bash
clear

WP_PATH="/mnt/volume-nyc1-01/wordpress.hellyer.kiwi/public_html"
for URL in = $(wp site list --fields=url --format=csv --path="$WP_PATH")
do

	if [[ $URL == "http"* ]]; then
		wp cron event run --all --due-now --url="$URL" --path="$WP_PATH"
	fi

done
