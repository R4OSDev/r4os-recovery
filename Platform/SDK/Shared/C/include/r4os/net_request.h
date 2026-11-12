#ifndef R4OS_NET_REQUEST_H
#define R4OS_NET_REQUEST_H
#include "net_bridge.h"
/* Init only once, before first submission; Reset refuses active requests.
 * Init/reset never cancel submitted work. Keep active storage at its exact
 * address through the native close acknowledgement, also on timeout/error.
 * Response/header getters require observed completion and never expose a
 * pending worker's output. Views borrow this exact request until close/reset. */
void R4SdkNetRequestInit(R4SdkNetRequest *);
int32_t R4SdkNetRequestReset(R4SdkNetRequest *);
uint32_t R4SdkNetRequestActive(const R4SdkNetRequest *);
uint32_t R4SdkNetRequestCompleted(const R4SdkNetRequest *);
void R4SdkNetRequestInfo(const R4SdkNetRequest *, R4ProgramIoInfo *);
uint32_t R4SdkNetRequestHeader(const R4SdkNetRequest *, R4ServiceMessageHeader *);
R4SdkNetSlice R4SdkNetRequestResponse(const R4SdkNetRequest *);
uint32_t R4SdkNetRequestTcpStatus(const R4SdkNetRequest *, R4NetServiceTcpStatus *);
uint32_t R4SdkNetRequestTcpResult(const R4SdkNetRequest *, R4NetServiceTcpResult *);
R4SdkNetSlice R4SdkNetRequestTcpData(const R4SdkNetRequest *, const R4NetServiceTcpResult *);
uint32_t R4SdkNetRequestUdpStatus(const R4SdkNetRequest *, R4NetServiceUdpStatus *);
uint32_t R4SdkNetRequestUdpResult(const R4SdkNetRequest *, R4NetServiceUdpResult *);
R4SdkNetSlice R4SdkNetRequestUdpData(const R4SdkNetRequest *, const R4NetServiceUdpResult *);
#endif
