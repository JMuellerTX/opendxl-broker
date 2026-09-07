#!/bin/bash

DXLBROKER_DIR=/dxlbroker
DXLBROKER_APP=/dxlbroker/bin/dxlbroker
DXLBROKER_CONFIG_DIR=$DXLBROKER_DIR/config
DXLBROKER_CONFIG_FILE=$DXLBROKER_CONFIG_DIR/dxlbroker.conf.tmpl
DXLBROKER_POLICY_DIR=$DXLBROKER_DIR/policy
DXLBROKER_GENERAL_POLICY_FILE=$DXLBROKER_POLICY_DIR/general.policy
DXLBROKER_BROKER_STATE_POLICY_FILE=$DXLBROKER_POLICY_DIR/brokerstate.policy
DXLBROKER_TOPIC_AUTH_POLICY_FILE=$DXLBROKER_POLICY_DIR/topicauth.policy
DXLBROKER_LIB_DIR=$DXLBROKER_DIR/lib
DXLBROKER_CONSOLE_DIR=$DXLBROKER_DIR/console
DXLBROKER_CONSOLE_CONFIG_DIR=$DXLBROKER_CONSOLE_DIR/config
DXLBROKER_CONSOLE_CONFIG_FILE=$DXLBROKER_CONSOLE_CONFIG_DIR/dxlconsole.config
DXLBROKER_CONSOLE_LOGGING_FILE=$DXLBROKER_CONSOLE_CONFIG_DIR/logging.config
DXLBROKER_CONSOLE_CLIENT_CONFIG_FILE=$DXLBROKER_CONSOLE_CONFIG_DIR/dxlclient.config
DXLBROKER_CONSOLE_CLIENT_CONFIG_TMPL_FILE=$DXLBROKER_CONSOLE_CONFIG_DIR/dxlclient.config.tmpl

MSGPACK_LIB=$DXLBROKER_LIB_DIR/libmsgpackc.so.2.0.0
MSGPACK_LIB_SYMLINK1=$DXLBROKER_LIB_DIR/libmsgpackc.so.2
MSGPACK_LIB_SYMLINK2=$DXLBROKER_LIB_DIR/libmsgpackc.so

DVOL=/dxlbroker-volume
DVOL_CONFIG_DIR=$DVOL/config
DVOL_CONFIG_FILE=$DVOL_CONFIG_DIR/dxlbroker.conf
DVOL_POLICY_DIR=$DVOL/policy
DVOL_GENERAL_POLICY_FILE=$DVOL_POLICY_DIR/general.policy
DVOL_BROKER_STATE_POLICY_FILE=$DVOL_POLICY_DIR/brokerstate.policy
DVOL_TOPIC_AUTH_POLICY_FILE=$DVOL_POLICY_DIR/topicauth.policy
DVOL_CONFIG_DEFAULTS_FILE=$DVOL_CONFIG_DIR/dxlbroker.conf.defaults
DVOL_CONSOLE_CONFIG_DIR=$DVOL/config/console
DVOL_CONSOLE_CONFIG_FILE=$DVOL_CONSOLE_CONFIG_DIR/dxlconsole.config
DVOL_CONSOLE_LOGGING_FILE=$DVOL_CONSOLE_CONFIG_DIR/logging.config
DVOL_CONSOLE_CLIENT_CONFIG_FILE=$DVOL_CONSOLE_CONFIG_DIR/dxlclient.config
DVOL_CONSOLE_CLIENT_CONFIG_TMPL_FILE=$DVOL_CONSOLE_CONFIG_DIR/dxlclient.config.tmpl
DVOL_POLICY_DIR=$DVOL/policy
DVOL_KEYSTORE_DIR=$DVOL/keystore
DVOL_LOGS_DIR=$DVOL/logs
DVOL_CLIENT_CA_CERT_FILE=$DVOL_KEYSTORE_DIR/ca-client.crt
DVOL_CLIENT_CA_KEY_FILE=$DVOL_KEYSTORE_DIR/ca-client.key
DVOL_BROKER_CA_CERT_FILE=$DVOL_KEYSTORE_DIR/ca-broker.crt
DVOL_BROKER_CA_KEY_FILE=$DVOL_KEYSTORE_DIR/ca-broker.key
DVOL_BROKER_CA_CSR_FILE=$DVOL_KEYSTORE_DIR/ca-broker.csr
DVOL_BROKER_CAS_LIST_FILE=$DVOL_KEYSTORE_DIR/ca-brokers.lst
DVOL_BROKER_CERT_FILE=$DVOL_KEYSTORE_DIR/broker.crt
DVOL_BROKER_KEY_FILE=$DVOL_KEYSTORE_DIR/broker.key
DVOL_BROKER_CSR_FILE=$DVOL_KEYSTORE_DIR/broker.csr
DVOL_BROKER_V3_EXT_FILE=$DVOL_KEYSTORE_DIR/v3.ext
REQUIRED_CA_FILES=($DVOL_CLIENT_CA_CERT_FILE $DVOL_BROKER_CA_CERT_FILE $DVOL_BROKER_CERT_FILE $DVOL_BROKER_KEY_FILE)

