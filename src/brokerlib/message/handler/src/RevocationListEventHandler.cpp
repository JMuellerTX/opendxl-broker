/******************************************************************************
 * Copyright (c) 2018 McAfee, LLC - All Rights Reserved.
 *****************************************************************************/

#include "include/SimpleLog.h"
#include "include/brokerlib.h"
#include "cert/include/RevocationService.h"
#include "message/handler/include/RevocationListEventHandler.h"

using namespace std;
using namespace dxl::broker::cert;
using namespace dxl::broker::message;
using namespace dxl::broker::message::handler;
using namespace dxl::broker::core;

/** {@inheritDoc} */
bool RevocationListEventHandler::onStoreMessage(
        CoreMessageContext* context, struct cert_hashes* /*certHashes*/ ) const
{
    if( SL_LOG.isDebugEnabled() )
    {
        SL_START << "RevocationListEventHandler::onStoreMessage" << SL_DEBUG_END;
    }

    if( !context->isSourceBridge() && !context->isSourceOps() &&
        !( context->getContextFlags() & ( DXL_FLAG_LOCAL | DXL_FLAG_ADMIN ) ) )
    {
        SL_START << "A non-broker/non-ops client attempted to publish a revocation list event ("
            << context->getSourceId() << ")" << SL_ERROR_END;
        return false;
    }

    // Get the DXL event
    DxlEvent* evt = context->getDxlEvent();

    // Get the revocation service
    RevocationService& revService = RevocationService::getInstance();
    
    // Walk the received certificates
    string cert;
    istringstream iss(evt->getPayloadStr());    
    while( getline( iss, cert ) )
    {
        while( !cert.empty() &&
            ( cert[cert.size() - 1] == '\r' || cert[cert.size() - 1] == ' ' || cert[cert.size() - 1] == '\t' ) )
        {
            cert.erase( cert.size() - 1 );
        }
        if( !cert.empty() )
        {
            revService.addCertificate( cert.c_str() );
        }
    }
    
    // propagate event
    return true;
}
