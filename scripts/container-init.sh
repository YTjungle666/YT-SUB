#!/bin/sh
set -u

: "${NODE_ENV:=production}"
: "${SUB_STORE_DOCKER:=true}"
: "${SUB_STORE_DATA_BASE_PATH:=/app/data}"
: "${SUB_STORE_BACKEND_API_HOST:=::}"
: "${SUB_STORE_BACKEND_API_PORT:=80}"
: "${SUB_STORE_BACKEND_MERGE:=true}"
: "${SUB_STORE_FRONTEND_PATH:=/app/frontend}"
: "${SUB_STORE_FRONTEND_BACKEND_PATH:=/}"

export NODE_ENV
export SUB_STORE_DOCKER
export SUB_STORE_DATA_BASE_PATH
export SUB_STORE_BACKEND_API_HOST
export SUB_STORE_BACKEND_API_PORT
export SUB_STORE_BACKEND_MERGE
export SUB_STORE_FRONTEND_PATH
export SUB_STORE_FRONTEND_BACKEND_PATH

if [ "$#" -eq 0 ]; then
  set -- /usr/local/bin/node /app/backend/sub-store.bundle.js
fi

exec "$@"
