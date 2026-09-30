#!/bin/sh
set -e
# The admin password lives in a Railway variable: (re)apply it on every boot so
# rotating it is "change the variable, redeploy". aioncore's `user set-password`
# is upstream's offline bootstrap path for self-hosted WebUI.
: "${AIONUI_ADMIN_PASSWORD:?set AIONUI_ADMIN_PASSWORD}"
printf '%s\n' "$AIONUI_ADMIN_PASSWORD" |
  /opt/aionui-web/bundled-aioncore/linux-x64/aioncore --data-dir "$AIONUI_DATA_DIR" user set-password --password-stdin
exec /opt/aionui-web/aionui-web start
