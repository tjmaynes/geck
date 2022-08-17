#!/bin/bash

set -e

export BASE_DIRECTORY=$1
export REMOTE_SERVER_HOST=$2
export PLEX_CLAIM_TOKEN=$3

function check_requirements() {
  if [[ -z "$(command -v docker)" ]]; then
    echo "Please install 'docker' before running this script"
    exit 1
  fi
}

function ensure_directory_exists() {
  TARGET_DIRECTORY=$1

  if [[ ! -d "$TARGET_DIRECTORY" ]]; then
    echo "Creating $TARGET_DIRECTORY directory..."
    mkdir -p "$TARGET_DIRECTORY"
  fi
}

function set_environment_variables() {
  if [[ -z "$BASE_DIRECTORY" ]]; then
    echo "Please an environment variable for 'BASE_DIRECTORY' before running this script"
    exit 1
  elif [[ -z "$REMOTE_SERVER_HOST" ]]; then
    echo "Please an environment variable for 'REMOTE_SERVER_HOST' before running this script"
    exit 1
  elif [[ -z "$PLEX_CLAIM_TOKEN" ]]; then
    echo "Please an environment variable for 'PLEX_CLAIM_TOKEN' before running this script"
    exit 1
  fi

  export ENVIRONMENT=development
  export TIMEZONE=America/Chicago
  export PUID=$UID
  export PGID=$(sudo id -g)

  export ADMIN_PORTAL_PORT=5000

  export MEDIA_DIRECTORY=${BASE_DIRECTORY}/media

  export PHOTOS_DIRECTORY=${MEDIA_DIRECTORY}/Photos
  export BOOKS_DIRECTORY=${MEDIA_DIRECTORY}/Books
  export AUDIOBOOKS_DIRECTORY=${MEDIA_DIRECTORY}/Audiobooks
  export PODCASTS_DIRECTORY=${MEDIA_DIRECTORY}/Podcasts

  export PLEX_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/plex-server
  export PLEX_PORT=32400

  export CALIBRE_WEB_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/calibre-web
  export CALIBRE_WEB_PORT=8083

  export GOGS_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/gogs-web
  export GOGS_PORT=3000
  export GOGS_SSH_PORT=222
  export GOGS_USER=gogs
  export GOGS_DATABASE=gogs
  export GOGS_DATABASE_PASSWORD=gogs
  export GOGS_DATABASE_PORT=5433
  export GOGS_DATABASE_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/gogs-db

  export HOME_ASSISTANT_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/home-assistant-web
  export HOME_ASSISTANT_PORT=8123

  export HOMER_WEB_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/homer-web
  export HOMER_WEB_PORT=8080

  export TAILSCALE_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/tailscale-agent

  export AUDIOBOOKSHELF_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/audiobookshelf-web
  export AUDIOBOOKSHELF_PORT=13378

  export PODGRAB_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/podgrab-web
  export PODGRAB_PORT=8098

  export NODE_RED_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/node-red
  export NODE_RED_PORT=1880

  export PHOTOVIEW_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/photoview-server
  export PHOTOVIEW_PORT=9080

  export PHOTOVIEW_DB_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/photoview-db
  export PHOTOVIEW_DB_PORT=9081
  export PHOTOVIEW_DB_NAME=photoview
  export PHOTOVIEW_DB_USER=photoview
  export PHOTOVIEW_DB_PASSWORD=password

  export DRAWIO_PORT=9092
  export DRAWIO_HTTPS_PORT=9093

  export BITWARDEN_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/bitwarden-server
  export BITWARDEN_PORT=8084
  export BITWARDEN_HTTPS_PORT=8085

  export PHOTOUPLOADER_BASE_DIRECTORY=${BASE_DIRECTORY}/docker/photouploader-server
  export PHOTOUPLOADER_PORT=9003
}

