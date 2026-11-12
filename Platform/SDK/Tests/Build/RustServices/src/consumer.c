#include <r4os/facades.h>
static int compare_bytes(const void *left,const void *right,uint32_t count){const uint8_t *a=left,*b=right;for(uint32_t i=0;i<count;++i)if(a[i]!=b[i])return 1;return 0;}
int32_t sdk55_c_network(const R4XStartContext *context){
    R4App app;if(R4SdkAppFacade(context,&app)!=0)return 1;
    R4Services services=r4_app_services(&app);R4ServiceConnection service;
    if(r4_services_open(&services,"NET55SVC",&service)!=0)return 2;
    R4Timeout timeout=r4_timeout_finite((R4Duration){2000000000});
    uint8_t bytes[32];R4ServiceCallResult call=r4_service_connection_call(&service,1,"C service",9,bytes,sizeof(bytes),timeout);
    (void)r4_service_connection_close(&service);
    if(call.kind!=R4_SERVICE_CALL_RESPONSE||call.bytes!=9||compare_bytes(bytes,"C service",9)!=0)return 3;
    R4Network network=r4_app_network(&app);R4SocketAddress address={{{10,0,2,2}},18555,0};R4TcpSocket tcp;
    if(r4_network_connect_tcp(&network,address,timeout,&tcp).kind!=R4_NET_RESULT_OK)return 4;
    uint32_t sent=0;const uint8_t payload[]="C TCP";
    for(uint32_t tries=0;sent<sizeof(payload)-1&&tries<64;++tries){
        R4NetResult result=r4_tcp_socket_write(&tcp,payload+sent,sizeof(payload)-1-sent,timeout);
        if(result.kind!=R4_NET_RESULT_OK||result.bytes==0){(void)r4_tcp_socket_close(&tcp,timeout);return 5;}sent+=result.bytes;
    }
    uint32_t got=0;
    for(uint32_t tries=0;got<sent&&tries<64;++tries){
        R4NetResult result=r4_tcp_socket_read(&tcp,bytes+got,sent-got,timeout);
        if(result.kind==R4_NET_RESULT_WOULD_BLOCK){((R4SysSleepTicksFn)(uintptr_t)app.system.table->sleep_ticks)(1);continue;}
        if(result.kind!=R4_NET_RESULT_OK||result.bytes==0){(void)r4_tcp_socket_close(&tcp,timeout);return 6;}got+=result.bytes;
    }
    (void)r4_tcp_socket_close(&tcp,timeout);
    if(sent!=sizeof(payload)-1||got!=sent||compare_bytes(bytes,payload,got)!=0)return 7;
    R4UdpSocket udp;if(r4_network_bind_udp(&network,19556,timeout,&udp).kind!=R4_NET_RESULT_OK)return 8;
    address.port=18556;
    if(r4_udp_socket_send_to(&udp,address,(const uint8_t *)"C UDP",5,timeout).bytes!=5){(void)r4_udp_socket_close(&udp,timeout);return 9;}
    R4Datagram datagram={0};R4NetResult result;
    for(uint32_t tries=0;tries<64;++tries){
        result=r4_udp_socket_receive_from(&udp,bytes,sizeof(bytes),timeout,&datagram);
        if(result.kind!=R4_NET_RESULT_WOULD_BLOCK)break;
        ((R4SysSleepTicksFn)(uintptr_t)app.system.table->sleep_ticks)(1);
    }
    (void)r4_udp_socket_close(&udp,timeout);
    return result.kind==R4_NET_RESULT_OK&&datagram.bytes==5&&compare_bytes(bytes,"C UDP",5)==0?0:10;
}
