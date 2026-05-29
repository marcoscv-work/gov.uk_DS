#!/usr/bin/env bash
# GOV.UK Site Initializer — deploy to a remote Dockerized Liferay (PATH A / 7.4.13)
#
# Usage:
#   SSH_USER=root SSH_PASS=secret CONTAINER=liferay bash scripts/deploy.sh
#   # or run discovery first to find CONTAINER:
#   SSH_USER=root SSH_PASS=secret bash scripts/deploy.sh --list-containers
#
# Requires: sshpass, scp, ssh on this machine.
set -euo pipefail

HOST="${HOST:-192.168.0.199}"
SSH_USER="${SSH_USER:?set SSH_USER (the box's SSH login, not the Liferay admin)}"
SSH_PASS="${SSH_PASS:?set SSH_PASS}"
DEPLOY_DIR="${DEPLOY_DIR:-/opt/liferay/deploy}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
JAR="$ROOT/build-scripts/govuk-site-initializer/build/libs/com.govuk.site.initializer-1.0.0.jar"
ZIP="$ROOT/client-extensions/govuk-theme/dist/govuk-theme.zip"

ssh_() { sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=accept-new "$SSH_USER@$HOST" "$@"; }
scp_() { sshpass -p "$SSH_PASS" scp -o StrictHostKeyChecking=accept-new "$@"; }

if [[ "${1:-}" == "--list-containers" ]]; then
    echo "Containers on $HOST:"
    ssh_ 'docker ps --format "{{.Names}}\t{{.Image}}\t{{.Status}}"'
    exit 0
fi

CONTAINER="${CONTAINER:?set CONTAINER (run with --list-containers to find it)}"

[[ -f "$JAR" ]] || { echo "Missing JAR: $JAR"; exit 1; }
[[ -f "$ZIP" ]] || { echo "Missing theme zip: $ZIP"; exit 1; }

echo "==> Copying artifacts to $HOST:/tmp/"
scp_ "$JAR" "$ZIP" "$SSH_USER@$HOST:/tmp/"

echo "==> docker cp into $CONTAINER:$DEPLOY_DIR"
ssh_ "docker cp /tmp/com.govuk.site.initializer-1.0.0.jar $CONTAINER:$DEPLOY_DIR/ && \
      docker cp /tmp/govuk-theme.zip $CONTAINER:$DEPLOY_DIR/"

echo "==> Tailing logs (Ctrl-C to stop). Watch for:"
echo "      STARTED com.govuk.site.initializer_1.0.0"
echo "      STARTED ...govuk-theme..."
ssh_ "docker logs -f --tail 80 $CONTAINER"
