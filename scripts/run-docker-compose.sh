#!/usr/bin/env bash

set -e

RUN_TYPE=$1

function check_requirements() {
  throw_if_program_not_present "docker"

  throw_if_env_var_not_present "TIMEZONE" "$TIMEZONE"
  throw_if_env_var_not_present "PUID" "$PUID"
  throw_if_env_var_not_present "PGID" "$PGID"

  throw_if_env_var_not_present "DOCKER_BASE_DIRECTORY" "$DOCKER_BASE_DIRECTORY"
}

function setup_cloudflare_tunnel() {
  throw_if_env_var_not_present "CLOUDFLARE_BASE_DIRECTORY" "$CLOUDFLARE_BASE_DIRECTORY"

  ensure_directory_exists "$CLOUDFLARE_BASE_DIRECTORY/etc/cloudflared"

  throw_if_env_var_not_present "CLOUDFLARE_TUNNEL_TOKEN" "$CLOUDFLARE_TUNNEL_TOKEN"
}

function setup_nginx_proxy() {
  throw_if_env_var_not_present "NGNIX_PROXY_MANAGER_BASE_DIRECTORY" "$NGNIX_PROXY_MANAGER_BASE_DIRECTORY"

  ensure_directory_exists "$NGNIX_PROXY_MANAGER_BASE_DIRECTORY/data"
  ensure_directory_exists "$NGNIX_PROXY_MANAGER_BASE_DIRECTORY/letsencrypt"
}

function setup_jellyfin() {
  add_step "Setting up jellyfin"

  throw_if_env_var_not_present "MEDIA_BASE_DIRECTORY" "$MEDIA_BASE_DIRECTORY"
  throw_if_env_var_not_present "HOST_IP" "$HOST_IP"

  throw_if_env_var_not_present "JELLYFIN_BASE_DIRECTORY" "$JELLYFIN_BASE_DIRECTORY"
  ensure_directory_exists "$JELLYFIN_BASE_DIRECTORY/config"
  ensure_directory_exists "$JELLYFIN_BASE_DIRECTORY/plugins"
}

function setup_navidrome() {
  add_step "Setting up navidrome"

  throw_if_env_var_not_present "MUSIC_DIRECTORY" "$MUSIC_DIRECTORY"

  throw_if_env_var_not_present "NAVIDROME_BASE_DIRECTORY" "$NAVIDROME_BASE_DIRECTORY"
  ensure_directory_exists "$NAVIDROME_BASE_DIRECTORY/data"

  throw_if_env_var_not_present "BONOB_SECRET_KEY" "$BONOB_SECRET_KEY"
  throw_if_env_var_not_present "BONOB_SEED_HOST" "$BONOB_SEED_HOST"
}

function setup_calibre_web() {
  add_step "Setting up calibre-web"

  throw_if_env_var_not_present "CALIBRE_WEB_BASE_DIRECTORY" "$CALIBRE_WEB_BASE_DIRECTORY"

  ensure_directory_exists "$CALIBRE_WEB_BASE_DIRECTORY/config"
}

function setup_miniflux_web() {
  add_step "Setting up miniflux-web"

  throw_if_env_var_not_present "MINIFLUX_DB_USERNAME" "$MINIFLUX_DB_USERNAME"
  throw_if_env_var_not_present "MINIFLUX_DB_PASSWORD" "$MINIFLUX_DB_PASSWORD"
  throw_if_env_var_not_present "MINIFLUX_ADMIN_USERNAME" "$MINIFLUX_ADMIN_USERNAME"
  throw_if_env_var_not_present "MINIFLUX_ADMIN_PASSWORD" "$MINIFLUX_ADMIN_PASSWORD"

  throw_if_env_var_not_present "MINIFLUX_DB_BASE_DIRECTORY" "$MINIFLUX_DB_BASE_DIRECTORY"

  ensure_directory_exists "$MINIFLUX_DB_BASE_DIRECTORY"
}

function setup_code_server() {
  add_step "Setting up code-server"

  throw_if_env_var_not_present "CODE_SERVER_PASSWORD" "$CODE_SERVER_PASSWORD"
  throw_if_env_var_not_present "CODE_SERVER_SUDO_PASSWORD" "$CODE_SERVER_SUDO_PASSWORD"

  throw_if_env_var_not_present "CODE_SERVER_BASE_DIRECTORY" "$CODE_SERVER_BASE_DIRECTORY"
  ensure_directory_exists "$CODE_SERVER_BASE_DIRECTORY/config/workspace/tjmaynes"
}

function setup_gogs() {
  add_step "Setting up gogs"

  throw_if_env_var_not_present "GOGS_BASE_DIRECTORY" "$GOGS_BASE_DIRECTORY"
  ensure_directory_exists "$GOGS_BASE_DIRECTORY/data"

  throw_if_env_var_not_present "GOGS_DB_BASE_DIRECTORY" "$GOGS_DB_BASE_DIRECTORY"
  ensure_directory_exists "$GOGS_DB_BASE_DIRECTORY"
}

