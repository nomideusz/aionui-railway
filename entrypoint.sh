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

# Agent CLIs for AionUi to detect on $PATH. They live on the volume and are
# updated on every boot, because a copy baked into the image would go stale.
# Short names map to npm packages, and anything else is used as an npm package name.
# AIONUI_AGENTS=none installs none.
AGENTS_DIR="$AIONUI_DATA_DIR/agents"
pkgs=""
for a in $(echo "${AIONUI_AGENTS-claude,codex,gemini,opencode}" | tr ',' ' '); do
  case "$a" in
    claude) pkgs="$pkgs @anthropic-ai/claude-code" ;;
    codex) pkgs="$pkgs @openai/codex" ;;
    gemini) pkgs="$pkgs @google/gemini-cli" ;;
    opencode) pkgs="$pkgs opencode-ai" ;;
    qwen) pkgs="$pkgs @qwen-code/qwen-code" ;;
    none) ;;
    *) pkgs="$pkgs $a" ;;
  esac
done
# A changed list starts from scratch, so agents that were removed from it disappear.
[ "$pkgs" = "$(cat "$AGENTS_DIR/.list" 2>/dev/null)" ] || rm -rf "$AGENTS_DIR"
if [ -n "$pkgs" ]; then
  echo "installing/updating agent CLIs:$pkgs"
  # A failed update keeps the old CLIs, and a failed first install retries on the next boot.
  # The npm cache goes to /tmp, so it doesn't keep ~750 MB on the volume.
  if timeout 240 npm install -g --prefix "$AGENTS_DIR" --cache /tmp/npm-cache --no-fund --no-audit --no-update-notifier --loglevel=error \
       $(for p in $pkgs; do echo "$p@latest"; done); then
    echo "$pkgs" > "$AGENTS_DIR/.list"
  else
    echo "agent CLI install failed, starting with what is there"
  fi
  rm -rf /tmp/npm-cache
  # The install leaves ~2 GB of page cache, which Railway counts as the service's memory,
  # and the container can't drop caches, so evict the CLIs' files from it one by one.
  python3 - "$AGENTS_DIR" <<'EOF'
import os, sys
os.sync()
for d, _, fs in os.walk(sys.argv[1]):
    for f in fs:
        try: fd = os.open(os.path.join(d, f), os.O_RDONLY | os.O_NOFOLLOW)
        except OSError: continue
        os.posix_fadvise(fd, 0, 0, os.POSIX_FADV_DONTNEED); os.close(fd)
EOF
fi

# Codex's bubblewrap sandbox can't create namespaces inside a container, so each
# sandboxed command fails and is retried with a second approval. The container is
# the sandbox: default Codex to full access unless its config sets a mode. The line
# goes first, because top-level TOML keys must come before any [table].
C="$HOME/.codex/config.toml"
if ! grep -qs '^sandbox_mode' "$C"; then
  mkdir -p "${C%/*}"
  { echo 'sandbox_mode = "danger-full-access"'; cat "$C" 2>/dev/null || true; } > "$C.tmp" && mv "$C.tmp" "$C"
fi
exec /opt/aionui-web/aionui-web start
