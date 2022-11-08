#!/usr/bin/env bash

set -e

function check_requirements() {
  throw_if_program_not_present "apt-get"

  throw_if_env_var_not_present "NONROOT_USER" "$NONROOT_USER"
}

function setup_start_geck_service() {
  if [[ ! -f "/etc/systemd/system/start-geck.service" ]]; then
    sudo tee -a /etc/systemd/system/start-geck.service <<EOF
[Unit]
Description=Start GECK
After=network.target

[Service]
WorkingDirectory=/home/$NONROOT_USER/workspace/tjmaynes/geck
ExecStart=sudo make restart

[Install]
WantedBy=default.target
EOF
  fi

  sudo systemctl enable start-geck
}

function setup_cronjobs() {
  throw_if_program_not_present "cron"

  BACKUP_CRONTAB="0 0-6/2 * * *  cd ~/workspace/tjmaynes/geck && sudo make backup"
  if ! crontab -l | grep "$BACKUP_CRONTAB"; then
    echo -e "Backups are not setup. Copy command and paste via 'crontab -e': $BACKUP_CRONTAB"
  fi

  CRON_LINE="#cron.*"
  if cat /etc/rsyslog.conf | grep "$CRON_LINE"; then
    echo -e "Cron logging is not configured. Uncomment 'cron' line in /etc/rsyslog.conf"
  fi
}

function setup_static_ip() {
  throw_if_env_var_not_present "HOST_IP" "$HOST_IP"

  IPV6_CONFIG="net.ipv6.conf.all.forwarding=1"
  if ! cat /etc/sysctl.conf | grep "$IPV6_CONFIG"; then
    echo "$IPV6_CONFIG" | sudo tee -a /etc/sysctl.conf
  fi

  if [[ -f "/etc/dhcpcd.conf" ]]; then
    rm -f "/etc/dhcpcd.conf"
  fi

  tee -a "/etc/dhcpcd.conf" <<EOF
hostname

clientid

persistant

option rapid_commit
option domain_name_servers, domain_name, domain_search, host_name
option classless_static_routes
option interface_mtu

require dhcp_server_identifier

slaac private

interface eth0
static ip_address=${HOST_IP}/24
static routers=${HOST_ROUTER_IP}
EOF
}

function install_docker() {
  if [[ -z "$(command -v docker)" ]]; then
    ./scripts/install-docker.sh
  fi

  usermod -aG docker "$NONROOT_USER"
}

function install_required_programs() {
  apt-get update && apt-get upgrade -y
  
  DEB_PACKAGES=(cron usermod curl lsof ffmpeg vim htop ethtool rfkill rsync)
  for package in "${DEB_PACKAGES[@]}"; do
    ensure_program_installed "$package"
  done

  if [[ -z "$(command -v nslookup)" ]]; then
    ensure_program_installed "dnsutils"
  fi

  install_docker
}

function setup_sysctl() {
  IPV4_CONFIG="net.ipv4.ip_forward=1"
  if ! cat /etc/sysctl.conf | grep "$IPV4_CONFIG"; then
    echo "$IPV4_CONFIG" | sudo tee -a /etc/sysctl.conf
  fi

  IPV6_CONFIG="net.ipv6.conf.all.forwarding=1"
  if ! cat /etc/sysctl.conf | grep "$IPV6_CONFIG"; then
    echo "$IPV6_CONFIG" | sudo tee -a /etc/sysctl.conf
  fi
}

function main() {
  source ./scripts/common.sh

  check_requirements

  install_required_programs

  setup_start_geck_service
  ./scripts/setup-monitoring.sh

  setup_sysctl
  setup_cronjobs
  setup_static_ip

  git config --global alias.co checkout
  git config --global alias.st status
  git config --global alias.gl "log --oneline --graph"

  reboot
}

main
