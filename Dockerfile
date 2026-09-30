# AionUi WebUI for Railway. The web build (upstream AionUi + build/remote-auth.patch)
# is made by build/release.sh and attached to this repo's GitHub releases, so a
# deploy only downloads it instead of building AionUi from source.
FROM debian:bookworm-slim
ARG AIONUI_VERSION=2.2.2
ARG AIONUI_SHA256=3d5f81c79e80136dc54fdd28349f76fb5788173e42606876adde3a3d848f711b
# libicu: officecli (Office previews) aborts without it. git/curl/python3: agent tools.
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates libicu72 git curl procps python3 \
  && curl -fsSL -o /tmp/aionui-web.tgz \
       "https://github.com/nomideusz/aionui-railway/releases/download/v${AIONUI_VERSION}/aionui-web-${AIONUI_VERSION}-railway-linux-x86_64.tar.gz" \
  && echo "${AIONUI_SHA256}  /tmp/aionui-web.tgz" | sha256sum -c - \
  && tar xzf /tmp/aionui-web.tgz -C /opt && rm /tmp/aionui-web.tgz \
  && rm -rf /var/lib/apt/lists/*
COPY entrypoint.sh /entrypoint.sh
ENV PORT=25808 AIONUI_ALLOW_REMOTE=true AIONUI_DATA_DIR=/data HOME=/data
EXPOSE 25808
ENTRYPOINT ["/entrypoint.sh"]
