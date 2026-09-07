#!/bin/sh
#
# Readiness probe for the broker container.
#
# The question a test harness actually has is "will a DXL client get a usable TLS
# connection right now?" - not "is the process alive". The listener accepts
# connections several seconds after the process starts, and a cipher list with no
# overlap leaves a running process that negotiates nothing.
#
# The probe deliberately does NOT complete a full handshake. The broker requires a
# client certificate, so anything without one is rejected with a handshake_failure
# after the server certificate has been sent. Receiving that certificate is the
# useful signal, and it is sufficient:
#
#   - connection refused          -> listener not up
#   - no server certificate       -> no shared cipher suite (misconfiguration)
#   - server certificate received -> listener up, cipher negotiated, TLS working
#
# Verified against a running broker: a healthy one presents its certificate, and
# the same broker probed with a deliberately non-overlapping cipher list presents
# nothing.
#
# Exits 0 when ready, 1 otherwise. Used by the image's HEALTHCHECK and usable
# directly:
#
#     docker exec <container> /dxlbroker/healthcheck.sh
#
# DXL_HEALTHCHECK_PORT overrides the port (default: the configured listenPort,
# falling back to 8883).
#

set -u

CONFIG_FILE=/dxlbroker-volume/dxlbroker.conf
OPENSSL=/opt/openssl/bin/openssl
[ -x "$OPENSSL" ] || OPENSSL=openssl

port="${DXL_HEALTHCHECK_PORT:-}"
if [ -z "$port" ] && [ -r "$CONFIG_FILE" ]; then
    port=$(sed -n 's/^listenPort=\([0-9]*\).*/\1/p' "$CONFIG_FILE" | head -1)
fi
[ -n "$port" ] || port=8883

out=$("$OPENSSL" s_client -connect "127.0.0.1:${port}" </dev/null 2>&1)

if ! echo "$out" | grep -q "BEGIN CERTIFICATE"; then
    if echo "$out" | grep -qi "Connection refused"; then
        echo "broker not ready: nothing listening on port ${port}"
    else
        echo "broker not ready: no server certificate on port ${port}" \
             "(no shared cipher suite?)"
    fi
    echo "$out" | grep -iE "error|alert|refused" | head -2
    exit 1
fi

subject=$(echo "$out" | sed -n 's/^subject=//p' | head -1)
cipher=$(echo "$out" | sed -n 's/^ *Cipher *: *//p' | head -1)
# TLS 1.3 sessions report the suite on the "New, TLSv1.3, Cipher is ..." line
# instead of in the session block.
[ -n "$cipher" ] || cipher=$(echo "$out" | sed -n 's/^New, .*Cipher is //p' | head -1)
proto=$(echo "$out" | sed -n 's/^ *Protocol *: *//p' | head -1)

echo "broker ready on port ${port}: ${proto:-?} ${cipher:-?} ${subject:-}"
exit 0
