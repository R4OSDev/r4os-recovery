#ifndef R4OS_POWER_PROFILES_H
#define R4OS_POWER_PROFILES_H
#include "app_services.h"

/* Accepted receipts describe actual masks/errors, never physical frequency or
 * energy. Every call closes its ordinary handle; mutations are never retried. */
typedef struct R4PowerProfiles { R4Services services; R4PowerProfileInfo info; } R4PowerProfiles;

static inline int r4_power_profile_info_valid(const R4PowerProfileInfo *v) {
    if (!v || v->version!=1 || v->size!=sizeof(*v) || v->reserved0 || !v->service_generation || !v->service_instance_id || !v->revision ||
        v->state>R4OS_POWER_PROFILE_STATE_QUIESCED || v->selected_profile>R4OS_POWER_PROFILE_SAVING || !v->configured_cpus ||
        v->configured_cpus>64 || v->online_cpus>v->configured_cpus || v->backend_cpus>v->online_cpus || v->worker_count>v->configured_cpus) return 0;
    uint64_t mask=v->configured_cpus==64?UINT64_MAX:((UINT64_C(1)<<v->configured_cpus)-1);
    return !((v->owned_mask|v->applied_mask|v->pending_mask|v->supported_mask)&~mask);
}
static inline int32_t r4_power_profiles_call(R4PowerProfiles *client,uint16_t op,uint32_t profile,uint32_t flags,R4PowerProfileInfo *out,R4Timeout timeout) {
    if (!client || !out || (op!=R4OS_POWER_PROFILE_OP_STATUS && !client->info.service_generation)) return R4OS_SERVICE_API_RESULT_INVALID;
    R4ServiceConnection peer={0};int32_t rc=r4_services_open(&client->services,"POWERSVC",&peer);
    if(rc!=R4OS_SERVICE_API_RESULT_OK)return rc;
    if(client->info.service_generation && client->info.service_instance_id!=peer.info.instance_id){(void)r4_service_connection_close(&peer);return R4OS_SERVICE_API_RESULT_NOT_RUNNING;}
    R4PowerProfileRequest request={.version=1,.size=sizeof(request),.profile=profile,.flags=flags,.expected_service_generation=client->info.service_generation,
        .expected_revision=op==R4OS_POWER_PROFILE_OP_STATUS?0:client->info.revision};
    R4PowerProfileInfo value={0};R4ServiceCallResult result=r4_service_connection_call_struct(&peer,op,&request,sizeof(request),&value,sizeof(value),timeout);
    uint32_t instance=peer.info.instance_id;(void)r4_service_connection_close(&peer);
    if(result.kind==R4_SERVICE_CALL_TIMED_OUT)return R4OS_SERVICE_API_RESULT_TIMEOUT;
    if(result.kind!=R4_SERVICE_CALL_RESPONSE)return result.raw_code;
    if(!r4_power_profile_info_valid(&value) || value.service_instance_id!=instance || (client->info.service_generation &&
        (value.service_generation!=client->info.service_generation || value.revision<client->info.revision)))return R4OS_SERVICE_API_RESULT_INVALID;
    client->info=value;*out=value;return R4OS_SERVICE_API_RESULT_OK;
}
static inline int32_t r4_power_profiles_open(R4App *app,R4PowerProfiles *out,R4Timeout timeout){
    if(!app||!out)return R4OS_SERVICE_API_RESULT_INVALID;
    R4PowerProfiles value={.services={app}};R4PowerProfileInfo info={0};int32_t rc=r4_power_profiles_call(&value,R4OS_POWER_PROFILE_OP_STATUS,0,0,&info,timeout);
    if(rc==R4OS_SERVICE_API_RESULT_OK)*out=value;return rc;
}
static inline int32_t r4_power_profiles_status(R4PowerProfiles *client,R4PowerProfileInfo *out,R4Timeout timeout){
    return r4_power_profiles_call(client,R4OS_POWER_PROFILE_OP_STATUS,0,0,out,timeout);
}
static inline int32_t r4_power_profiles_select(R4PowerProfiles *client,uint32_t profile,int sticky_enable,R4PowerProfileInfo *out,R4Timeout timeout){
    if(profile>R4OS_POWER_PROFILE_SAVING || (profile==R4OS_POWER_PROFILE_FIRMWARE && sticky_enable))return R4OS_SERVICE_API_RESULT_INVALID;
    return r4_power_profiles_call(client,R4OS_POWER_PROFILE_OP_SELECT,profile,sticky_enable?R4OS_POWER_PROFILE_REQUEST_FLAG_STICKY_ENABLE:0,out,timeout);
}
static inline int32_t r4_power_profiles_quiesce(R4PowerProfiles *client,R4PowerProfileInfo *out,R4Timeout timeout){return r4_power_profiles_call(client,R4OS_POWER_PROFILE_OP_QUIESCE,0,0,out,timeout);}
static inline int32_t r4_power_profiles_resume(R4PowerProfiles *client,R4PowerProfileInfo *out,R4Timeout timeout){return r4_power_profiles_call(client,R4OS_POWER_PROFILE_OP_RESUME,0,0,out,timeout);}
static inline int32_t r4_power_profiles_reload(R4PowerProfiles *client,R4PowerProfileInfo *out,R4Timeout timeout){return r4_power_profiles_call(client,R4OS_POWER_PROFILE_OP_RELOAD,0,0,out,timeout);}
static inline int32_t r4_power_profiles_cpu(R4PowerProfiles *client,uint32_t cpu,R4PowerCpuProfileInfo *out,R4Timeout timeout){
    if(!client||!out||!client->info.service_generation||cpu>=client->info.configured_cpus)return R4OS_SERVICE_API_RESULT_INVALID;
    R4ServiceConnection peer={0};int32_t rc=r4_services_open(&client->services,"POWERSVC",&peer);if(rc!=R4OS_SERVICE_API_RESULT_OK)return rc;
    if(peer.info.instance_id!=client->info.service_instance_id){(void)r4_service_connection_close(&peer);return R4OS_SERVICE_API_RESULT_NOT_RUNNING;}
    R4PowerProfileRequest request={.version=1,.size=sizeof(request),.cpu_index=cpu,.expected_service_generation=client->info.service_generation};R4PowerCpuProfileInfo value={0};
    R4ServiceCallResult result=r4_service_connection_call_struct(&peer,R4OS_POWER_PROFILE_OP_CPU,&request,sizeof(request),&value,sizeof(value),timeout);(void)r4_service_connection_close(&peer);
    if(result.kind==R4_SERVICE_CALL_TIMED_OUT)return R4OS_SERVICE_API_RESULT_TIMEOUT;
    if(result.kind!=R4_SERVICE_CALL_RESPONSE)return result.raw_code;
    if(value.version!=1||value.size!=sizeof(value)||value.cpu_index!=cpu||value.service_generation!=client->info.service_generation||value.reserved0||value.reserved1||
        value.backend>R4OS_POWER_PROFILE_BACKEND_ACPI_PSS||value.state>R4OS_POWER_PROFILE_STATE_QUIESCED)return R4OS_SERVICE_API_RESULT_INVALID;
    *out=value;return R4OS_SERVICE_API_RESULT_OK;
}
#endif
