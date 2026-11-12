#ifndef R4OS_SERIAL_H
#define R4OS_SERIAL_H
#include "r4dev.h"
typedef struct R4Serial { const R4XStartR4Dev *table; const R4OS2Context *generation2; } R4Serial;
static inline uintptr_t r4serial_callback(const R4Serial *serial, size_t offset1, uint32_t offset2) {
    if (!serial) return 0;
    const R4Dev dev = {.table = serial->table, .generation2 = serial->generation2};
    return r4dev_callback(&dev, offset1, offset2);
}
#define R4SERIAL_SLOT(s, field) r4serial_callback((s), offsetof(R4XStartR4Dev, field), offsetof(R4XStartR4Dev2, field))
#define R4SERIAL_HAS(s, field) (R4SERIAL_SLOT((s), field) != 0)
static inline int32_t r4serial_init(const R4Dev *dev, R4Serial *out) {
    if (!out) return R4OS_SERIAL_ERROR_INVALID;
    *out = (R4Serial){0};
    if (!r4dev_available(dev)) return R4OS_ERR_NO_FN;
    if (!dev->generation2 && (dev->table->magic != R4XSTART_R4DEV_MAGIC || dev->table->abi_version < 21)) return R4OS_ERR_NO_FN;
    if (!R4DEV_HAS(dev, serial_count) || !R4DEV_HAS(dev, serial_port_at) || !R4DEV_HAS(dev, serial_open) || !R4DEV_HAS(dev, serial_configure) || !R4DEV_HAS(dev, serial_read) || !R4DEV_HAS(dev, serial_write) || !R4DEV_HAS(dev, serial_drain) || !R4DEV_HAS(dev, serial_status) || !R4DEV_HAS(dev, serial_cancel) || !R4DEV_HAS(dev, serial_close)) return R4OS_ERR_NO_FN;
    *out = (R4Serial){.table = dev->table, .generation2 = dev->generation2};
    return 0;
}
static inline uint32_t r4serial_count(const R4Serial *s){if(!s||!R4SERIAL_HAS(s, serial_count)||!R4SERIAL_SLOT(s, serial_count))return 0;return ((R4DevSerialCountFn)(uintptr_t)R4SERIAL_SLOT(s, serial_count))();}
static inline int32_t r4serial_port_at(const R4Serial *s,uint32_t index,R4SerialPortInfo *out){if(!s||!R4SERIAL_HAS(s, serial_port_at)||!R4SERIAL_SLOT(s, serial_port_at))return R4OS_ERR_NO_FN;return ((R4DevSerialPortAtFn)(uintptr_t)R4SERIAL_SLOT(s, serial_port_at))(index,out);}
static inline int32_t r4serial_open(const R4Serial *s,uint64_t port_id,uint64_t generation,const R4SerialConfig *config,uint64_t *out_handle){if(!s||!R4SERIAL_HAS(s, serial_open)||!R4SERIAL_SLOT(s, serial_open))return R4OS_ERR_NO_FN;return ((R4DevSerialOpenFn)(uintptr_t)R4SERIAL_SLOT(s, serial_open))(port_id,generation,config,out_handle);}
static inline int32_t r4serial_configure(const R4Serial *s,uint64_t handle,const R4SerialConfig *config){if(!s||!R4SERIAL_HAS(s, serial_configure)||!R4SERIAL_SLOT(s, serial_configure))return R4OS_ERR_NO_FN;return ((R4DevSerialConfigureFn)(uintptr_t)R4SERIAL_SLOT(s, serial_configure))(handle,config);}
static inline int32_t r4serial_read(const R4Serial *s,uint64_t handle,uint8_t *buffer,uint32_t capacity,uint64_t timeout_ticks,R4SerialTransfer *out){if(!s||!R4SERIAL_HAS(s, serial_read)||!R4SERIAL_SLOT(s, serial_read))return R4OS_ERR_NO_FN;return ((R4DevSerialReadFn)(uintptr_t)R4SERIAL_SLOT(s, serial_read))(handle,buffer,capacity,timeout_ticks,out);}
static inline int32_t r4serial_write(const R4Serial *s,uint64_t handle,const uint8_t *buffer,uint32_t length,uint64_t timeout_ticks,R4SerialTransfer *out){if(!s||!R4SERIAL_HAS(s, serial_write)||!R4SERIAL_SLOT(s, serial_write))return R4OS_ERR_NO_FN;return ((R4DevSerialWriteFn)(uintptr_t)R4SERIAL_SLOT(s, serial_write))(handle,buffer,length,timeout_ticks,out);}
static inline int32_t r4serial_drain(const R4Serial *s,uint64_t handle,uint64_t timeout_ticks){if(!s||!R4SERIAL_HAS(s, serial_drain)||!R4SERIAL_SLOT(s, serial_drain))return R4OS_ERR_NO_FN;return ((R4DevSerialDrainFn)(uintptr_t)R4SERIAL_SLOT(s, serial_drain))(handle,timeout_ticks);}
static inline int32_t r4serial_status(const R4Serial *s,uint64_t handle,R4SerialStatus *out){if(!s||!R4SERIAL_HAS(s, serial_status)||!R4SERIAL_SLOT(s, serial_status))return R4OS_ERR_NO_FN;return ((R4DevSerialStatusFn)(uintptr_t)R4SERIAL_SLOT(s, serial_status))(handle,out);}
static inline int32_t r4serial_cancel(const R4Serial *s,uint64_t handle){if(!s||!R4SERIAL_HAS(s, serial_cancel)||!R4SERIAL_SLOT(s, serial_cancel))return R4OS_ERR_NO_FN;return ((R4DevSerialCancelFn)(uintptr_t)R4SERIAL_SLOT(s, serial_cancel))(handle);}
static inline int32_t r4serial_close(const R4Serial *s,uint64_t handle,uint32_t flags,uint64_t timeout_ticks){if(!s||!R4SERIAL_HAS(s, serial_close)||!R4SERIAL_SLOT(s, serial_close))return R4OS_ERR_NO_FN;return ((R4DevSerialCloseFn)(uintptr_t)R4SERIAL_SLOT(s, serial_close))(handle,flags,timeout_ticks);}
#endif
