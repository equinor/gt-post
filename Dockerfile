ARG PIXI_ENV=prod

FROM ubuntu:22.04 AS builder

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates && \
    curl -fsSL https://pixi.sh/install.sh | PIXI_VERSION=v0.67.2 bash && \
    mv /root/.pixi/bin/pixi /usr/local/bin/pixi && \
    rm -rf /var/lib/apt/lists/*

COPY . /app
WORKDIR /app
ENV CONDA_OVERRIDE_GLIBC=2.17
# Runtime-only environment: excludes the dev/docs/training/gpu features
ARG PIXI_ENV
ENV PIXI_ENV=${PIXI_ENV}
RUN pixi install --locked -e "${PIXI_ENV}" \
    && pixi shell-hook -e "${PIXI_ENV}" > /shell-hook

FROM ubuntu:22.04 AS runtime

ARG PIXI_ENV
ENV PIXI_ENV=${PIXI_ENV} \
    CONDA_OVERRIDE_GLIBC=2.17 \
    LD_LIBRARY_PATH=/app/.pixi/envs/${PIXI_ENV}/lib \
    MPLBACKEND=Agg

RUN apt-get update \
    && apt-get install -y --no-install-recommends adduser ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && addgroup --gid 1001 radix-non-root-group \
    && adduser --disabled-password --gecos "" --uid 1001 --gid 1001 radix-non-root-user \
    && mkdir -p /app/.pixi/envs \
    && chown 1001:1001 /app /app/.pixi /app/.pixi/envs

ENV HOME=/home/radix-non-root-user
WORKDIR /app
COPY --from=builder /shell-hook /shell-hook
COPY --from=builder --chown=1001:1001 /app/.pixi/envs/${PIXI_ENV} /app/.pixi/envs/${PIXI_ENV}
COPY --chown=1001:1001 pyproject.toml pixi.lock README.md LICENSE /app/
COPY --chown=1001:1001 gtpost/ /app/gtpost/
COPY --chown=1001:1001 scripts/ /app/scripts/
COPY --chown=1001:1001 config/ /app/config/
COPY --chown=1001:1001 gt_templates/ /app/gt_templates/
COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

USER 1001

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