function main() {
  check_requirements
  
  set_environment_variables

  ensure_directory_exists "$PLEX_BASE_DIRECTORY/config"
  ensure_directory_exists "$PLEX_BASE_DIRECTORY/transcode"
  ensure_directory_exists "$CALIBRE_WEB_BASE_DIRECTORY/config"
  ensure_directory_exists "$GOGS_BASE_DIRECTORY/data"
  ensure_directory_exists "$GOGS_DATABASE_BASE_DIRECTORY"
  ensure_directory_exists "$HOME_ASSISTANT_BASE_DIRECTORY/config"
  ensure_directory_exists "$HOMER_WEB_BASE_DIRECTORY/www/assets"
  ensure_directory_exists "$TAILSCALE_BASE_DIRECTORY/var/lib"
  ensure_directory_exists "$AUDIOBOOKSHELF_BASE_DIRECTORY/config"
  ensure_directory_exists "$AUDIOBOOKSHELF_BASE_DIRECTORY/metadata"
  ensure_directory_exists "$PODGRAB_BASE_DIRECTORY/config"
  ensure_directory_exists "$PHOTOVIEW_BASE_DIRECTORY/cache"
  ensure_directory_exists "$PHOTOVIEW_DB_BASE_DIRECTORY"
  ensure_directory_exists "$BITWARDEN_BASE_DIRECTORY/data"
  ensure_directory_exists "$PRIVATEBIN_BASE_DIRECTORY/data"
  ensure_directory_exists "$FRESHRSS_BASE_DIRECTORY/config"
  
  ensure_directory_exists "$PHOTOUPLOADER_BASE_DIRECTORY/config"
  ensure_directory_exists "$PHOTOUPLOADER_BASE_DIRECTORY/database"
  touch "$PHOTOUPLOADER_BASE_DIRECTORY/database/filebrowser.db"

  ensure_directory_exists "$NODE_RED_BASE_DIRECTORY/data"
  sudo chmod 777 "$NODE_RED_BASE_DIRECTORY/data"

  ENCODED_REMOTE_SERVER_HOST="https:\/\/${REMOTE_SERVER_HOST}"
  
  LOCAL_SERVER_HOST="$(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')"
  ENCODED_LOCAL_SERVER_HOST="http:\/\/${LOCAL_SERVER_HOST}"

  sed \
     -e "s/%remote-server-host%:%plex-port%/${ENCODED_REMOTE_SERVER_HOST}:${PLEX_PORT}/g" \
     -e "s/%local-server-host%:%plex-port%/${ENCODED_LOCAL_SERVER_HOST}:${PLEX_PORT}/g" \
     -e "s/%remote-server-host%:%calibre-web-port%/${ENCODED_REMOTE_SERVER_HOST}:${CALIBRE_WEB_PORT}/g" \
     -e "s/%local-server-host%:%calibre-web-port%/${ENCODED_LOCAL_SERVER_HOST}:${CALIBRE_WEB_PORT}/g" \
     -e "s/%remote-server-host%:%home-assistant-port%/${ENCODED_REMOTE_SERVER_HOST}:${HOME_ASSISTANT_PORT}/g" \
     -e "s/%local-server-host%:%home-assistant-port%/${ENCODED_LOCAL_SERVER_HOST}:${HOME_ASSISTANT_PORT}/g" \
     -e "s/%remote-server-host%:%gogs-port%/${ENCODED_REMOTE_SERVER_HOST}:${GOGS_PORT}/g" \
     -e "s/%local-server-host%:%gogs-port%/${ENCODED_LOCAL_SERVER_HOST}:${GOGS_PORT}/g" \
     -e "s/%remote-server-host%:%audiobookshelf-web-port%/${ENCODED_REMOTE_SERVER_HOST}:${AUDIOBOOKSHELF_PORT}/g" \
     -e "s/%local-server-host%:%audiobookshelf-web-port%/${ENCODED_LOCAL_SERVER_HOST}:${AUDIOBOOKSHELF_PORT}/g" \
     -e "s/%remote-server-host%:%node-red-port%/${ENCODED_REMOTE_SERVER_HOST}:${NODE_RED_PORT}/g" \
     -e "s/%local-server-host%:%node-red-port%/${ENCODED_LOCAL_SERVER_HOST}:${NODE_RED_PORT}/g" \
     -e "s/%remote-server-host%:%photoview-port%/${ENCODED_REMOTE_SERVER_HOST}:${PHOTOVIEW_PORT}/g" \
     -e "s/%local-server-host%:%photoview-port%/${ENCODED_LOCAL_SERVER_HOST}:${PHOTOVIEW_PORT}/g" \
     -e "s/%remote-server-host%:%drawio-port%/${ENCODED_REMOTE_SERVER_HOST}:${DRAWIO_PORT}/g" \
     -e "s/%local-server-host%:%drawio-port%/${ENCODED_LOCAL_SERVER_HOST}:${DRAWIO_PORT}/g" \
     -e "s/%remote-server-host%:%bitwarden-port%/${ENCODED_REMOTE_SERVER_HOST}:${BITWARDEN_PORT}/g" \
     -e "s/%local-server-host%:%bitwarden-port%/${ENCODED_LOCAL_SERVER_HOST}:${BITWARDEN_PORT}/g" \
     -e "s/%remote-server-host%:%photouploader-port%/${ENCODED_REMOTE_SERVER_HOST}:${PHOTOUPLOADER_PORT}/g" \
     -e "s/%local-server-host%:%photouploader-port%/${ENCODED_LOCAL_SERVER_HOST}:${PHOTOUPLOADER_PORT}/g" \
     -e "s/%remote-server-host%:%admin-portal-port%/${ENCODED_REMOTE_SERVER_HOST}:${ADMIN_PORTAL_PORT}/g" \
     -e "s/%local-server-host%:%admin-portal-port%/${ENCODED_LOCAL_SERVER_HOST}:${ADMIN_PORTAL_PORT}/g" \
     -e "s/%remote-server-host%:%podgrab-port%/${ENCODED_REMOTE_SERVER_HOST}:${PODGRAB_PORT}/g" \
     -e "s/%local-server-host%:%podgrab-port%/${ENCODED_LOCAL_SERVER_HOST}:${PODGRAB_PORT}/g" \
    data/homer.yml > "$HOMER_WEB_BASE_DIRECTORY/www/assets/config.yml"

  cp -f static/homer-logo.png "$HOMER_WEB_BASE_DIRECTORY/www/assets/logo.png"

  cp -f data/photo-uploader.json "$PHOTOUPLOADER_BASE_DIRECTORY/config/settings.json"

  sudo -E docker-compose up -d --remove-orphans

  sudo docker exec tailscale-agent tailscale up --advertise-routes=192.168.4.0/24
}

main
