#!/bin/sh
# ===========================================================================
# Calibre-Web for TerraMaster TOS 7 - non-root entrypoint
# ===========================================================================
# The upstream linuxserver image starts s6-overlay as root, then drops to its
# internal "abc" user. TOS forbids root containers, and s6 cannot switch users
# from a container that already runs as uid 1000 ("s6-applyuidgid: unable to
# set supplementary group list"), so this wrapper bypasses s6 and starts the
# unmodified Calibre-Web code directly.
#
# Everything Calibre-Web writes is redirected into the mounted /config volume:
#   CALIBRE_DBPATH  -> app.db, gdrive.db, .key
#   CACHE_DIRECTORY -> generated cover/thumbnail cache
#   HOME            -> per-user files some Python libraries expect
# The log goes to stdout so `docker logs calibrewebdocker` shows it.
#
# MAINTAINERS: this file is embedded into docker-compose.yml by
# scripts/build.sh, which indents it and escapes every dollar sign (docker
# compose interpolates $VAR/${VAR} in compose files). Edit THIS file only.
# ===========================================================================
set -u

log() { printf '[calibre-web] %s\n' "$*"; }

CONFIG_DIR=/config
CACHE_DIR=/config/cache
LIBRARY_DIR=/books

# The installer chowns the bind-mount sources to the application user. Create
# the cache directory here so Calibre-Web never tries to write below /app
# (which is root-owned and intentionally read-only for this container).
mkdir -p "$CACHE_DIR" 2>/dev/null || true

if [ ! -w "$CONFIG_DIR" ]; then
    log "WARNING: $CONFIG_DIR is not writable by uid $(id -u); settings will not persist"
fi
if [ ! -d "$LIBRARY_DIR" ]; then
    log "WARNING: $LIBRARY_DIR is missing; the Calibre library cannot be opened"
fi

export CALIBRE_DBPATH="$CONFIG_DIR"
export CACHE_DIRECTORY="$CACHE_DIR"
export HOME="$CONFIG_DIR"

cd /app/calibre-web || exit 1

log "starting Calibre-Web as uid $(id -u), gid $(id -g)"
exec python3 /app/calibre-web/cps.py -o /dev/stdout
