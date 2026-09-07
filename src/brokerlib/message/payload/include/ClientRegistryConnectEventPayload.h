/******************************************************************************
 * Copyright (c) 2018 McAfee, LLC - All Rights Reserved.
 *****************************************************************************/

#ifndef CLIENTREGISTRYCONNECTEVENTPAYLOAD_H_
#define CLIENTREGISTRYCONNECTEVENTPAYLOAD_H_

#include "json/include/JsonReader.h"
#include "json/include/JsonWriter.h"
#include <string>

namespace dxl {
namespace broker {
namespace message {
namespace payload {

/**
 * Payload for a "Connect" (or disconnect) message
 */
class ClientRegistryConnectEventPayload : 
    public dxl::broker::json::JsonReader,
    public dxl::broker::json::JsonWriter
{
public:
    /**
     * Constructor
     *
     * @param   clientId The client associated with the message
     */
    ClientRegistryConnectEventPayload( const std::string& clientId = "" ) : m_clientId( clientId ) {}

    /** Destructor */
    virtual ~ClientRegistryConnectEventPayload() {}

    /** {@inheritDoc} */
    void read( const Json::Value& in );    

    /** {@inheritDoc} */
    void write( Json::Value& out ) const;    

    /**
     * Returns the client identifier
     *
     * @return  The client identifier
     */
    std::string getClientId() const { return m_clientId; }

    /**
     * Connection details (fork addition). All optional: they are only written
     * when set, so a payload without them is byte-for-byte what the upstream
     * broker and the Trellix DXL broker send, and readers that only know
     * "clientGuid" keep working (jsoncpp ignores unknown members).
     *
     * @param   tlsVersion The negotiated TLS protocol version, e.g. "TLSv1.3"
     * @param   cipher The negotiated cipher suite (IANA name)
     * @param   certThumbprint SHA-1 thumbprint of the client certificate, lowercase hex
     * @param   remoteAddress The remote address of the connection
     * @param   transport "mqtt" or "websocket"
     */
    void setConnectionInfo(
        const std::string& tlsVersion, const std::string& cipher,
        const std::string& certThumbprint, const std::string& remoteAddress,
        const std::string& transport )
    {
        m_tlsVersion = tlsVersion;
        m_cipher = cipher;
        m_certThumbprint = certThumbprint;
        m_remoteAddress = remoteAddress;
        m_transport = transport;
    }

    /** Returns the negotiated TLS version (empty if unknown) */
    std::string getTlsVersion() const { return m_tlsVersion; }
    /** Returns the negotiated cipher suite (empty if unknown) */
    std::string getCipher() const { return m_cipher; }
    /** Returns the client certificate thumbprint (empty if unknown) */
    std::string getCertThumbprint() const { return m_certThumbprint; }
    /** Returns the remote address (empty if unknown) */
    std::string getRemoteAddress() const { return m_remoteAddress; }
    /** Returns the transport, "mqtt" or "websocket" (empty if unknown) */
    std::string getTransport() const { return m_transport; }

private:
    std::string m_clientId;
    std::string m_tlsVersion;
    std::string m_cipher;
    std::string m_certThumbprint;
    std::string m_remoteAddress;
    std::string m_transport;
};

} /* namespace payload */
} /* namespace message */
} /* namespace broker */
} /* namespace dxl */

#endif /* CLIENTREGISTRYCONNECTEVENTPAYLOAD_H_ */
