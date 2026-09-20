[![Actions Status](https://github.com/opendxl/opendxl-broker/workflows/Build/badge.svg)](https://github.com/opendxl/opendxl-broker/actions)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Docker Build Status](https://img.shields.io/docker/cloud/build/opendxl/opendxl-broker.svg)](https://hub.docker.com/r/opendxl/opendxl-broker/)


# OpenDXL Broker

## Overview


The OpenDXL Broker is an open source version of a [Data Exchange Layer](http://www.mcafee.com/us/solutions/data-exchange-layer.aspx) (DXL) broker. The broker executes in a standalone mode and does not require an external management interface. The only currently supported packaged delivery mechanism for the OpenDXL Broker is a [Docker](https://www.docker.com/) image. 

The OpenDXL Broker Docker image is available at the following location within [Docker Hub](https://hub.docker.com):

[https://hub.docker.com/r/opendxl/opendxl-broker/](https://hub.docker.com/r/opendxl/opendxl-broker/)

## This fork

The image on Docker Hub was last built in 2021 on Debian stretch with OpenSSL 1.0.2.
Every cipher suite it offers uses RSA key transport, so a current Python, JDK or
Node.js refuses the handshake with it out of the box. This fork rebuilds it on current
bases against **OpenSSL 4.0.2**, with forward secrecy, TLS 1.3 and a Python 3 console:

```bash
docker pull ghcr.io/jmuellertx/opendxl-broker:debian      # or :almalinux
```

### Runtime settings

All of them are read on **every** start, so recreating the container against the same
volume is enough to change one.

| Variable | Default | Effect |
|---|---|---|
| `DXL_TLS_MODE` | `modern` | Cipher profile: `modern`, `legacy`, `pfs-only`, `trellix-6.1`. It also fixes the protocol ceiling, which a cipher list cannot: `legacy` and `trellix-6.1` pin TLS 1.2, because the brokers they imitate cannot do 1.3. |
| `DXL_TLS_CIPHERS` | — | An explicit OpenSSL cipher string instead of a profile. |
| `DXL_TLS_VERSION` | from the profile | `tlsv1.2` or `tlsv1.3` to pin both listeners; empty negotiates the highest both ends support. |
| `DXL_CONSOLE_PASSWORD` | *generated* | See below. `random` forces a new one. |
| `DXL_CONSOLE_USER` | `admin` | Console user. |
| `DXL_CONSOLE_ENABLED` | `true` | `false` does not start the console at all. |
| `DXL_SEND_CONNECT_EVENTS` | `false` | Publish client connect/disconnect events, with TLS version, cipher and certificate thumbprint. |

### Credentials

MQTT on 8883 and WebSockets on 443 have **no credentials and need none**: both require a
client certificate, so the fabric is held by mutual TLS. The console on 8443 is the
exception and the one that matters, because it holds the client CA and signs
certificates - whoever reaches it can mint an identity for the fabric.

**This image has no default console password.** One is generated on first start, kept in
the volume so a restart does not invalidate it, and printed once:

```
  Console credentials: admin / htBWHXymBDZ2y75K6GQ27AQC
  ^ generated for this volume and shown only here. Read it back later with:
      docker exec <container> /dxlbroker/console-credentials.sh
```

A script should supply one instead - then nothing is generated, and the value never
reaches the container log:

```bash
docker run -d --name dxlbroker -p 8883:8883 -p 127.0.0.1:8443:8443 -p 8444:443 \
  -e DXL_CONSOLE_PASSWORD="$(openssl rand -hex 16)" ghcr.io/jmuellertx/opendxl-broker:debian
```

With `DXL_CONSOLE_ENABLED=false` the container has no credentials at all; nothing can be
provisioned against it, so bring certificates issued earlier.

### Testing against all four profiles at once

```bash
DXL_CONSOLE_PASSWORD=$(openssl rand -hex 16) \
  docker compose -f docker-compose.test.yml up -d --wait
```

Four brokers on `127.0.0.1`, one per TLS profile, each with its own volume and CA.
`--wait` blocks until every one reports healthy.

Full documentation of the fork: the [opendxl-docs repository](https://github.com/JMuellerTX/opendxl-docs), broker pages under docs/broker/.

## Documentation

See the [Wiki](https://github.com/opendxl/opendxl-broker/wiki) for installation, configuration, and usage instructions for the OpenDXL Broker.

## Bugs and Feedback

For bugs, questions and discussions please use the [GitHub Issues](https://github.com/opendxl/opendxl-broker/issues).

## LICENSE

Copyright 2018 McAfee, LLC

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