CERT_PASS=OpenDxlBroker
CERT_DAYS=3650

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
# Link libraries
#

if [ ! -f $MSGPACK_LIB_SYMLINK1 ]; then
    ln -s $MSGPACK_LIB $MSGPACK_LIB_SYMLINK1 || { fail 'Error creating message pack symbolic link (1).'; }
fi
if [ ! -f $MSGPACK_LIB_SYMLINK2 ]; then
    ln -s $MSGPACK_LIB $MSGPACK_LIB_SYMLINK2 || { fail 'Error creating message pack symbolic link (2).'; }
fi

#
# Create directories
#

if [ ! -d $DVOL_CONFIG_DIR ]; then
    echo "Creating config directory..."
    mkdir -p $DVOL_CONFIG_DIR || { fail 'Error creating config directory.'; }
fi
if [ ! -d $DVOL_CONSOLE_CONFIG_DIR ]; then
    echo "Creating console config directory..."
    mkdir -p $DVOL_CONSOLE_CONFIG_DIR || { fail 'Error creating console config directory.'; }
fi
if [ ! -d $DVOL_POLICY_DIR ]; then
    echo "Creating policy directory..."
    mkdir -p $DVOL_POLICY_DIR || { fail 'Error creating policy directory.'; }
fi
if [ ! -d DVOL_KEYSTORE_DIR ]; then
    echo "Creating keystore directory..."
    mkdir -p $DVOL_KEYSTORE_DIR || { fail 'Error creating keystore directory.'; }
fi
if [ ! -d DVOL_LOGS_DIR ]; then
    echo "Creating logs directory..."
    mkdir -p $DVOL_LOGS_DIR || { fail 'Error creating logs directory.'; }
fi

#
# Console configuration files
#
if [ ! -f $DVOL_CONSOLE_CONFIG_FILE ]; then
    cp $DXLBROKER_CONSOLE_CONFIG_FILE $DVOL_CONSOLE_CONFIG_FILE \
        || { fail 'Error copying console configuration file.'; }
    sed -i "s,@CLIENT_CA_CERT_FILE@,$DVOL_CLIENT_CA_CERT_FILE,g" $DVOL_CONSOLE_CONFIG_FILE \
        || { fail 'Error setting CA certificate file in console configuration file.'; }
    sed -i "s,@CLIENT_CA_KEY_FILE@,$DVOL_CLIENT_CA_KEY_FILE,g" $DVOL_CONSOLE_CONFIG_FILE \
        || { fail 'Error setting CA key file in console configuration file.'; }
    sed -i "s,@BROKER_CA_BUNDLE_FILE@,$DVOL_BROKER_CA_CERT_FILE,g" $DVOL_CONSOLE_CONFIG_FILE \
        || { fail 'Error setting broker CA bundle file in console configuration file.'; }
    sed -i "s,@CLIENT_CA_PASSWORD@,$CERT_PASS,g" $DVOL_CONSOLE_CONFIG_FILE \
        || { fail 'Error setting client CA password in console configuration file.'; }
    sed -i "s,@CLIENT_CONFIG_TMPL_FILE@,$DVOL_CONSOLE_CLIENT_CONFIG_TMPL_FILE,g" $DVOL_CONSOLE_CONFIG_FILE \
        || { fail 'Error setting client configuration template file in console configuration file.'; }
    sed -i "s,@BROKER_STATE_POLICY_FILE@,$DVOL_BROKER_STATE_POLICY_FILE,g" $DVOL_CONSOLE_CONFIG_FILE \
        || { fail 'Error setting broker state policy file in console configuration file.'; }
