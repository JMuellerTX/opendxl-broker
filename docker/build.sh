#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DOCKERFILE_TEMPLATE="$DIR/Dockerfile.template"
DEB_SLIM_DOCKERFILE="$DIR/../Dockerfile"
RH_UBI_DOCKERFILE="$DIR/redhat-ubi/Dockerfile"
ALMA_DOCKERFILE="$DIR/almalinux/Dockerfile"

#
# Function that is invoked when the script fails.
#
# $1 - The message to display prior to exiting.
#
function fail() {
    echo $1
    echo "Exiting."
    exit 1
}

#
# Debian bookworm-slim
#
yes | cp -f $DOCKERFILE_TEMPLATE $DEB_SLIM_DOCKERFILE \
    || { fail 'Error copying template (deb bookworm slim).'; }
sed -i "s,@BUILDER_IMAGE@,debian:bookworm-slim,g" $DEB_SLIM_DOCKERFILE \
    || { fail 'Error setting builder image (deb bookworm slim).'; }
INSTALL_BUILDER_PACKAGES='apt-get update -y \\\n'\
'    \&\& apt-get install -y --no-install-recommends libssl-dev libboost-dev cmake uuid-dev wget ca-certificates \\\n'\
'        build-essential git patch perl zlib1g-dev python3 python3-venv'
sed -i "s,@INSTALL_BUILDER_PACKAGES@,$INSTALL_BUILDER_PACKAGES,g" $DEB_SLIM_DOCKERFILE \
    || { fail 'Error setting builder packages (deb bookworm slim).'; }
sed -i "s,@BROKER_IMAGE@,debian:bookworm-slim,g" $DEB_SLIM_DOCKERFILE \
    || { fail 'Error setting broker image (deb bookworm slim).'; }
INSTALL_BROKER_PACKAGES='apt-get update -y \\\n'\
'    \&\& apt-get install -y --no-install-recommends libssl3 openssl ca-certificates wget uuid-runtime \\\n'\
'        python3 python3-venv iproute2 procps adduser \\\n'\
'    \&\& apt-get clean \\\n'\
'    \&\& rm -rf /var/lib/apt/lists/*'
sed -i "s,@INSTALL_BROKER_PACKAGES@,$INSTALL_BROKER_PACKAGES,g" $DEB_SLIM_DOCKERFILE \
    || { fail 'Error setting broker packages (deb bookworm slim).'; }
sed -i "s,@ADD_USER@,adduser --home /dxlbroker --disabled-password --gecos \"\" dxl,g" $DEB_SLIM_DOCKERFILE \
    || { fail 'Error setting add user (deb bookworm slim).'; }
sed -i "s,@INSTALL_DOC_PACKAGES@,apt-get -y install --no-install-recommends flex bison doxygen,g" $DEB_SLIM_DOCKERFILE \
    || { fail 'Error setting doc packages (deb bookworm slim).'; }

#
# RedHat UBI 9
#
yes | cp -f $DOCKERFILE_TEMPLATE $RH_UBI_DOCKERFILE \
    || { fail 'Error copying template (RedHat UBI).'; }
sed -i "s,@BUILDER_IMAGE@,quay.io/centos/centos:stream9,g" $RH_UBI_DOCKERFILE \
    || { fail 'Error setting builder image (RedHat UBI).'; }
INSTALL_BUILDER_PACKAGES='dnf group install -y "Development Tools" \\\n'\
'    \&\& dnf install -y openssl-devel boost-devel cmake libuuid-devel wget git python3 python3-pip'
sed -i "s,@INSTALL_BUILDER_PACKAGES@,$INSTALL_BUILDER_PACKAGES,g" $RH_UBI_DOCKERFILE \
    || { fail 'Error setting builder packages (RedHat UBI).'; }
sed -i "s,@BROKER_IMAGE@,registry.access.redhat.com/ubi9/ubi-minimal:latest,g" $RH_UBI_DOCKERFILE \
    || { fail 'Error setting broker image (RedHat UBI).'; }
