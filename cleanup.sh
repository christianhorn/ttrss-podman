#!/usr/bin/bash

set -x

podman stop rss-nginx rss-updater rss-backups rss-app rss-db
podman rm rss-nginx rss-updater rss-backups rss-app rss-db
podman rmi rss-nginx rss-updater rss-backups rss-app rss-db

# remove the pod
podman pod rm ttrss

# remove the podman-pause image
podman rmi $(podman images|grep podman-pause|awk '{print $3}')

sudo rm -rf configs/* .env
