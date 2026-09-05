###############################################################################
# Compile Broker
###############################################################################

FROM debian:bookworm-slim AS builder
ARG build_docs=false

# The OpenDXL Python client used by the embedded console. The PyPI release
# (5.6.0.x) pins msgpack<1.0 (vulnerable, GHSA-6v7p-g79w-8964) and does not
# start on current Python versions; override with a pip requirement
# specifier once a fixed release is published.
ARG DXL_CLIENT_PIP_SPEC="git+https://github.com/derjochenmueller/opendxl-client-python@epo-legacy"
# The OpenDXL console. The PyPI release (0.3.3) fails on Python 3 when
# started with the broker identifier and when generating provisioning
# packages; override with a pip requirement specifier (e.g. dxlconsole==x.y.z)
# once a fixed release is published.
ARG DXL_CONSOLE_PIP_SPEC="git+https://github.com/derjochenmueller/opendxl-console@master"

# Packages (OpenSSL, Boost)
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends libssl-dev libboost-dev cmake uuid-dev wget ca-certificates \
        build-essential git python3 python3-venv

# Message Pack
RUN cd /tmp \
    && wget https://github.com/msgpack/msgpack-c/releases/download/cpp-3.1.1/msgpack-3.1.1.tar.gz \
    && tar xvfz ./msgpack-3.1.1.tar.gz \
    && cd msgpack-3.1.1 \
    && cmake . \
    && make \
    && make install

# JsonCPP
RUN cd /tmp \
    && wget https://github.com/open-source-parsers/jsoncpp/archive/1.8.4.tar.gz \
    && tar xvfz 1.8.4.tar.gz \
    && cd jsoncpp-1.8.4 \
    && cmake -DCMAKE_BUILD_TYPE=release -DBUILD_STATIC_LIBS=ON -DBUILD_SHARED_LIBS=OFF \
        -DARCHIVE_INSTALL_DIR=/usr/local/lib -G "Unix Makefiles" \
    && make \
    && make install

# libwebsockets
RUN cd /tmp \
    && wget https://github.com/opendxl-community/libwebsockets/archive/v3.1-stable-opendxl-4.tar.gz \
    && tar xvzf v3.1-stable-opendxl-4.tar.gz \
    && cd libwebsockets-3.1-stable-opendxl-4 \
    && cmake -DCMAKE_BUILD_TYPE=release -DLWS_IPV6=On -DLWS_WITH_STATIC=ON \
        -DLWS_WITH_SHARED=OFF -DLWS_WITHOUT_TESTAPPS=ON -DCMAKE_C_FLAGS=-Wno-error -G "Unix Makefiles" \
    && make \
    && make install

# Build broker
COPY src /tmp/src
RUN cd /tmp/src && make

# Build the OpenDXL Python client and console wheels
RUN python3 -m venv /tmp/wheelenv \
    && /tmp/wheelenv/bin/pip install --no-cache-dir --upgrade pip wheel \
    && /tmp/wheelenv/bin/pip wheel --no-cache-dir --no-deps -w /tmp/wheels \
        "${DXL_CLIENT_PIP_SPEC}" "${DXL_CONSOLE_PIP_SPEC}"

# Generate documentation
COPY docs /tmp/docs
RUN mkdir /tmp/docs-output
RUN if [ "$build_docs" = "true" ]; then apt-get -y install --no-install-recommends flex bison doxygen \
    && cd /tmp/docs \
    && . /tmp/src/version \
    && sed -i "s,@PROJECT_NUMBER@,$SOMAJVER.$SOMINVER.$SOSUBMINVER.$SOBLDNUM,g" doxygen.config \
    && doxygen doxygen.config > /tmp/docs-output/build.log 2>&1 ; fi

###############################################################################
# Build Broker Image
###############################################################################

FROM debian:bookworm-slim

# Install packages
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends libssl3 openssl ca-certificates wget uuid-runtime \
        python3 python3-venv iproute2 procps adduser \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install the OpenDXL console and client wheels built above into a virtual
# environment
COPY --from=builder /tmp/wheels /tmp/wheels
RUN python3 -m venv /opt/dxlconsole \
    && /opt/dxlconsole/bin/pip install --no-cache-dir /tmp/wheels/*.whl \
    && rm -rf /tmp/wheels

COPY dxlbroker /dxlbroker
COPY LICENSE* /dxlbroker/
COPY --from=builder /tmp/src/mqtt-core/src/dxlbroker /dxlbroker/bin
COPY --from=builder /usr/local/lib/libmsgpackc.so.2.0.0 /dxlbroker/lib

# Documentation
COPY --from=builder /tmp/docs-output /dxlbroker/docs

# Create volume directory
RUN mkdir /dxlbroker-volume

# Add user
RUN adduser --home /dxlbroker --disabled-password --gecos "" dxl \
    && chown -R dxl:dxl /dxlbroker-volume \
    && chown -R dxl:dxl /dxlbroker

# Ensure script is executable
RUN chmod +x /dxlbroker/startup.sh
RUN chmod +x /dxlbroker/startup_as_root.sh

# Expose the volume
VOLUME ["/dxlbroker-volume"]

# Expose ports
EXPOSE 8883
EXPOSE 8443
EXPOSE 443

# Set user
#USER root

ENTRYPOINT ["/dxlbroker/startup_as_root.sh"]