INSTALL_BROKER_PACKAGES='microdnf install -y shadow-utils util-linux wget python3 openssl ca-certificates procps-ng uuid libuuid iproute \\\n'\
'    \&\& microdnf clean all'
sed -i "s,@INSTALL_BROKER_PACKAGES@,$INSTALL_BROKER_PACKAGES,g" $RH_UBI_DOCKERFILE \
    || { fail 'Error setting broker packages (RedHat UBI).'; }
sed -i "s,@ADD_USER@,useradd -d /dxlbroker -c \"\" dxl,g" $RH_UBI_DOCKERFILE \
    || { fail 'Error setting add user (RedHat UBI).'; }
INSTALL_DOC_PACKAGES='dnf install -y '"'dnf-command(config-manager)'"' \\\n'\
'    \&\& dnf config-manager --set-enabled crb \\\n'\
'    \&\& dnf -y install flex bison doxygen'
sed -i "s,@INSTALL_DOC_PACKAGES@,$INSTALL_DOC_PACKAGES,g" $RH_UBI_DOCKERFILE \
    || { fail 'Error setting doc packages (RedHat UBI).'; }

#
# AlmaLinux 10
#
# The primary base. AlmaLinux is the direction Trellix appliances are taking, so a
# test broker built on it matches the platform the fabric will actually run on. It
# also ships OpenSSL 3.5 - the same LTS line as the ePO 5.10 SP1 management service
# - which makes "what the distribution gives us" a meaningful test configuration
# rather than an arbitrary one.
#
mkdir -p "$DIR/almalinux" || { fail 'Error creating almalinux directory.'; }
yes | cp -f $DOCKERFILE_TEMPLATE $ALMA_DOCKERFILE \
    || { fail 'Error copying template (AlmaLinux).'; }
sed -i "s,@BUILDER_IMAGE@,almalinux:10,g" $ALMA_DOCKERFILE \
    || { fail 'Error setting builder image (AlmaLinux).'; }
INSTALL_BUILDER_PACKAGES='dnf install -y '"'"'dnf-command(config-manager)'"'"' \\\n'\
'    \&\& dnf config-manager --set-enabled crb \\\n'\
'    \&\& dnf group install -y "Development Tools" \\\n'\
'    \&\& dnf install -y openssl-devel boost-devel cmake libuuid-devel wget git patch \\\n'\
'        perl-core zlib-devel python3 python3-pip'
sed -i "s,@INSTALL_BUILDER_PACKAGES@,$INSTALL_BUILDER_PACKAGES,g" $ALMA_DOCKERFILE \
    || { fail 'Error setting builder packages (AlmaLinux).'; }
sed -i "s,@BROKER_IMAGE@,almalinux:10-minimal,g" $ALMA_DOCKERFILE \
    || { fail 'Error setting broker image (AlmaLinux).'; }
INSTALL_BROKER_PACKAGES='microdnf install -y shadow-utils util-linux wget python3 openssl \\\n'\
'        ca-certificates procps-ng libuuid iproute \\\n'\
'    \&\& microdnf clean all'
sed -i "s,@INSTALL_BROKER_PACKAGES@,$INSTALL_BROKER_PACKAGES,g" $ALMA_DOCKERFILE \
    || { fail 'Error setting broker packages (AlmaLinux).'; }
sed -i "s,@ADD_USER@,useradd -d /dxlbroker -c \"\" dxl,g" $ALMA_DOCKERFILE \
    || { fail 'Error setting add user (AlmaLinux).'; }
INSTALL_DOC_PACKAGES='dnf install -y flex bison doxygen'
sed -i "s,@INSTALL_DOC_PACKAGES@,$INSTALL_DOC_PACKAGES,g" $ALMA_DOCKERFILE \
    || { fail 'Error setting doc packages (AlmaLinux).'; }