function setup_homer() {
  add_step "Setting up homer"

  throw_if_env_var_not_present "SERVICE_DOMAIN" "$SERVICE_DOMAIN"

  throw_if_env_var_not_present "HOMER_BASE_DIRECTORY" "$HOMER_BASE_DIRECTORY"

  ensure_directory_exists "$HOMER_BASE_DIRECTORY/www/assets"

  sed \
    -e "s/%protocol-type%/https/g" \
    -e "s/%service-domain%/${SERVICE_DOMAIN}/g" \
    data/homer.template.yml > "$HOMER_BASE_DIRECTORY/www/assets/config.yml"

  cp -f static/homer-logo.png "$HOMER_BASE_DIRECTORY/www/assets/logo.png"
}

function setup_audiobookshelf() {
  add_step "Setting up audiobookshelf"

  throw_if_env_var_not_present "AUDIOBOOKSHELF_BASE_DIRECTORY" "$AUDIOBOOKSHELF_BASE_DIRECTORY"

  ensure_directory_exists "$AUDIOBOOKSHELF_BASE_DIRECTORY/config"
  ensure_directory_exists "$AUDIOBOOKSHELF_BASE_DIRECTORY/metadata"
}

function setup_podgrab() {
  add_step "Setting up podgrab"

  throw_if_env_var_not_present "PODGRAB_BASE_DIRECTORY" "$PODGRAB_BASE_DIRECTORY"

  ensure_directory_exists "$PODGRAB_BASE_DIRECTORY/config"
}

function setup_bitwarden() {
  add_step "Setting up bitwarden"

  throw_if_env_var_not_present "BITWARDEN_BASE_DIRECTORY" "$BITWARDEN_BASE_DIRECTORY"

  ensure_directory_exists "$BITWARDEN_BASE_DIRECTORY/data"
}

function setup_home_assistant() {
  add_step "Setting up home assistant"

  throw_if_env_var_not_present "HOME_ASSISTANT_BASE_DIRECTORY" "$HOME_ASSISTANT_BASE_DIRECTORY"

  ensure_directory_exists "$HOME_ASSISTANT_BASE_DIRECTORY/config"
}

function setup_nodered() {
  add_step "Setting up nodered"

  throw_if_env_var_not_present "NODERED_BASE_DIRECTORY" "$NODERED_BASE_DIRECTORY"

  ensure_directory_exists "$NODERED_BASE_DIRECTORY/data"

  chmod 777 "$NODERED_BASE_DIRECTORY/data"
}

function setup_nfs_media_mount() {
  add_step "Setting up NFS mounts"

  throw_if_program_not_present "mount"

  throw_if_env_var_not_present "NAS_MEDIA_DIRECTORY" "$NAS_MEDIA_DIRECTORY"
  throw_if_env_var_not_present "MEDIA_BASE_DIRECTORY" "$MEDIA_BASE_DIRECTORY"

  setup_nas_mount "$NAS_MEDIA_DIRECTORY" "$MEDIA_BASE_DIRECTORY"

  throw_if_directory_not_present "VIDEOS_DIRECTORY" "$VIDEOS_DIRECTORY"
  throw_if_directory_not_present "MUSIC_DIRECTORY" "$MUSIC_DIRECTORY"
  throw_if_directory_not_present "PHOTOS_DIRECTORY" "$PHOTOS_DIRECTORY"
  throw_if_directory_not_present "BOOKS_DIRECTORY" "$BOOKS_DIRECTORY"
  throw_if_directory_not_present "AUDIOBOOKS_DIRECTORY" "$AUDIOBOOKS_DIRECTORY"
  throw_if_directory_not_present "PODCASTS_DIRECTORY" "$PODCASTS_DIRECTORY"
}

function turn_off_wifi() {
  ensure_program_installed "rfkill"

  rfkill block wifi
}

function turn_off_bluetooth() {
  ensure_program_installed "rfkill"

  rfkill block bluetooth
}

function turn_off_eee_mode() {
  ethtool --set-eee eth0 eee off
}

function main() {
  source ./scripts/common.sh

  check_requirements

  setup_nfs_media_mount

  setup_cloudflare_tunnel
  setup_nginx_proxy
  setup_homer
  setup_jellyfin
  setup_navidrome
  setup_calibre_web
  setup_miniflux_web
  setup_audiobookshelf
  setup_code_server
  setup_gogs
  setup_podgrab
  setup_bitwarden
  setup_home_assistant
  setup_nodered

  ./scripts/setup-monitoring.sh

  if [[ -z "$RUN_TYPE" ]]; then
    echo "Please pass an argument for 'RUN_TYPE'."
    exit 1
  fi

  if [[ "$RUN_TYPE" = "start" ]]; then
    docker compose up -d --remove-orphans
  else
    docker compose restart
  fi

  turn_off_wifi
  turn_off_bluetooth
  turn_off_eee_mode
}

main
