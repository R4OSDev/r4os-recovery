//! Typed class bridge. Exact controller identity is resolved before admission;
//! callers retain their independent HID/medium owner across waits.
const native = @import("xhci.zig");
const usb_core = @import("core.zig");
const usb_host = @import("host_controller.zig");
const usb_wait = @import("usb_boot_wait.zig");
const diag_screen = @import("../../kernel/diag_screen.zig");
pub const DeviceHandle = native.DeviceHandle;
pub const EndpointHandle = native.EndpointHandle;
pub const DeviceTransaction = native.DeviceTransaction;
pub const Status = native.Status;
pub fn acquireId(id: u32) ?*native.Instance {
    const instance = native.forId(id) orelse return null;
    if (!instance.acquireControllerOwnership()) return null;
    if (instance.id() != id) {
        instance.releaseControllerOwnership();
        return null;
    }
    return instance;
}
pub fn acquireDevice(handle: DeviceHandle) ?*native.Instance {
    const instance = acquireId(handle.controller_id) orelse return null;
    if (!instance.deviceHandleCurrent(handle)) {
        instance.releaseControllerOwnership();
        return null;
    }
    return instance;
}
pub fn deviceStatus(handle: DeviceHandle) Status {
    return statusForDevice(handle) orelse .{};
}
pub fn setTopologyHook(hook: ?native.TopologyHook) void {
    native.setTopologyHook(hook);
}
pub fn controllerName(id: u32) ?[]const u8 {
    return if (native.forId(id)) |instance| instance.nameSlice() else null;
}

pub fn beginDeviceTransaction(handle: *DeviceHandle) ?DeviceTransaction {
    const instance = acquireId(handle.controller_id) orelse {
        return null;
    };
    defer instance.releaseControllerOwnership();
    return instance.beginDeviceTransaction(handle);
}

pub fn bulkInHandleFromCore(dev: *const usb_core.Device) EndpointHandle {
    const instance = acquireId(dev.controller_id) orelse {
        return .{};
    };
    defer instance.releaseControllerOwnership();
    return instance.bulkInHandleFromCore(dev);
}

pub fn bulkOutHandleFromCore(dev: *const usb_core.Device) EndpointHandle {
    const instance = acquireId(dev.controller_id) orelse {
        return .{};
    };
    defer instance.releaseControllerOwnership();
    return instance.bulkOutHandleFromCore(dev);
}

pub fn clearEndpointHaltForHandleWithin(handle: *DeviceHandle, endpoint_address: u8, recovery_budget: *const usb_wait.Deadline) bool {
    const instance = acquireId(handle.controller_id) orelse {
        return false;
    };
    defer instance.releaseControllerOwnership();
    return instance.clearEndpointHaltForHandleWithin(handle, endpoint_address, recovery_budget);
}

pub fn configureBulkEndpointHandles(in_handle: *EndpointHandle, out_handle: *EndpointHandle) bool {
    if (in_handle.device.controller_id != out_handle.device.controller_id or in_handle.device.generation != out_handle.device.generation or in_handle.device.port != out_handle.device.port or in_handle.device.slot_id != out_handle.device.slot_id) return false;
    const instance = acquireId(in_handle.device.controller_id) orelse {
        return false;
    };
    defer instance.releaseControllerOwnership();
    return instance.configureBulkEndpointHandles(in_handle, out_handle);
}

pub fn configureInterruptInEndpointHandle(handle: *EndpointHandle) bool {
    const instance = acquireId(handle.device.controller_id) orelse {
        return false;
    };
    defer instance.releaseControllerOwnership();
    return instance.configureInterruptInEndpointHandle(handle);
}

pub fn deviceHandleCurrent(handle: DeviceHandle) bool {
    const instance = acquireId(handle.controller_id) orelse {
        return false;
    };
    defer instance.releaseControllerOwnership();
    return instance.deviceHandleCurrent(handle);
}

pub fn deviceHandleFromCore(dev: *const usb_core.Device) DeviceHandle {
    const instance = acquireId(dev.controller_id) orelse {
        return .{};
    };
    defer instance.releaseControllerOwnership();
    return instance.deviceHandleFromCore(dev);
}

pub fn endDeviceTransaction(transaction: DeviceTransaction) void {
    const instance = acquireId(transaction.controller_id) orelse {
        return;
    };
    defer instance.releaseControllerOwnership();
    return instance.endDeviceTransaction(transaction);
}

