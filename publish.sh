#!/usr/bin/env bash

set -euo pipefail

LOCAL_DIR="./publish/"
REMOTE_USER="Administrator"
REMOTE_HOST="192.168.1.237"
REMOTE_DIR="/c/Users/Administrator/Documents/IIS/Web2024"
APP_POOL="Web2024"

SSH_OPTS="-T -p 22 -o LogLevel=ERROR"

section() {
  printf "\n\033[1m==> %s\033[0m\n" "$1"
}

success() {
  printf "\033[32m✔ %s\033[0m\n" "$1"
}

run() {
  local message="$1"
  shift

  section "$message"

  "$@"

  success "$message completed"
}

# run "Publishing application" \
#   dotnet publish WEB2024/WEB2024/WEB2024.csproj \
#     -c Release \
#     -o "$LOCAL_DIR"

run "Stopping IIS app pool" \
  ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" \
  "powershell \"
    if ((Get-WebAppPoolState -Name '$APP_POOL').Value -eq 'Started') {
      Stop-WebAppPool -Name '$APP_POOL'
      Write-Host 'App pool stopped'
    }
    else {
      Write-Host 'App pool already stopped'
    }
  \""

run "Syncing files to remote server" \
  rsync --blocking-io -rtvl --delete \
    --exclude='*Development.json' \
    --exclude='wwwroot/images' \
    --exclude='caidatsettings.json' \
    --exclude='logs/' \
    --exclude='uploads/' \
    -e "ssh $SSH_OPTS" \
    "$LOCAL_DIR" \
    "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}"

run "Starting IIS app pool" \
  ssh $SSH_OPTS "$REMOTE_USER@$REMOTE_HOST" \
  "powershell \"Start-WebAppPool -Name '$APP_POOL'\""

printf "\n\033[1;32mDEPLOYMENT COMPLETED SUCCESSFULLY!\033[0m\n"
