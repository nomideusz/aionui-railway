# AionUi WebUI: the upstream web-cli tarball, built from a release tag
# (upstream doesn't publish the Linux web tarball as a release asset).
FROM node:22-bookworm AS build
ARG AIONUI_REF=v2.2.2
COPY --from=oven/bun:1 /usr/local/bin/bun /usr/local/bin/bun
RUN ln -s bun /usr/local/bin/bunx
WORKDIR /src
RUN git clone --depth 1 --branch "$AIONUI_REF" https://github.com/iOfficeAI/AionUi.git .
ENV ELECTRON_SKIP_BINARY_DOWNLOAD=1 BUN_INSTALL_REGISTRY=https://registry.npmjs.org/
RUN bun install --frozen-lockfile
RUN NODE_OPTIONS=--max-old-space-size=8192 bunx electron-vite build --config packages/desktop/electron.vite.config.ts
# Remote mode that actually authenticates: see remote-auth.patch.
COPY build/remote-auth.patch /tmp/
RUN git apply /tmp/remote-auth.patch && PACK_PLATFORM=linux PACK_ARCH=x64 node scripts/pack-web-cli.js