fi
if [ ! -f $DVOL_CONSOLE_CLIENT_CONFIG_FILE ]; then
    cp $DXLBROKER_CONSOLE_CLIENT_CONFIG_FILE $DVOL_CONSOLE_CLIENT_CONFIG_FILE \
        || { fail 'Error copying console client configuration file.'; }
fi
if [ ! -f DVOL_CONSOLE_LOGGING_FILE ]; then
    cp $DXLBROKER_CONSOLE_LOGGING_FILE $DVOL_CONSOLE_LOGGING_FILE \
        || { fail 'Error copying console logging configuration file.'; }
fi
if [ ! -f $DVOL_CONSOLE_CLIENT_CONFIG_TMPL_FILE ]; then
    cp $DXLBROKER_CONSOLE_CLIENT_CONFIG_TMPL_FILE $DVOL_CONSOLE_CLIENT_CONFIG_TMPL_FILE \
        || { fail 'Error copying console client configuration template file.'; }
fi

#
# Create policy files
#
if [ ! -f $DVOL_GENERAL_POLICY_FILE ]; then
    cp $DXLBROKER_GENERAL_POLICY_FILE $DVOL_GENERAL_POLICY_FILE \
        || { fail 'Error copying general policy file.'; }
fi
if [ ! -f $DVOL_BROKER_STATE_POLICY_FILE ]; then
    cp $DXLBROKER_BROKER_STATE_POLICY_FILE $DVOL_BROKER_STATE_POLICY_FILE \
        || { fail 'Error copying broker state policy file.'; }
fi
if [ ! -f $DVOL_TOPIC_AUTH_POLICY_FILE ]; then
    cp $DXLBROKER_TOPIC_AUTH_POLICY_FILE $DVOL_TOPIC_AUTH_POLICY_FILE \
        || { fail 'Error copying topic authorization policy file.'; }
fi

#
# Create broker configuration file
#

if [ ! -f $DVOL_CONFIG_DEFAULTS_FILE ]; then
    echo "No broker defaults configuration file found, creating one..."
    cp $DXLBROKER_CONFIG_FILE $DVOL_CONFIG_DEFAULTS_FILE || { fail 'Copy failed.'; }

    echo "  Setting broker identifier..."
    BROKERID=$(uuidgen) || { fail 'Broker identifier generation failed.'; }
    sed -i "s/@DXLBROKER_ID@/$BROKERID/g" $DVOL_CONFIG_DEFAULTS_FILE \
        || { fail 'Error setting broker identifier in config file.'; }

    echo "  Updating configuration paths..."
    sed -i "s,@DXLBROKER_POLICYDIR@,$DVOL_POLICY_DIR,g" $DVOL_CONFIG_DEFAULTS_FILE \
        || { fail 'Error setting policy directory in config file.'; }
    sed -i "s,@DXLBROKER_KEYSTOREDIR@,$DVOL_KEYSTORE_DIR,g" $DVOL_CONFIG_DEFAULTS_FILE \
        || { fail 'Error setting keystore directory in config file.'; }
    sed -i "s,@DXLBROKER_LOGDIR@,$DVOL_LOGS_DIR,g" $DVOL_CONFIG_DEFAULTS_FILE \
        || { fail 'Error setting logs directory in config file.'; }
fi

