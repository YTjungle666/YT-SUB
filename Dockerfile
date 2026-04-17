# syntax=docker/dockerfile:1.7

ARG NODE_IMAGE=node:22.22.1-alpine3.22
ARG RUNTIME_IMAGE=node:22.22.1-alpine3.22
ARG PNPM_VERSION=9.15.9

FROM ${NODE_IMAGE} AS frontend-builder
ARG PNPM_VERSION
WORKDIR /src/frontend

COPY frontend/package.json frontend/pnpm-lock.yaml ./
RUN corepack enable \
    && corepack prepare pnpm@${PNPM_VERSION} --activate \
    && pnpm install --frozen-lockfile --reporter=silent

COPY frontend/ ./
RUN pnpm build

FROM ${NODE_IMAGE} AS backend-builder
ARG PNPM_VERSION
WORKDIR /src/backend

COPY backend/package.json backend/pnpm-lock.yaml ./
COPY backend/patches ./patches
RUN corepack enable \
    && corepack prepare pnpm@${PNPM_VERSION} --activate \
    && pnpm install --frozen-lockfile --reporter=silent

COPY backend/ ./
RUN pnpm test && pnpm bundle:esbuild

FROM ${RUNTIME_IMAGE} AS runtime
WORKDIR /app

LABEL org.opencontainers.image.title="YT-SUB" \
      org.opencontainers.image.description="Self-hosted Sub-Store with integrated same-origin frontend" \
      org.opencontainers.image.source="https://github.com/YTjungle666/YT-SUB" \
      org.opencontainers.image.licenses="GPL-3.0"

RUN apk add --no-cache ca-certificates libcap \
    && addgroup -S substore \
    && adduser -S -G substore -h /app substore \
    && mkdir -p /app/backend /app/frontend /app/data \
    && chown -R substore:substore /app/data

ENV NODE_ENV=production \
    SUB_STORE_DOCKER=true \
    SUB_STORE_DATA_BASE_PATH=/app/data \
    SUB_STORE_BACKEND_API_HOST=:: \
    SUB_STORE_BACKEND_API_PORT=80 \
    SUB_STORE_BACKEND_MERGE=true \
    SUB_STORE_FRONTEND_PATH=/app/frontend \
    SUB_STORE_FRONTEND_BACKEND_PATH=/

COPY LICENSE /app/LICENSE
COPY --from=frontend-builder /src/frontend/dist /app/frontend
COPY --from=backend-builder /src/backend/dist/sub-store.bundle.js /app/backend/sub-store.bundle.js
COPY --chmod=755 scripts/container-init.sh /app/sub-store

RUN ln -s /app/sub-store /usr/local/bin/container-init \
    && chmod 0755 /app/sub-store /app/backend/sub-store.bundle.js \
    && chown substore:substore /app/sub-store /app/backend/sub-store.bundle.js /app/LICENSE \
    && setcap cap_net_bind_service=+ep /usr/local/bin/node

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1/ping').then((res)=>process.exit(res.ok?0:1)).catch(()=>process.exit(1))"

USER substore:substore

CMD ["/usr/local/bin/container-init"]

FROM runtime AS ct-template
USER root
RUN apk add --no-cache iproute2 \
    && rm -f /sbin/init
COPY scripts/ct-entrypoint.sh /sbin/init
RUN chmod 0755 /sbin/init
