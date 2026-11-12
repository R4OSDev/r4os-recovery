#ifndef R4OS_FACADES_H
#define R4OS_FACADES_H
#include "app_storage.h"
#include "app_resources.h"
#include "desktop_evidence.h"
#include "desktop_actions.h"
#include "app_network.h"
#include "app_tray.h"
#include "storage.h"
#include "storage_helpers.h"
#include "directory_page.h"
#include "serial.h"
#include "service_helpers.h"
#include "net_bridge.h"
#include "net_request.h"
#include "gui_bridge.h"
#include "platform_facade2.h"
#include "data_helpers.h"
#include "cli_helpers.h"
#include "stream_transfer.h"
#include "stream_platform2.h"
#include "cli_platform2.h"
#include "wait_set_platform2.h"
#include "byte_pipe_platform2.h"
#include "launch_io_platform2.h"
#include "network_family_platform2.h"
#include "audio_write_platform2.h"
#include "audio_capture_platform2.h"
#include "inventory_reader.h"
#include "device_snapshot.h"
#include "text_metrics.h"
#include "text_composition.h"
#include "file_picker.h"
#include "audio_write.h"
#include "pcm_source.h"
#include "published_frame.h"
#include "web_helpers.h"
#include "transport_helpers.h"
#include "update_helpers.h"

int32_t R4SdkAppFacade(const R4XStartContext *, R4App *);

/* SDK-local object functions. These are not new platform API slots. */
int32_t R4SdkFilePath(const uint8_t *, uintptr_t, int32_t, uint8_t *, uintptr_t, uint16_t *, uint8_t *);
int32_t R4SdkRegistryPath(const uint8_t *, uintptr_t, uint8_t *, uintptr_t, uint16_t *);
#endif

#include "r4os/subsystem_helpers.h"

#include "driver_helpers.h"
#include "poll_budget.h"
#include "wire_helpers.h"