#
# TLS cipher configuration (applied on every start, environment driven)
#
# DXL_TLS_MODE selects a predefined cipher list for the MQTT listener:
#   modern   - forward-secrecy suites first, AES128-SHA256 (RSA key transport)
#              as fallback: behaves like Trellix DXL Broker >= 6.1.1 (default)
#   legacy   - RSA key transport only (AES128-SHA256 and friends): behaves
#              like DXL brokers before 6.1.1 (no forward secrecy)
#   pfs-only - ECDHE/DHE suites only (FIPS 140-3 oriented profile)
#   trellix-6.1 - the exact 12 suites a Trellix DXL Broker 6.1.3.55 offers,
#              measured against a live fabric: four ECDHE (secp256r1) plus
#              eight RSA key transport, and no DHE. Use this to test against
#              what production actually presents rather than a superset of it;
#              "modern" additionally offers DHE, so it is a compatibility
#              target, not a faithful mock.
# DXL_TLS_CIPHERS overrides the list with an explicit OpenSSL cipher string.
# A user-provided ciphers= line in dxlbroker.conf still takes precedence
# over the defaults file edited here.
#
case "${DXL_TLS_MODE:-modern}" in
    modern)   TLS_MODE_CIPHERS="ECDHE+AESGCM:ECDHE+AES:DHE+AES:AES128-SHA256:!aNULL:!eNULL:!MD5:!3DES" ;;
    legacy)   TLS_MODE_CIPHERS="AES128-SHA256:AES256-SHA256:AES128-GCM-SHA256:AES256-GCM-SHA384:!aNULL:!eNULL" ;;
    pfs-only) TLS_MODE_CIPHERS="ECDHE+AESGCM:ECDHE+AES:DHE+AES:!aNULL:!eNULL:!MD5:!3DES" ;;
    trellix-6.1) TLS_MODE_CIPHERS="ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:AES256-GCM-SHA384:AES128-GCM-SHA256:CAMELLIA256-SHA:CAMELLIA128-SHA:AES256-SHA256:AES256-SHA:AES128-SHA256:AES128-SHA" ;;
    *) fail "Unknown DXL_TLS_MODE '$DXL_TLS_MODE' (expected modern, legacy, pfs-only or trellix-6.1)." ;;
esac
TLS_CIPHERS="${DXL_TLS_CIPHERS:-$TLS_MODE_CIPHERS}"
echo "  TLS cipher mode: ${DXL_TLS_MODE:-modern} (${TLS_CIPHERS})"
sed -i "s|^ciphers=.*|ciphers=${TLS_CIPHERS}|" $DVOL_CONFIG_DEFAULTS_FILE     || { fail 'Error setting cipher list in config file.'; }

#
# Client connect/disconnect events (applied on every start, environment driven)
#
# DXL_SEND_CONNECT_EVENTS=true makes the broker publish
# /mcafee/event/dxl/clientregistry/connect and /disconnect for every client
# (broker setting sendConnectEvents). The connect event of this fork carries
# tlsVersion, cipher, certThumbprint, remoteAddress and protocol in addition
# to clientGuid - the input a monitoring sensor needs. Off by default, like
# upstream and like a Trellix DXL broker (measured: neither sends them).
#
SEND_CONNECT_EVENTS="${DXL_SEND_CONNECT_EVENTS:-false}"
case "$SEND_CONNECT_EVENTS" in
    true|false) ;;
    *) fail "Unknown DXL_SEND_CONNECT_EVENTS '$SEND_CONNECT_EVENTS' (expected true or false)." ;;
esac
echo "  Client connect events: ${SEND_CONNECT_EVENTS}"
if grep -q '^sendConnectEvents=' $DVOL_CONFIG_DEFAULTS_FILE; then
    sed -i "s|^sendConnectEvents=.*|sendConnectEvents=${SEND_CONNECT_EVENTS}|" $DVOL_CONFIG_DEFAULTS_FILE \
        || { fail 'Error setting sendConnectEvents in config file.'; }
else
    printf '\n# Whether client connect/disconnect events are published (DXL_SEND_CONNECT_EVENTS)\nsendConnectEvents=%s\n' "$SEND_CONNECT_EVENTS" >> $DVOL_CONFIG_DEFAULTS_FILE \
        || { fail 'Error adding sendConnectEvents to config file.'; }
fi

#
# Read broker identifier from configuration file
#

BROKER_ID=$(awk -F"brokerId *= *" '{printf $2}' $DVOL_CONFIG_DEFAULTS_FILE)
if [ -z $BROKER_ID ]; then
    fail 'Unable to find broker identifier in configuration file.'
fi

#
# Check and possibly generate certificate information
#

# Check to see if any of the required CA files exist
found_ca_file=false
for f in "${REQUIRED_CA_FILES[@]}"
do
    if [ -f $f ]; then
        found_ca_file=true
        break
	fi
done

if [ $found_ca_file = true ]
then
    # At least one file exists, make sure they all exist
    found_all_files=true
    for f in "${REQUIRED_CA_FILES[@]}"
    do
        if [ ! -f $f ]; then
            found_all_files=false
            echo "Required CA file not found: $f"
        fi
    done
    if [ $found_all_files = false ]; then
        fail 'Required CA files were not found.'
    fi