pub fn getHidReportDescriptorForHandle(handle: *DeviceHandle, interface_number: u8, expected_len: u16, out: []u8) ?usize {
    const instance = acquireId(handle.controller_id) orelse {
        return null;
    };
    defer instance.releaseControllerOwnership();
    return instance.getHidReportDescriptorForHandle(handle, interface_number, expected_len, out);
}

pub fn reconfigureMassStorageBulkEndpointsForHandleWithin(handle: *DeviceHandle, in_endpoint_address: u8, out_endpoint_address: u8, recovery_budget: *const usb_wait.Deadline) bool {
    const instance = acquireId(handle.controller_id) orelse {
        return false;
    };
    defer instance.releaseControllerOwnership();
    return instance.reconfigureMassStorageBulkEndpointsForHandleWithin(handle, in_endpoint_address, out_endpoint_address, recovery_budget);
}

pub fn resetEndpointStateForHandleWithin(handle: *DeviceHandle, endpoint_address: u8, recovery_budget: *const usb_wait.Deadline) bool {
    const instance = acquireId(handle.controller_id) orelse {
        return false;
    };
    defer instance.releaseControllerOwnership();
    return instance.resetEndpointStateForHandleWithin(handle, endpoint_address, recovery_budget);
}

pub fn resetMassStorageInterfaceForHandleWithin(handle: *DeviceHandle, interface_number: u8, recovery_budget: *const usb_wait.Deadline) bool {
    const instance = acquireId(handle.controller_id) orelse {
        return false;
    };
    defer instance.releaseControllerOwnership();
    return instance.resetMassStorageInterfaceForHandleWithin(handle, interface_number, recovery_budget);
}

pub fn selectDeviceHandle(handle: *DeviceHandle) bool {
    const instance = acquireId(handle.controller_id) orelse {
        return false;
    };
    defer instance.releaseControllerOwnership();
    return instance.selectDeviceHandle(handle);
}

pub fn setConfigurationForHandle(handle: *DeviceHandle) bool {
    const instance = acquireId(handle.controller_id) orelse {
        return false;
    };
    defer instance.releaseControllerOwnership();
    return instance.setConfigurationForHandle(handle);
}

pub fn setHidBootProtocolForHandle(handle: *DeviceHandle, interface_number: u8) bool {
    const instance = acquireId(handle.controller_id) orelse {
        return false;
    };
    defer instance.releaseControllerOwnership();
    return instance.setHidBootProtocolForHandle(handle, interface_number);
}

pub fn setHidIdleForHandle(handle: *DeviceHandle, interface_number: u8) bool {
    const instance = acquireId(handle.controller_id) orelse {
        return false;
    };
    defer instance.releaseControllerOwnership();
    return instance.setHidIdleForHandle(handle, interface_number);
}

pub fn statusForDevice(handle: DeviceHandle) ?Status {
    const instance = acquireId(handle.controller_id) orelse {
        return null;
    };
    defer instance.releaseControllerOwnership();
    return instance.statusForDevice(handle);
}

pub fn takeSyncTransferIncidentForDevice(handle: DeviceHandle) diag_screen.IncidentToken {
    const instance = acquireId(handle.controller_id) orelse {
        return .{};
    };
    defer instance.releaseControllerOwnership();
    return instance.takeSyncTransferIncidentForDevice(handle);
}

pub fn usbHostEndpointHandle(handle: EndpointHandle) usb_host.EndpointHandle {
    const instance = acquireId(handle.device.controller_id) orelse {
        return .{};
    };
    defer instance.releaseControllerOwnership();
    return instance.usbHostEndpointHandle(handle);
}

// The HID caller retains acquireDevice through dispatch and these reads.
pub fn lastInterruptActualLength(handle: DeviceHandle) usize {
    const instance = acquireId(handle.controller_id) orelse return 0;
    defer instance.releaseControllerOwnership();
    return instance.lastInterruptActualLength();
}

// The HID caller retains acquireDevice through dispatch and these reads.
pub fn lastInterruptRequestedLength(handle: DeviceHandle) usize {
    const instance = acquireId(handle.controller_id) orelse return 0;
    defer instance.releaseControllerOwnership();
    return instance.lastInterruptRequestedLength();
}

// The HID caller retains acquireDevice through dispatch and these reads.
pub fn lastInterruptResidue(handle: DeviceHandle) u32 {
    const instance = acquireId(handle.controller_id) orelse return 0;
    defer instance.releaseControllerOwnership();
    return instance.lastInterruptResidue();
}
