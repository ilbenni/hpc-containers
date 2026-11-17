# Blender (binario ufficiale blender.org) per rendering headless su cluster HPC.
# Cycles CPU/CUDA/OptiX; per le GPU NVIDIA usare `apptainer ... --nv` (driver dall'host).

FROM debian:trixie-slim AS build
ARG VERSION
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl xz-utils \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /tmp/dl
RUN set -eux; \
    SERIES="${VERSION%.*}"; \
    BASE="https://download.blender.org/release/Blender${SERIES}"; \
    TARBALL="blender-${VERSION}-linux-x64.tar.xz"; \
    curl -fsSLO "${BASE}/${TARBALL}"; \
    curl -fsSL "${BASE}/blender-${VERSION}.sha256" | grep " ${TARBALL}\$" > SHA256SUMS; \
    sha256sum -c SHA256SUMS; \
    mkdir -p /opt/blender; \
    tar -xJf "${TARBALL}" --strip-components=1 -C /opt/blender

FROM debian:trixie-slim
ARG VERSION
LABEL org.opencontainers.image.title="blender" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.description="Blender ${VERSION} (binario ufficiale) per rendering headless" \
      org.opencontainers.image.licenses="GPL-2.0-or-later"
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libxi6 libxrender1 libxxf86vm1 libxfixes3 libxkbcommon0 \
      libsm6 libice6 libx11-6 libgl1 libegl1 libglx0 \
 && rm -rf /var/lib/apt/lists/*
COPY --from=build /opt/blender /opt/blender
RUN ln -s /opt/blender/blender /usr/local/bin/blender
ENTRYPOINT ["blender"]