else
    # No CA files exist, generate them.
    echo "Generating certificate files..."

    # Create Client CA
    # keyUsage: RFC 5280 requires it for CA certificates (strict verifiers such
    # as the default Python >= 3.13 ssl context reject CA certificates without it)
    openssl req -new -passout pass:"$CERT_PASS" -subj "/CN=OpenDxlClientCA-$BROKER_ID" -x509 -days $CERT_DAYS \
        -extensions v3_ca -addext "keyUsage=critical,keyCertSign,cRLSign" \
        -keyout $DVOL_CLIENT_CA_KEY_FILE -out $DVOL_CLIENT_CA_CERT_FILE \
        || { fail 'Error creating client CA.'; }

    # Generate Broker CA CSR
    openssl req -out $DVOL_BROKER_CA_CSR_FILE -subj "/CN=OpenDxlBrokerCA-$BROKER_ID" -new -newkey rsa:2048 -nodes \
        -keyout $DVOL_BROKER_CA_KEY_FILE \
        || { fail 'Error generating broker CA certificate signing request.'; }

    # Create V3 extension file (CA is true)
    printf "basicConstraints=critical,CA:TRUE\nkeyUsage=critical,keyCertSign,cRLSign\n" > $DVOL_BROKER_V3_EXT_FILE \
        || { fail 'Error creating broker CA V3 extension file.'; }

    # Sign Broker CA CSR
    openssl x509 -req -passin pass:"$CERT_PASS" -in $DVOL_BROKER_CA_CSR_FILE -CA $DVOL_CLIENT_CA_CERT_FILE \
        -CAkey $DVOL_CLIENT_CA_KEY_FILE -CAcreateserial -out $DVOL_BROKER_CA_CERT_FILE -days $CERT_DAYS \
         -extfile $DVOL_BROKER_V3_EXT_FILE \
        || { fail 'Error signing broker CA.'; }

    # Capture Broker CA fingerprint
    openssl x509 -in $DVOL_BROKER_CA_CERT_FILE -fingerprint -noout \
        | sed -e 's/://g' -e 's/.*=\(.*\)/\L\1/' > $DVOL_BROKER_CAS_LIST_FILE \
        || { fail 'Error determining broker CA fingerprint'; }

    # Append Client CA to Broker CA
    cat $DVOL_CLIENT_CA_CERT_FILE >> $DVOL_BROKER_CA_CERT_FILE \
        || { fail 'Unable to append Client CA to Broker CA.'; }

    # Create broker CSR
    openssl req -out $DVOL_BROKER_CSR_FILE -subj "/CN=OpenDxlBroker-$BROKER_ID" -new -newkey rsa:2048 -nodes -keyout \
        $DVOL_BROKER_KEY_FILE \
        || { fail 'Error generating broker CSR.'; }

    # Create V3 extension file (CA is false)
    # clientAuth: the broker certificate is also used as client certificate by
    # the embedded console and for bridging
    printf "basicConstraints=CA:FALSE\nkeyUsage=digitalSignature,keyEncipherment\nextendedKeyUsage=serverAuth,clientAuth\n" > $DVOL_BROKER_V3_EXT_FILE \
        || { fail 'Error creating broker V3 extension file.'; }

    # Sign the Broker CSR
    openssl x509 -req -passin pass:"$CERT_PASS" -in $DVOL_BROKER_CSR_FILE -CA $DVOL_BROKER_CA_CERT_FILE \
        -CAkey $DVOL_BROKER_CA_KEY_FILE -CAcreateserial -out $DVOL_BROKER_CERT_FILE -days $CERT_DAYS \
        -extfile $DVOL_BROKER_V3_EXT_FILE \
        || { fail 'Error signing broker CSR.'; }

    # Remove temporary files
    rm -f $DVOL_KEYSTORE_DIR/*.csr
    rm -f $DVOL_BROKER_V3_EXT_FILE
fi

# Run the broker console
cd $DXLBROKER_CONSOLE_DIR || { fail 'Unable to change to broker console directory.'; }
/opt/dxlconsole/bin/python -m dxlconsole $DVOL_CONSOLE_CONFIG_DIR $BROKER_ID &
