BASEDIR="$(pwd)/configs"
mkdir -p $BASEDIR/db $BASEDIR/app $BASEDIR/config.d \
	$BASEDIR/backups $BASEDIR/config.d
. .env

# build locally
podman build -t rss-db rss-db/
podman build -t rss-app rss-app/
podman build -t rss-backups rss-backups/
podman build -t rss-updater rss-updater/
podman build -t rss-nginx rss-nginx/

# run locally
podman run --name rss-db -d \
	--security-opt seccomp=unconfined \
	-p ${HTTP_PORT}:80 \
	--pod new:ttrss \
	-e POSTGRES_USER=${TTRSS_DB_USER} \
    -e POSTGRES_PASSWORD=${TTRSS_DB_PASS} \
    -e POSTGRES_DB=${TTRSS_DB_NAME} \
	-v $BASEDIR/db:/var/lib/postgresql/data:Z \
	rss-db

podman run --name rss-app -d \
	--security-opt seccomp=unconfined \
	--pod ttrss \
	--env-file=.env \
	-v $BASEDIR/app:/var/www/html:Z \
	-v $BASEDIR/config.d:/opt/tt-rss/config.d:ro,Z \
	rss-app

podman run --name rss-backups -d \
	--security-opt seccomp=unconfined \
	--pod ttrss \
	--env-file=.env \
	-v $BASEDIR/backups:/backups:Z \
	-v $BASEDIR/app:/var/www/html:Z \
	rss-backups

podman run --name rss-updater -d \
	--security-opt seccomp=unconfined \
	--pod ttrss \
	--env-file=.env \
	-v $BASEDIR/app:/var/www/html:Z \
	-v $BASEDIR/config.d:/opt/tt-rss/config.d:ro,Z \
	rss-updater

podman run --name rss-nginx -d \
	--security-opt seccomp=unconfined \
	--pod ttrss \
	-v $BASEDIR/app:/var/www/html:ro,Z \
	rss-nginx
