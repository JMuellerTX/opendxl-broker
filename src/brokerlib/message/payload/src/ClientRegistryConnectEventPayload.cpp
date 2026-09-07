/******************************************************************************
 * Copyright (c) 2018 McAfee, LLC - All Rights Reserved.
 *****************************************************************************/

#include "message/include/DxlMessageConstants.h"
#include "message/payload/include/ClientRegistryConnectEventPayload.h"

using namespace dxl::broker::message::payload;

/** {@inheritDoc} */
void ClientRegistryConnectEventPayload::write( Json::Value& out ) const
{
    out[ DxlMessageConstants::PROP_CLIENT_GUID ] = m_clientId;
    // Optional connection details: written only when known, so the
    // disconnect event and brokers without this information produce the
    // same payload as before.
    if( !m_tlsVersion.empty() )
        out[ DxlMessageConstants::PROP_TLS_VERSION ] = m_tlsVersion;
    if( !m_cipher.empty() )
        out[ DxlMessageConstants::PROP_TLS_CIPHER ] = m_cipher;
    if( !m_certThumbprint.empty() )
        out[ DxlMessageConstants::PROP_CERT_THUMBPRINT ] = m_certThumbprint;
    if( !m_remoteAddress.empty() )
        out[ DxlMessageConstants::PROP_REMOTE_ADDRESS ] = m_remoteAddress;
    if( !m_transport.empty() )
        out[ DxlMessageConstants::PROP_TRANSPORT ] = m_transport;
}

/** {@inheritDoc} */
void ClientRegistryConnectEventPayload::read( const Json::Value& in )
{
    m_clientId = in[ DxlMessageConstants::PROP_CLIENT_GUID ].asString();
    // Members added by the fork; absent in events from other brokers
    m_tlsVersion = in.get( DxlMessageConstants::PROP_TLS_VERSION, "" ).asString();
    m_cipher = in.get( DxlMessageConstants::PROP_TLS_CIPHER, "" ).asString();
    m_certThumbprint = in.get( DxlMessageConstants::PROP_CERT_THUMBPRINT, "" ).asString();
    m_remoteAddress = in.get( DxlMessageConstants::PROP_REMOTE_ADDRESS, "" ).asString();
    m_transport = in.get( DxlMessageConstants::PROP_TRANSPORT, "" ).asString();
}
