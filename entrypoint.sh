#!/bin/sh
set -e
# The admin password lives in a Railway variable: (re)apply it on every boot so
# rotating it is "change the variable, redeploy". aioncore's `user set-password`
# is upstream's offline bootstrap path for self-hosted WebUI.
: "${AIONUI_ADMIN_PASSWORD:?set AIONUI_ADMIN_PASSWORD}"
A=/opt/aionui-web/bundled-aioncore/linux-x64/aioncore
printf '%s\n' "$AIONUI_ADMIN_PASSWORD" | $A --data-dir "$AIONUI_DATA_DIR" user set-password --password-stdin

# set-password keeps existing sessions; disable+enable revokes them. Do that only
# when the password actually changed (salted hash on the volume), so a plain
# redeploy doesn't log everyone out.
STAMP="$AIONUI_DATA_DIR/.admin-password"
salt=$(cut -d: -f1 "$STAMP" 2>/dev/null || true)
[ -n "$salt" ] || salt=$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')
new="$salt:$(python3 -c 'import hashlib,os,sys; print(hashlib.pbkdf2_hmac("sha256", os.environ["AIONUI_ADMIN_PASSWORD"].encode(), bytes.fromhex(sys.argv[1]), 200000).hex())' "$salt")"
if [ "$new" != "$(cat "$STAMP" 2>/dev/null)" ]; then
  $A --data-dir "$AIONUI_DATA_DIR" user disable --username admin >/dev/null
  $A --data-dir "$AIONUI_DATA_DIR" user enable --username admin >/dev/null
  echo "$new" > "$STAMP"
  echo "admin password changed: existing sessions revoked"
fi
exec /opt/aionui-web/aionui-web start
