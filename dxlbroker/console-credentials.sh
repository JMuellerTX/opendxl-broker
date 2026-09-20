#!/bin/sh
#
# Print the console's credentials for this container.
#
# The console on 8443 gets a password generated on first start unless one was
# supplied through DXL_CONSOLE_PASSWORD. It is printed once, at that first start,
# and kept in the volume so a restart does not invalidate it - this is how to read
# it back afterwards without going through `docker logs`, which may have rotated,
# been shipped elsewhere, or been discarded entirely.
#
#     docker exec <container> /dxlbroker/console-credentials.sh
#     user=admin
#     password=shFUsjZMuqNTDeQlpcCoHr4f
#
#     PW=$(docker exec <container> /dxlbroker/console-credentials.sh --password)
#     python -m dxlclient provisionconfig ./config 127.0.0.1 client -u admin -p "$PW" --insecure
#
# In a script, prefer supplying the password instead: `-e DXL_CONSOLE_PASSWORD=...`
# on `docker run` needs no read-back at all, and keeps the value out of the
# container's log.
#
# Exits 1 when there are no credentials to print, which means either that the
# console is switched off (DXL_CONSOLE_ENABLED=false) or that the container has
# not finished its first start.
#

set -u

CRED_FILE=/dxlbroker-volume/config/console/console-credentials

if [ ! -r "$CRED_FILE" ]; then
    echo "No console credentials in this container." >&2
    echo "The console is either switched off (DXL_CONSOLE_ENABLED=false) or still starting." >&2
    exit 1
fi

user=$(sed -n 's/^user=//p' "$CRED_FILE" | head -1)
password=$(sed -n 's/^password=//p' "$CRED_FILE" | head -1)

case "${1:-}" in
    --password) printf '%s\n' "$password" ;;
    --user)     printf '%s\n' "$user" ;;
    '')         printf 'user=%s\npassword=%s\n' "$user" "$password" ;;
    *)          echo "Usage: $0 [--user|--password]" >&2; exit 2 ;;
esac
