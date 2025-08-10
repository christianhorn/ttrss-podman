# Podmanized tt-rss


This is a podman version of tt-rss, 
[https://tt-rss.org/](https://tt-rss.org/) .
The setup uses the same images as the official tt-rss build which is
docker based.  This file is also based on the docker-deployment.

Original docs: 
[link](https://git.tt-rss.org/fox/ttrss-docker-compose.git/tree/README.md).

Outline of the configuration:

 - separate containers (frontend: nginx, database: pgsql, app and updater: php/fpm)
 - images are pulled from [Docker Hub](https://hub.docker.com/u/cthulhoo) 
 - updates are not yet tested (the docker-ttrss deployment supports these)
 - nginx has its http port exposed to the outside
 - feed updates are handled via update daemon started in a separate container (`updater`)
 - optional `backups` container which performs tt-rss database backup once a week

### Installation

To be executed as user:

```sh
git clone https://github.com/christianhorn/ttrss-podman
cd ttrss-podman
cp .env-dist .env
vi .env # details below
```

#### Edit configuration file

Configuration is done primarily through the .env file.  Copy ``.env-dist`` to ``.env`` and edit any relevant variables you need changed.

* Change ADMIN_USER_PASS to an initial admin user password.  To the bare minimum, you need to set this.
* Change ``TTRSS_SELF_URL_PATH`` to the fully qualified tt-rss
URL you will use in your web browser. If this field is set incorrectly, you will
likely see the correct value in the tt-rss fatal error message.  The default is http://localhost:8280/tt-rss, so plain text access from your local hypervisor.  That's appropriate for the default config with the frontend container binding to `localhost` port `8280`. If you want the container to be
accessible on the net, it's recommended to but i.e. an nginx in front.
* As root, modify /etc/hosts to contain this:
```sh
127.0.0.1       db app
```


#### Build and start the container

```sh
# build locally
podman build -t ttrss build-bookworm/

# run locally
podman run -p 127.0.0.1:8280:80 --name ttrss -d \
        --security-opt seccomp=unconfined --hostname ttrss \
        localhost/ttrss /lib/systemd/systemd

podman exec -it ttrss bash

sudo -u postgres psql
postgres=# CREATE USER "www-data" WITH PASSWORD 'windy4spot3seven';
postgres=# CREATE DATABASE ttrss WITH OWNER "www-data";
postgres=# \quit
exit

cd /var/www/html
git clone https://git.tt-rss.org/fox/tt-rss.git tt-rss
cd tt-rss
cp config.php-dist config.php
# vi config.php
# podman cp config.php ttrss:/config.php
echo '127.0.0.1 db' >>/etc/hosts
php ./update.php --update-schema
cd ..
chown -R www-data:www-data tt-rss

cd /etc/nginx/sites-available/
vi ttrss
# podman cp ttrss ttrss:/etc/nginx/sites-available/ttrss

systemctl enable --now php8.2-fpm
cd ../sites-enabled/
rm default
ln -s ../sites-available/ttrss .
service nginx restart

vi /etc/systemd/system/ttrss-updater.service
systemctl daemon-reload
systemctl enable --now ttrss-updater

# login with admin/password

# backups
/root/ttrss-backup.sh

```


#### Login credentials

Login at the URL, by default http://localhost:8280/tt-rss/, with user 'admin' and the password you did choose. Enter 'preferences', and create a further user which you then use for feeds.

### Updating

For now, I'm just reading up all items, exporting my feeds, recreating the containers and then importing the feeds again. This will mark all items in the feeds as 'unread'.
