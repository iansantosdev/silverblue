FROM ghcr.io/blue-build/cli:latest-installer AS bluebuild

FROM fedora:44

RUN dnf install -y \
      dconf \
      flatpak \
      git \
      glib2 \
      shellcheck \
      systemd \
    && dnf clean all

COPY --from=bluebuild /out/bluebuild /usr/local/bin/bluebuild
