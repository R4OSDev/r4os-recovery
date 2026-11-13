// Generated Generation2. DO NOT EDIT.
pub use super::{DriverApi2, ProtocolApi2, AudioBackend2, AudioBackendStatus2, AudioBackendRegisterFn2, AudioBackendStatusFn2, AudioCaptureBackend2, AudioCaptureRegisterFn2};
pub const DRIVER_MAGIC: u32 = super::driver_api2_magic;
pub const DRIVER_VERSION: u32 = super::driver_api2_version;
pub const PROTOCOL_MAGIC: u32 = super::protocol_api2_magic;
pub const PROTOCOL_VERSION: u32 = super::protocol_api2_version;
pub const AUDIO_BACKEND_MAGIC: u32 = super::audio_backend2_magic;
pub const AUDIO_BACKEND_VERSION: u32 = super::audio_backend2_version;
pub type R4XStartShouldCloseFn2 = unsafe extern "C" fn(*const R4XStartContext2) -> u32;
pub type R4XStartYieldFn2 = unsafe extern "C" fn(*const R4XStartContext2);
pub const QUERY_MAGIC: u32 = 843854930;
pub const START_MAGIC: u32 = 844641362;
#[repr(C)]
#[derive(Clone, Copy)]
pub struct R4LQuery2 { pub magic: u32, pub abi_version: u32, pub size: u32, pub group: u32, pub reserved: u64 }
impl Default for R4LQuery2 { fn default() -> Self { Self { magic: QUERY_MAGIC, abi_version: 2, size: 24, group: 0, reserved: 0 } } }
#[repr(C)]
#[derive(Clone, Copy)]
pub struct R4XStartContext2 {
    pub magic: u32,
    pub abi_major: u16,
    pub abi_minor: u16,
    pub size: u32,
    pub flags: u32,
    pub instance_id: u64,
    pub app_class: u32,
    pub reserved0: u32,
    pub program_path: u64,
    pub args: u64,
    pub args_len: u64,
    pub imports: u64,
    pub import_count: u32,
    pub reserved1: u32,
    pub reserved_memory0: u64,
    pub reserved_memory1: u64,
    pub exit: u64,
    pub should_close: u64,
    pub r#yield: u64,
    pub reserved2: u64,
}
impl Default for R4XStartContext2 { fn default() -> Self { Self {
    magic: START_MAGIC,
    abi_major: 2,
    abi_minor: 0,
    size: 120,
    flags: 0,
    instance_id: 0,
    app_class: 0,
    reserved0: 0,
    program_path: 0,
    args: 0,
    args_len: 0,
    imports: 0,
    import_count: 0,
    reserved1: 0,
    reserved_memory0: 0,
    reserved_memory1: 0,
    exit: 0,
    should_close: 0,
    r#yield: 0,
    reserved2: 0,
} } }
const _: () = { assert!(core::mem::size_of::<R4LQuery2>() == 24); assert!(core::mem::size_of::<R4XStartContext2>() == 120); assert!(core::mem::offset_of!(R4XStartContext2,reserved2) == 112); };
pub mod R4SysFns2 {
    pub type write = unsafe extern "C" fn(*const u8, u32) -> i32;
    pub type putc = unsafe extern "C" fn(u8) -> ();
    pub type sleep_ticks = unsafe extern "C" fn(u64) -> ();
    pub type ticks = unsafe extern "C" fn() -> u64;
    pub type env_get = unsafe extern "C" fn(*const u8, *mut u8, u32) -> i32;
    pub type dir_entry = unsafe extern "C" fn(*const u8, u32, *mut u8, u32) -> i32;
    pub type program_should_close = unsafe extern "C" fn() -> u32;
    pub type program_class = unsafe extern "C" fn(*const u8, u32) -> i32;
    pub type program_instance = unsafe extern "C" fn(u32, *mut super::super::ProgramInstanceInfo) -> i32;
    pub type service_status = unsafe extern "C" fn(*const u8, *mut super::super::ServiceInfo) -> i32;
    pub type service_open = unsafe extern "C" fn(*const u8, *mut super::super::ServiceInfo) -> i32;
    pub type service_close = unsafe extern "C" fn(u32) -> i32;
    pub type service_call = unsafe extern "C" fn(u32, u16, *const u8, u32, *mut super::super::ServiceMessageHeader, *mut u8, u32, u64) -> i32;
    pub type service_endpoint_register = unsafe extern "C" fn(*const u8, u32, *mut super::super::ServiceInfo) -> i32;
    pub type service_endpoint_unregister = unsafe extern "C" fn(u32) -> i32;
    pub type service_endpoint_poll = unsafe extern "C" fn(u32) -> i32;
    pub type service_endpoint_recv = unsafe extern "C" fn(u32, *mut super::super::ServiceMessageHeader, *mut u8, u32) -> i32;
    pub type service_endpoint_reply = unsafe extern "C" fn(u32, u32, i32, *const u8, u32) -> i32;
    pub type service_detail_by_name = unsafe extern "C" fn(*const u8, *mut super::super::ServiceDetail) -> i32;
    pub type service_start = unsafe extern "C" fn(*const u8, *mut super::super::ServiceInfo) -> i32;
    pub type service_stop = unsafe extern "C" fn(*const u8, *mut super::super::ServiceInfo, u64) -> i32;
    pub type service_restart = unsafe extern "C" fn(*const u8, *mut super::super::ServiceInfo) -> i32;
    pub type service_install = unsafe extern "C" fn(*const u8, *const u8, *const u8, u32, *const u8, *mut super::super::ServiceInfo) -> i32;
    pub type service_remove = unsafe extern "C" fn(*const u8) -> i32;
    pub type vm_reserve = unsafe extern "C" fn(u64, u64, u64, *mut super::super::ProgramVmRegionInfo) -> i32;
    pub type vm_commit = unsafe extern "C" fn(u32, u64, u64, u64) -> i32;
    pub type vm_decommit = unsafe extern "C" fn(u32, u64, u64) -> i32;
    pub type vm_release = unsafe extern "C" fn(u32) -> i32;
    pub type vm_query = unsafe extern "C" fn(u32, *mut super::super::ProgramVmRegionInfo) -> i32;
    pub type thread_create = unsafe extern "C" fn(super::super::ThreadEntryFn, u64, u64, u32, *mut u32) -> i32;
    pub type thread_exit = unsafe extern "C" fn(i32) -> ();
    pub type thread_join = unsafe extern "C" fn(u32, u64, *mut i32) -> i32;
    pub type thread_current = unsafe extern "C" fn() -> u32;
    pub type thread_status = unsafe extern "C" fn(u32, *mut super::super::ProgramThreadInfo) -> i32;
    pub type io_file_read = unsafe extern "C" fn(*const u8, *mut u8, u64, u32, *mut u32) -> i32;
    pub type io_file_read_at = unsafe extern "C" fn(*const u8, u64, *mut u8, u64, u32, *mut u32) -> i32;
    pub type io_file_write = unsafe extern "C" fn(*const u8, *const u8, u64, u32, *mut u32) -> i32;
    pub type io_file_append = unsafe extern "C" fn(*const u8, *const u8, u64, u32, *mut u32) -> i32;
    pub type io_file_stream_begin = unsafe extern "C" fn(*const u8, u32, *mut u32) -> i32;
    pub type io_file_stream_write = unsafe extern "C" fn(*const u8, u64, *const u8, u64, u32, *mut u32) -> i32;
    pub type io_file_stream_finish = unsafe extern "C" fn(*const u8, u64, u32, *mut u32) -> i32;
    pub type io_file_stream_abort = unsafe extern "C" fn(*const u8, *mut u32) -> i32;
    pub type io_service_call = unsafe extern "C" fn(u32, u16, *const u8, u32, *mut super::super::ServiceMessageHeader, *mut u8, u32, u64, u32, *mut u32) -> i32;
    pub type io_status = unsafe extern "C" fn(u32, *mut super::super::ProgramIoInfo) -> i32;
    pub type io_wait = unsafe extern "C" fn(u32, u64, *mut super::super::ProgramIoInfo) -> i32;
    pub type io_close = unsafe extern "C" fn(u32) -> i32;
    pub type task_yield = unsafe extern "C" fn() -> ();
    pub type system_halt = unsafe extern "C" fn() -> ();
    pub type system_reboot = unsafe extern "C" fn() -> ();
    pub type system_poweroff = unsafe extern "C" fn() -> ();
    pub type time_state = unsafe extern "C" fn(*mut super::super::TimeState) -> ();
    pub type time_set_state = unsafe extern "C" fn(*const super::super::TimeState) -> i32;
    pub type time_seconds_since_midnight = unsafe extern "C" fn() -> u32;
    pub type dir_list = unsafe extern "C" fn(*const u8, *mut u8, u32) -> i32;
    pub type dir_create = unsafe extern "C" fn(*const u8) -> i32;
    pub type dir_delete = unsafe extern "C" fn(*const u8) -> i32;
    pub type drive_info = unsafe extern "C" fn(u32, *mut super::super::DriveInfo) -> i32;
    pub type file_info = unsafe extern "C" fn(*const u8, *mut super::super::FileInfo) -> i32;
    pub type file_delete = unsafe extern "C" fn(*const u8) -> i32;
    pub type file_rename = unsafe extern "C" fn(*const u8, *const u8) -> i32;
    pub type file_copy = unsafe extern "C" fn(*const u8, *const u8) -> i32;
    pub type file_move = unsafe extern "C" fn(*const u8, *const u8) -> i32;
    pub type file_read = unsafe extern "C" fn(*const u8, *mut u8, u32) -> i32;
    pub type file_write = unsafe extern "C" fn(*const u8, *const u8, u32) -> i32;
    pub type file_read_at = unsafe extern "C" fn(*const u8, u32, *mut u8, u32) -> i32;
    pub type file_append = unsafe extern "C" fn(*const u8, *const u8, u32) -> i32;
    pub type file_stream_begin = unsafe extern "C" fn(*const u8, u32) -> i32;
    pub type file_stream_write = unsafe extern "C" fn(*const u8, u64, *const u8, u32, u32) -> i32;
    pub type file_stream_finish = unsafe extern "C" fn(*const u8, u64, u32) -> i32;
    pub type file_stream_abort = unsafe extern "C" fn(*const u8) -> i32;
    pub type env_set = unsafe extern "C" fn(*const u8, *const u8, u32) -> i32;
    pub type registry_key_info = unsafe extern "C" fn(*const u8, *mut super::super::RegistryKeyInfo) -> i32;
    pub type registry_enum_key = unsafe extern "C" fn(*const u8, u32, *mut u8, u32) -> i32;
    pub type registry_enum_value = unsafe extern "C" fn(*const u8, u32, *mut super::super::RegistryValueInfo) -> i32;
    pub type registry_get_value = unsafe extern "C" fn(*const u8, *const u8, *mut super::super::RegistryValueInfo, *mut u8, u32) -> i32;
    pub type registry_set_value = unsafe extern "C" fn(*const u8, *const u8, u16, *const u8, u32) -> i32;
    pub type registry_delete_value = unsafe extern "C" fn(*const u8, *const u8) -> i32;
    pub type service_info = unsafe extern "C" fn(u32, *mut super::super::ServiceInfo) -> i32;
    pub type service_detail = unsafe extern "C" fn(u32, *mut super::super::ServiceDetail) -> i32;
    pub type service_set_start_mode = unsafe extern "C" fn(*const u8, u32, *mut super::super::ServiceInfo) -> i32;
    pub type service_endpoint_wait = unsafe extern "C" fn(u32, u64) -> i32;
    pub type program_run = unsafe extern "C" fn(*const u8, *const u8) -> i32;
    pub type program_launch = unsafe extern "C" fn(*const u8, *const u8, u32) -> i32;
    pub type program_spawn = unsafe extern "C" fn(*const u8, *const u8, u32) -> i32;
    pub type program_kill = unsafe extern "C" fn(u32) -> i32;
    pub type program_status = unsafe extern "C" fn(*mut super::super::ProgramStatus) -> ();
    pub type program_request_close = unsafe extern "C" fn(u32) -> i32;
    pub type program_reap_instance = unsafe extern "C" fn(u32) -> i32;
    pub type boot_log_info = unsafe extern "C" fn(*mut super::super::BootLogInfo) -> i32;
    pub type boot_log_read = unsafe extern "C" fn(u32, *mut u8, u32) -> i32;
    pub type program_spawn_handle = unsafe extern "C" fn(*const u8, *const u8, u32, *mut super::super::ProgramProcessHandle) -> i32;
    pub type program_open_handle = unsafe extern "C" fn(u32, *mut super::super::ProgramProcessHandle) -> i32;
    pub type program_handle_status = unsafe extern "C" fn(*const super::super::ProgramProcessHandle, *mut super::super::ProgramInstanceInfo) -> i32;
    pub type program_handle_request_close = unsafe extern "C" fn(*const super::super::ProgramProcessHandle) -> i32;
    pub type program_handle_kill = unsafe extern "C" fn(*const super::super::ProgramProcessHandle) -> i32;
    pub type program_handle_wait = unsafe extern "C" fn(*const super::super::ProgramProcessHandle, u64, *mut super::super::ProgramProcessCompletion) -> i32;
    pub type program_handle_reap = unsafe extern "C" fn(*const super::super::ProgramProcessHandle, *mut super::super::ProgramProcessCompletion) -> i32;
    pub type program_completion_read = unsafe extern "C" fn(*const super::super::ProgramProcessHandle, u32, *mut u8, u32, *mut u32) -> i32;
    pub type program_inventory_begin = unsafe extern "C" fn(*mut super::super::ProgramInventoryCursor, *mut super::super::ProgramInventorySummary) -> i32;
    pub type program_inventory_programs = unsafe extern "C" fn(*mut super::super::ProgramInventoryCursor, *mut super::super::ProgramInstanceSnapshot, u32, *mut super::super::ProgramInventoryPageInfo) -> i32;
    pub type program_inventory_tasks = unsafe extern "C" fn(*mut super::super::ProgramInventoryCursor, *mut super::super::ProgramTaskSnapshot, u32, *mut super::super::ProgramInventoryPageInfo) -> i32;
    pub type program_inventory_threads = unsafe extern "C" fn(*mut super::super::ProgramInventoryCursor, *mut super::super::ProgramThreadSnapshot, u32, *mut super::super::ProgramInventoryPageInfo) -> i32;
    pub type thread_create_handle = unsafe extern "C" fn(super::super::ThreadEntryFn, u64, u64, u32, *mut super::super::ProgramJoinHandle) -> i32;
    pub type thread_handle_join = unsafe extern "C" fn(*const super::super::ProgramJoinHandle, u64, *mut i32) -> i32;
    pub type thread_handle_status = unsafe extern "C" fn(*const super::super::ProgramJoinHandle, *mut super::super::ProgramThreadInfo) -> i32;
    pub type file_replace_atomic = unsafe extern "C" fn(*const u8, *const u8, *const u8, u32) -> i32;
    pub type file_delete_if_match = unsafe extern "C" fn(*const u8, u64, u32) -> i32;
    pub type file_update_atomic_checked = unsafe extern "C" fn(*const u8, *const u8, *const u8, u64, u32, u64, u32, u32) -> i32;
    pub type path_names_equal_collated = unsafe extern "C" fn(*const u8, *const u8) -> i32;
    pub type file_update_cleanup_checked = unsafe extern "C" fn(*const u8, *const u8, *const u8, *const u8, u64, u32, u64, u32, u64, u32, u32) -> i32;
    pub type file_stream_declare_publish = unsafe extern "C" fn(*const u8, *const u8, *const u8, u32) -> i32;
    pub type module_resource_stat = unsafe extern "C" fn(*const u8, u32, u32, *const u8) -> i32;
    pub type module_resource_read = unsafe extern "C" fn(*const u8, u32, u32, *const u8, *mut u8, u32) -> i32;
    pub type program_module_path = unsafe extern "C" fn(*mut u8, u32) -> i32;
    pub type program_module_running = unsafe extern "C" fn(*const u8) -> i32;
    pub type monotonic_clock = unsafe extern "C" fn(*mut super::super::MonotonicClockInfo) -> i32;
    pub type boot_ready = unsafe extern "C" fn() -> i32;
    pub type registry_snapshot_begin = unsafe extern "C" fn(*const u8, u32, *mut super::super::RegistrySnapshotCursor) -> i32;
    pub type registry_snapshot_page = unsafe extern "C" fn(*mut super::super::RegistrySnapshotCursor, *mut super::super::RegistrySnapshotEntry, u32, *mut u8, u32, *mut super::super::RegistrySnapshotPageInfo) -> i32;
    pub type registry_batch_mutate = unsafe extern "C" fn(*const super::super::RegistryBatchOperation, u32, *const u8, u32, *mut super::super::RegistryBatchResult) -> i32;
    pub type io_file_write_at = unsafe extern "C" fn(*const u8, u64, *const u8, u64, u32, *mut u32) -> i32;
    pub type io_file_info = unsafe extern "C" fn(*const u8, u32, *mut u32) -> i32;
    pub type io_file_lock = unsafe extern "C" fn(*const u8, u64, u64, u32, *mut u32) -> i32;
    pub type storage_inventory = unsafe extern "C" fn(*mut super::super::StorageInventory) -> i32;
    pub type storage_device = unsafe extern "C" fn(u64, u32, *mut super::super::StorageDeviceInfo) -> i32;
    pub type storage_partition = unsafe extern "C" fn(u64, *const super::super::StorageDeviceRef, u32, *mut super::super::StoragePartitionInfo) -> i32;
    pub type storage_volume = unsafe extern "C" fn(u64, u32, *mut super::super::StorageVolumeInfo) -> i32;
    pub type storage_claim_begin = unsafe extern "C" fn(*const super::super::StorageTarget, *mut u64) -> i32;
    pub type storage_claim_end = unsafe extern "C" fn(u64, u32) -> i32;
    pub type storage_read = unsafe extern "C" fn(*const super::super::StorageTarget, u64, u32, *mut u8, u32) -> i32;
    pub type storage_claim_read = unsafe extern "C" fn(u64, u64, u32, *mut u8, u32) -> i32;
    pub type storage_claim_write = unsafe extern "C" fn(u64, u64, u32, *const u8, u32) -> i32;
    pub type storage_claim_flush = unsafe extern "C" fn(u64) -> i32;
    pub type storage_rescan = unsafe extern "C" fn(*const super::super::StorageDeviceRef) -> i32;
    pub type storage_mount = unsafe extern "C" fn(*const super::super::StorageTarget, u32, *mut super::super::StorageVolumeRef) -> i32;
    pub type storage_unmount = unsafe extern "C" fn(*const super::super::StorageVolumeRef) -> i32;
    pub type storage_use_begin = unsafe extern "C" fn(*const u8, *mut u64) -> i32;
    pub type storage_use_end = unsafe extern "C" fn(u64) -> i32;
    pub type directory_change_begin = unsafe extern "C" fn(*const u8, *mut super::super::DirectoryChangeCursor) -> i32;
    pub type directory_change_poll = unsafe extern "C" fn(*mut super::super::DirectoryChangeCursor) -> i32;
    pub type file_copy_buffered = unsafe extern "C" fn(*const u8, *const u8, *mut u8, u32, *mut super::super::FileCopyProgress) -> i32;
    pub type notification_create = unsafe extern "C" fn(*mut u64) -> i32;
    pub type notification_query = unsafe extern "C" fn(u64, *mut u64) -> i32;
    pub type notification_notify = unsafe extern "C" fn(u64, u32) -> i32;
    pub type notification_wait = unsafe extern "C" fn(u64, u64, u64) -> i32;
    pub type notification_close = unsafe extern "C" fn(u64) -> i32;
    pub type program_local_get = unsafe extern "C" fn(u64, *mut u64) -> i32;
    pub type program_local_publish = unsafe extern "C" fn(u64, u64, *mut u64) -> i32;
    pub type thread_current_handle = unsafe extern "C" fn(*mut super::super::ProgramJoinHandle) -> i32;
    pub type cpu_capacity = unsafe extern "C" fn(*mut super::super::CpuCapacity) -> i32;
    pub type program_exit = unsafe extern "C" fn(i32, u32) -> i32;
    pub type platform_input_snapshot = unsafe extern "C" fn(*mut super::super::PlatformInputSnapshot) -> i32;
    pub type directory_next = unsafe extern "C" fn(*const u8, *mut super::super::DirectoryScanCursor, *mut u8, u32, *mut super::super::FileInfo) -> i32;
    pub type thread_placement_get = unsafe extern "C" fn(*const super::super::ProgramJoinHandle, *mut super::super::ThreadPlacementInfo, *mut u64, u32) -> i32;
    pub type thread_placement_set = unsafe extern "C" fn(*const super::super::ProgramJoinHandle, *const super::super::ThreadPlacementRequest, *const u64, u32) -> i32;
    pub type system_power_transition = unsafe extern "C" fn(u32, u64) -> i32;
    pub type entropy_source_info = unsafe extern "C" fn(*mut super::super::EntropySourceInfo) -> i32;
    pub type entropy_fill = unsafe extern "C" fn(*mut u8, u32) -> i32;
    pub type program_lifecycle_begin = unsafe extern "C" fn(*mut super::super::ProgramInventoryCursor) -> i32;
    pub type program_lifecycle_programs = unsafe extern "C" fn(*mut super::super::ProgramInventoryCursor, *mut super::super::ProgramLifecycleSnapshot, u32, *mut super::super::ProgramInventoryPageInfo) -> i32;
    pub type drive_info_geometry = unsafe extern "C" fn(u32, *mut super::super::DriveInfo) -> i32;
    pub type directory_batch = unsafe extern "C" fn(*const u8, *mut super::super::DirectoryBatchCursor, *mut super::super::DirectoryBatchEntry, u32) -> i32;
    pub type program_observation_retain = unsafe extern "C" fn(*const super::super::ProgramProcessHandle, u32, *mut super::super::ProgramObservationHandle) -> i32;
    pub type program_observation_wait = unsafe extern "C" fn(*const super::super::ProgramObservationHandle, u64, *mut super::super::ProgramProcessCompletion) -> i32;
    pub type program_observation_read = unsafe extern "C" fn(*const super::super::ProgramObservationHandle, u32, *mut u8, u32, *mut u32) -> i32;
    pub type program_observation_release = unsafe extern "C" fn(*const super::super::ProgramObservationHandle) -> i32;
    pub type file_name_limits = unsafe extern "C" fn(*const u8, *mut super::super::FileNameLimits) -> i32;
    pub type service_bound_detail = unsafe extern "C" fn(*const u8, *mut super::super::ServiceDetail, *mut super::super::ProgramProcessHandle) -> i32;
    pub type service_stop_bound = unsafe extern "C" fn(*const u8, *const super::super::ProgramProcessHandle, *mut super::super::ServiceInfo, u64) -> i32;
    pub type service_inventory_page = unsafe extern "C" fn(*mut super::super::ServiceInventoryCursor, *mut super::super::ServiceInventoryRow, u32) -> i32;
    pub type service_control_bound = unsafe extern "C" fn(*const super::super::ServiceControlRequest) -> i32;
    pub type system_update_target_supported = unsafe extern "C" fn(*const u8) -> i32;
    pub type file_metadata2 = unsafe extern "C" fn(*const u8, *mut super::super::FileMetadata2) -> i32;
    pub type directory_metadata_batch2 = unsafe extern "C" fn(*const u8, *mut super::super::DirectoryMetadataCursor2, *mut super::super::DirectoryMetadataEntry2, u32) -> i32;
    pub type waitset_create = unsafe extern "C" fn(u32, *mut u64) -> i32;
    pub type waitset_enroll = unsafe extern "C" fn(u64, *const super::super::WaitSource, *mut u64) -> i32;
    pub type waitset_rearm = unsafe extern "C" fn(u64, u64, *const super::super::WaitSource) -> i32;
    pub type waitset_remove = unsafe extern "C" fn(u64, u64) -> i32;
    pub type waitset_wait = unsafe extern "C" fn(u64, *const super::super::WaitSetDeadline, *mut super::super::WaitSetEvent, u32, *mut super::super::WaitSetBatch) -> i32;
    pub type waitset_close = unsafe extern "C" fn(u64) -> i32;
    pub type waitset_source_prepare = unsafe extern "C" fn(*const super::super::WaitSourceRequest, *mut super::super::WaitSource) -> i32;
    pub type byte_pipe_create = unsafe extern "C" fn(u64, *mut super::super::BytePipePair) -> i32;
    pub type byte_pipe_dup = unsafe extern "C" fn(super::super::BytePipeEnd, *mut super::super::BytePipeEnd) -> i32;
    pub type byte_pipe_read = unsafe extern "C" fn(super::super::BytePipeEnd, *mut u8, u64, *const super::super::WaitSetDeadline, *mut super::super::BytePipeProgress) -> i32;
    pub type byte_pipe_write = unsafe extern "C" fn(super::super::BytePipeEnd, *const u8, u64, *const super::super::WaitSetDeadline, *mut super::super::BytePipeProgress) -> i32;
    pub type byte_pipe_cancel = unsafe extern "C" fn(super::super::BytePipeEnd) -> i32;
    pub type byte_pipe_close = unsafe extern "C" fn(super::super::BytePipeEnd) -> i32;
    pub type byte_pipe_info = unsafe extern "C" fn(super::super::BytePipeEnd, *mut super::super::BytePipeInfo) -> i32;
    pub type program_launch_io = unsafe extern "C" fn(*const u8, *const u8, *const super::super::LaunchIo, *mut super::super::ProgramProcessHandle) -> i32;
    pub type program_stdio = unsafe extern "C" fn(*mut super::super::LaunchIo) -> i32;
}
pub const R4SYS_MAGIC: u32 = 844714834;
#[repr(C)]
#[derive(Clone, Copy)]
pub struct R4XStartR4Sys2 {
    pub magic: u32, pub abi_version: u32, pub size: u32, pub flags: u32,
    pub write: u64,
    pub putc: u64,
    pub sleep_ticks: u64,
    pub ticks: u64,
    pub env_get: u64,
    pub dir_entry: u64,
    pub program_should_close: u64,
    pub program_class: u64,
    pub program_instance: u64,
    pub service_status: u64,
    pub service_open: u64,
    pub service_close: u64,
    pub service_call: u64,
    pub service_endpoint_register: u64,
    pub service_endpoint_unregister: u64,
    pub service_endpoint_poll: u64,
    pub service_endpoint_recv: u64,
    pub service_endpoint_reply: u64,
    pub service_detail_by_name: u64,
    pub service_start: u64,
    pub service_stop: u64,
    pub service_restart: u64,
    pub service_install: u64,
    pub service_remove: u64,
    pub reserved0: u64,
    pub reserved1: u64,
    pub vm_reserve: u64,
    pub vm_commit: u64,
    pub vm_decommit: u64,
    pub vm_release: u64,
    pub vm_query: u64,
    pub thread_create: u64,
    pub thread_exit: u64,
    pub thread_join: u64,
    pub thread_current: u64,
    pub thread_status: u64,
    pub io_file_read: u64,
    pub io_file_read_at: u64,
    pub io_file_write: u64,
    pub io_file_append: u64,
    pub io_file_stream_begin: u64,
    pub io_file_stream_write: u64,
    pub io_file_stream_finish: u64,
    pub io_file_stream_abort: u64,
    pub io_service_call: u64,
    pub io_status: u64,
    pub io_wait: u64,
    pub io_close: u64,
    pub task_yield: u64,
    pub system_halt: u64,
    pub system_reboot: u64,
    pub system_poweroff: u64,
    pub time_state: u64,
    pub time_set_state: u64,
    pub time_seconds_since_midnight: u64,
    pub dir_list: u64,
    pub dir_create: u64,
    pub dir_delete: u64,
    pub drive_info: u64,
    pub file_info: u64,
    pub file_delete: u64,
    pub file_rename: u64,
    pub file_copy: u64,
    pub file_move: u64,
    pub file_read: u64,
    pub file_write: u64,
    pub file_read_at: u64,
    pub file_append: u64,
    pub file_stream_begin: u64,
    pub file_stream_write: u64,
    pub file_stream_finish: u64,
    pub file_stream_abort: u64,
    pub env_set: u64,
    pub registry_key_info: u64,
    pub registry_enum_key: u64,
    pub registry_enum_value: u64,
    pub registry_get_value: u64,
    pub registry_set_value: u64,
    pub registry_delete_value: u64,
    pub service_info: u64,
    pub service_detail: u64,
    pub service_set_start_mode: u64,
    pub service_endpoint_wait: u64,
    pub program_run: u64,
    pub program_launch: u64,
    pub program_spawn: u64,
    pub program_kill: u64,
    pub program_status: u64,
    pub program_request_close: u64,
    pub program_reap_instance: u64,
    pub boot_log_info: u64,
    pub boot_log_read: u64,
    pub program_spawn_handle: u64,
    pub program_open_handle: u64,
    pub program_handle_status: u64,
    pub program_handle_request_close: u64,
    pub program_handle_kill: u64,
    pub program_handle_wait: u64,
    pub program_handle_reap: u64,
    pub program_completion_read: u64,
    pub program_inventory_begin: u64,
    pub program_inventory_programs: u64,
    pub program_inventory_tasks: u64,
    pub program_inventory_threads: u64,
    pub thread_create_handle: u64,
    pub thread_handle_join: u64,
    pub thread_handle_status: u64,
    pub file_replace_atomic: u64,
    pub file_delete_if_match: u64,
    pub file_update_atomic_checked: u64,
    pub path_names_equal_collated: u64,
    pub file_update_cleanup_checked: u64,
    pub file_stream_declare_publish: u64,
    pub module_resource_stat: u64,
    pub module_resource_read: u64,
    pub program_module_path: u64,
    pub program_module_running: u64,
    pub monotonic_clock: u64,
    pub boot_ready: u64,
    pub registry_snapshot_begin: u64,
    pub registry_snapshot_page: u64,
    pub registry_batch_mutate: u64,
    pub io_file_write_at: u64,
    pub io_file_info: u64,
    pub io_file_lock: u64,
    pub storage_inventory: u64,
    pub storage_device: u64,
    pub storage_partition: u64,
    pub storage_volume: u64,
    pub storage_claim_begin: u64,
    pub storage_claim_end: u64,
    pub storage_read: u64,
    pub storage_claim_read: u64,
    pub storage_claim_write: u64,
    pub storage_claim_flush: u64,
    pub storage_rescan: u64,
    pub storage_mount: u64,
    pub storage_unmount: u64,
    pub storage_use_begin: u64,
    pub storage_use_end: u64,
    pub directory_change_begin: u64,
    pub directory_change_poll: u64,
    pub file_copy_buffered: u64,
    pub notification_create: u64,
    pub notification_query: u64,
    pub notification_notify: u64,
    pub notification_wait: u64,
    pub notification_close: u64,
    pub program_local_get: u64,
    pub program_local_publish: u64,
    pub thread_current_handle: u64,
    pub cpu_capacity: u64,
    pub program_exit: u64,
    pub platform_input_snapshot: u64,
    pub directory_next: u64,
    pub thread_placement_get: u64,
    pub thread_placement_set: u64,
    pub system_power_transition: u64,
    pub entropy_source_info: u64,
    pub entropy_fill: u64,
    pub program_lifecycle_begin: u64,
    pub program_lifecycle_programs: u64,
    pub drive_info_geometry: u64,
    pub directory_batch: u64,
    pub program_observation_retain: u64,
    pub program_observation_wait: u64,
    pub program_observation_read: u64,
    pub program_observation_release: u64,
    pub file_name_limits: u64,
    pub service_bound_detail: u64,
    pub service_stop_bound: u64,
    pub service_inventory_page: u64,
    pub service_control_bound: u64,
    pub system_update_target_supported: u64,
    pub file_metadata2: u64,
    pub directory_metadata_batch2: u64,
    pub waitset_create: u64,
    pub waitset_enroll: u64,
    pub waitset_rearm: u64,
    pub waitset_remove: u64,
    pub waitset_wait: u64,
    pub waitset_close: u64,
    pub waitset_source_prepare: u64,
    pub byte_pipe_create: u64,
    pub byte_pipe_dup: u64,
    pub byte_pipe_read: u64,
    pub byte_pipe_write: u64,
    pub byte_pipe_cancel: u64,
    pub byte_pipe_close: u64,
    pub byte_pipe_info: u64,
    pub program_launch_io: u64,
    pub program_stdio: u64,
}
impl Default for R4XStartR4Sys2 { fn default() -> Self { Self { magic: 844714834, abi_version: 6, size: 1552, flags: 0,
    write: 0,
    putc: 0,
    sleep_ticks: 0,
    ticks: 0,
    env_get: 0,
    dir_entry: 0,
    program_should_close: 0,
    program_class: 0,
    program_instance: 0,
    service_status: 0,
    service_open: 0,
    service_close: 0,
    service_call: 0,
    service_endpoint_register: 0,
    service_endpoint_unregister: 0,
    service_endpoint_poll: 0,
    service_endpoint_recv: 0,
    service_endpoint_reply: 0,
    service_detail_by_name: 0,
    service_start: 0,
    service_stop: 0,
    service_restart: 0,
    service_install: 0,
    service_remove: 0,
    reserved0: 0,
    reserved1: 0,
    vm_reserve: 0,
    vm_commit: 0,
    vm_decommit: 0,
    vm_release: 0,
    vm_query: 0,
    thread_create: 0,
    thread_exit: 0,
    thread_join: 0,
    thread_current: 0,
    thread_status: 0,
    io_file_read: 0,
    io_file_read_at: 0,
    io_file_write: 0,
    io_file_append: 0,
    io_file_stream_begin: 0,
    io_file_stream_write: 0,
    io_file_stream_finish: 0,
    io_file_stream_abort: 0,
    io_service_call: 0,
    io_status: 0,
    io_wait: 0,
    io_close: 0,
    task_yield: 0,
    system_halt: 0,
    system_reboot: 0,
    system_poweroff: 0,
    time_state: 0,
    time_set_state: 0,
    time_seconds_since_midnight: 0,
    dir_list: 0,
    dir_create: 0,
    dir_delete: 0,
    drive_info: 0,
    file_info: 0,
    file_delete: 0,
    file_rename: 0,
    file_copy: 0,
    file_move: 0,
    file_read: 0,
    file_write: 0,
    file_read_at: 0,
    file_append: 0,
    file_stream_begin: 0,
    file_stream_write: 0,
    file_stream_finish: 0,
    file_stream_abort: 0,
    env_set: 0,
    registry_key_info: 0,
    registry_enum_key: 0,
    registry_enum_value: 0,
    registry_get_value: 0,
    registry_set_value: 0,
    registry_delete_value: 0,
    service_info: 0,
    service_detail: 0,
    service_set_start_mode: 0,
    service_endpoint_wait: 0,
    program_run: 0,
    program_launch: 0,
    program_spawn: 0,
    program_kill: 0,
    program_status: 0,
    program_request_close: 0,
    program_reap_instance: 0,
    boot_log_info: 0,
    boot_log_read: 0,
    program_spawn_handle: 0,
    program_open_handle: 0,
    program_handle_status: 0,
    program_handle_request_close: 0,
    program_handle_kill: 0,
    program_handle_wait: 0,
    program_handle_reap: 0,
    program_completion_read: 0,
    program_inventory_begin: 0,
    program_inventory_programs: 0,
    program_inventory_tasks: 0,
    program_inventory_threads: 0,
    thread_create_handle: 0,
    thread_handle_join: 0,
    thread_handle_status: 0,
    file_replace_atomic: 0,
    file_delete_if_match: 0,
    file_update_atomic_checked: 0,
    path_names_equal_collated: 0,
    file_update_cleanup_checked: 0,
    file_stream_declare_publish: 0,
    module_resource_stat: 0,
    module_resource_read: 0,
    program_module_path: 0,
    program_module_running: 0,
    monotonic_clock: 0,
    boot_ready: 0,
    registry_snapshot_begin: 0,
    registry_snapshot_page: 0,
    registry_batch_mutate: 0,
    io_file_write_at: 0,
    io_file_info: 0,
    io_file_lock: 0,
    storage_inventory: 0,
    storage_device: 0,
    storage_partition: 0,
    storage_volume: 0,
    storage_claim_begin: 0,
    storage_claim_end: 0,
    storage_read: 0,
    storage_claim_read: 0,
    storage_claim_write: 0,
    storage_claim_flush: 0,
    storage_rescan: 0,
    storage_mount: 0,
    storage_unmount: 0,
    storage_use_begin: 0,
    storage_use_end: 0,
    directory_change_begin: 0,
    directory_change_poll: 0,
    file_copy_buffered: 0,
    notification_create: 0,
    notification_query: 0,
    notification_notify: 0,
    notification_wait: 0,
    notification_close: 0,
    program_local_get: 0,
    program_local_publish: 0,
    thread_current_handle: 0,
    cpu_capacity: 0,
    program_exit: 0,
    platform_input_snapshot: 0,
    directory_next: 0,
    thread_placement_get: 0,
    thread_placement_set: 0,
    system_power_transition: 0,
    entropy_source_info: 0,
    entropy_fill: 0,
    program_lifecycle_begin: 0,
    program_lifecycle_programs: 0,
    drive_info_geometry: 0,
    directory_batch: 0,
    program_observation_retain: 0,
    program_observation_wait: 0,
    program_observation_read: 0,
    program_observation_release: 0,
    file_name_limits: 0,
    service_bound_detail: 0,
    service_stop_bound: 0,
    service_inventory_page: 0,
    service_control_bound: 0,
    system_update_target_supported: 0,
    file_metadata2: 0,
    directory_metadata_batch2: 0,
    waitset_create: 0,
    waitset_enroll: 0,
    waitset_rearm: 0,
    waitset_remove: 0,
    waitset_wait: 0,
    waitset_close: 0,
    waitset_source_prepare: 0,
    byte_pipe_create: 0,
    byte_pipe_dup: 0,
    byte_pipe_read: 0,
    byte_pipe_write: 0,
    byte_pipe_cancel: 0,
    byte_pipe_close: 0,
    byte_pipe_info: 0,
    program_launch_io: 0,
    program_stdio: 0,
} } }
const _: () = { assert!(core::mem::size_of::<R4XStartR4Sys2>() == 1552);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,write) == 16);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,putc) == 24);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,sleep_ticks) == 32);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,ticks) == 40);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,env_get) == 48);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,dir_entry) == 56);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_should_close) == 64);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_class) == 72);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_instance) == 80);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,service_status) == 88);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,service_open) == 96);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,service_close) == 104);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,service_call) == 112);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,service_endpoint_register) == 120);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,service_endpoint_unregister) == 128);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,service_endpoint_poll) == 136);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,service_endpoint_recv) == 144);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,service_endpoint_reply) == 152);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,service_detail_by_name) == 160);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,service_start) == 168);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,service_stop) == 176);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,service_restart) == 184);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,service_install) == 192);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,service_remove) == 200);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,reserved0) == 208);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,reserved1) == 216);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,vm_reserve) == 224);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,vm_commit) == 232);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,vm_decommit) == 240);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,vm_release) == 248);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,vm_query) == 256);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,thread_create) == 264);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,thread_exit) == 272);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,thread_join) == 280);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,thread_current) == 288);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,thread_status) == 296);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,io_file_read) == 304);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,io_file_read_at) == 312);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,io_file_write) == 320);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,io_file_append) == 328);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,io_file_stream_begin) == 336);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,io_file_stream_write) == 344);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,io_file_stream_finish) == 352);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,io_file_stream_abort) == 360);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,io_service_call) == 368);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,io_status) == 376);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,io_wait) == 384);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,io_close) == 392);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,task_yield) == 400);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,system_halt) == 408);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,system_reboot) == 416);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,system_poweroff) == 424);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,time_state) == 432);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,time_set_state) == 440);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,time_seconds_since_midnight) == 448);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,dir_list) == 456);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,dir_create) == 464);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,dir_delete) == 472);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,drive_info) == 480);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,file_info) == 488);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,file_delete) == 496);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,file_rename) == 504);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,file_copy) == 512);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,file_move) == 520);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,file_read) == 528);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,file_write) == 536);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,file_read_at) == 544);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,file_append) == 552);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,file_stream_begin) == 560);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,file_stream_write) == 568);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,file_stream_finish) == 576);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,file_stream_abort) == 584);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,env_set) == 592);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,registry_key_info) == 600);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,registry_enum_key) == 608);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,registry_enum_value) == 616);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,registry_get_value) == 624);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,registry_set_value) == 632);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,registry_delete_value) == 640);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,service_info) == 648);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,service_detail) == 656);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,service_set_start_mode) == 664);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,service_endpoint_wait) == 672);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_run) == 680);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_launch) == 688);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_spawn) == 696);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_kill) == 704);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_status) == 712);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_request_close) == 720);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_reap_instance) == 728);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,boot_log_info) == 736);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,boot_log_read) == 744);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_spawn_handle) == 752);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_open_handle) == 760);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_handle_status) == 768);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_handle_request_close) == 776);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_handle_kill) == 784);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_handle_wait) == 792);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_handle_reap) == 800);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_completion_read) == 808);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_inventory_begin) == 816);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_inventory_programs) == 824);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_inventory_tasks) == 832);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_inventory_threads) == 840);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,thread_create_handle) == 848);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,thread_handle_join) == 856);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,thread_handle_status) == 864);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,file_replace_atomic) == 872);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,file_delete_if_match) == 880);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,file_update_atomic_checked) == 888);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,path_names_equal_collated) == 896);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,file_update_cleanup_checked) == 904);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,file_stream_declare_publish) == 912);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,module_resource_stat) == 920);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,module_resource_read) == 928);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_module_path) == 936);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_module_running) == 944);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,monotonic_clock) == 952);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,boot_ready) == 960);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,registry_snapshot_begin) == 968);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,registry_snapshot_page) == 976);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,registry_batch_mutate) == 984);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,io_file_write_at) == 992);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,io_file_info) == 1000);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,io_file_lock) == 1008);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,storage_inventory) == 1016);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,storage_device) == 1024);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,storage_partition) == 1032);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,storage_volume) == 1040);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,storage_claim_begin) == 1048);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,storage_claim_end) == 1056);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,storage_read) == 1064);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,storage_claim_read) == 1072);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,storage_claim_write) == 1080);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,storage_claim_flush) == 1088);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,storage_rescan) == 1096);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,storage_mount) == 1104);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,storage_unmount) == 1112);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,storage_use_begin) == 1120);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,storage_use_end) == 1128);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,directory_change_begin) == 1136);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,directory_change_poll) == 1144);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,file_copy_buffered) == 1152);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,notification_create) == 1160);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,notification_query) == 1168);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,notification_notify) == 1176);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,notification_wait) == 1184);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,notification_close) == 1192);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_local_get) == 1200);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_local_publish) == 1208);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,thread_current_handle) == 1216);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,cpu_capacity) == 1224);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_exit) == 1232);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,platform_input_snapshot) == 1240);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,directory_next) == 1248);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,thread_placement_get) == 1256);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,thread_placement_set) == 1264);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,system_power_transition) == 1272);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,entropy_source_info) == 1280);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,entropy_fill) == 1288);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_lifecycle_begin) == 1296);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_lifecycle_programs) == 1304);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,drive_info_geometry) == 1312);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,directory_batch) == 1320);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_observation_retain) == 1328);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_observation_wait) == 1336);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_observation_read) == 1344);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_observation_release) == 1352);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,file_name_limits) == 1360);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,service_bound_detail) == 1368);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,service_stop_bound) == 1376);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,service_inventory_page) == 1384);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,service_control_bound) == 1392);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,system_update_target_supported) == 1400);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,file_metadata2) == 1408);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,directory_metadata_batch2) == 1416);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,waitset_create) == 1424);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,waitset_enroll) == 1432);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,waitset_rearm) == 1440);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,waitset_remove) == 1448);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,waitset_wait) == 1456);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,waitset_close) == 1464);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,waitset_source_prepare) == 1472);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,byte_pipe_create) == 1480);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,byte_pipe_dup) == 1488);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,byte_pipe_read) == 1496);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,byte_pipe_write) == 1504);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,byte_pipe_cancel) == 1512);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,byte_pipe_close) == 1520);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,byte_pipe_info) == 1528);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_launch_io) == 1536);
    assert!(core::mem::offset_of!(R4XStartR4Sys2,program_stdio) == 1544);
};
pub mod R4DeskFns2 {
    pub type read_key = unsafe extern "C" fn() -> u8;
    pub type mouse_state = unsafe extern "C" fn(*mut super::super::Mouse) -> ();
    pub type mouse_show = unsafe extern "C" fn() -> ();
    pub type mouse_hide = unsafe extern "C" fn() -> ();
    pub type keyboard_layout_current = unsafe extern "C" fn(*mut super::super::KeyboardLayoutInfo) -> i32;
    pub type keyboard_layout_at = unsafe extern "C" fn(u32, *mut super::super::KeyboardLayoutInfo) -> i32;
    pub type keyboard_layout_set = unsafe extern "C" fn(*const u8) -> i32;
    pub type program_set_window = unsafe extern "C" fn(u32, i32) -> i32;
    pub type program_set_console_host = unsafe extern "C" fn(u32, u32) -> i32;
    pub type program_request_host_launch = unsafe extern "C" fn(*const u8, *const u8, u32) -> i32;
    pub type program_take_host_launch = unsafe extern "C" fn(u32, *mut super::super::ProgramHostLaunchRequest) -> i32;
    pub type program_window_id = unsafe extern "C" fn() -> i32;
    pub type gui_window_info = unsafe extern "C" fn(*mut super::super::GuiWindowInfo) -> i32;
    pub type gui_set_window_info = unsafe extern "C" fn(u32, *const super::super::GuiWindowInfo) -> i32;
    pub type gui_poll_event = unsafe extern "C" fn(*mut super::super::GuiEvent) -> i32;
    pub type gui_push_event = unsafe extern "C" fn(u32, *const super::super::GuiEvent) -> i32;
    pub type gui_set_text = unsafe extern "C" fn(*const u8) -> i32;
    pub type gui_text = unsafe extern "C" fn(u32, *mut u8, u32) -> i32;
    pub type gui_revision = unsafe extern "C" fn(u32) -> u32;
    pub type gui_command = unsafe extern "C" fn(u32, u32, *mut super::super::GuiCommand) -> i32;
    pub type gui_set_title = unsafe extern "C" fn(*const u8) -> i32;
    pub type gui_title = unsafe extern "C" fn(u32, *mut u8, u32) -> i32;
    pub type gui_set_min_size = unsafe extern "C" fn(i32, i32) -> i32;
    pub type gui_min_size = unsafe extern "C" fn(u32, *mut super::super::GuiSize) -> i32;
    pub type console_output = unsafe extern "C" fn(u32, *mut u8, u32) -> i32;
    pub type console_revision = unsafe extern "C" fn(u32) -> u32;
    pub type console_state = unsafe extern "C" fn(u32, *mut super::super::ConsoleState) -> i32;
    pub type console_set_metrics = unsafe extern "C" fn(u32, u32, u32) -> i32;
    pub type console_push_key = unsafe extern "C" fn(u32, u8) -> i32;
    pub type console_write = unsafe extern "C" fn(u32, *const u8, u32) -> i32;
    pub type console_read = unsafe extern "C" fn(*mut u8, u32) -> i32;
    pub type clipboard_write = unsafe extern "C" fn(*const u8, u32) -> i32;
    pub type clipboard_read = unsafe extern "C" fn(*mut u8, u32) -> i32;
    pub type clipboard_revision = unsafe extern "C" fn() -> u32;
    pub type clipboard_info = unsafe extern "C" fn(*mut super::super::ClipboardInfo) -> i32;
    pub type clipboard_clear = unsafe extern "C" fn() -> i32;
    pub type read_key_codepoint = unsafe extern "C" fn() -> u32;
    pub type remote_frame_info = unsafe extern "C" fn(*mut super::super::RemoteFrameInfo) -> i32;
    pub type remote_frame_read = unsafe extern "C" fn(u32, *mut u32, u32, *mut super::super::RemoteFrameInfo) -> i32;
    pub type remote_frame_wait = unsafe extern "C" fn(u32, u64, *mut super::super::RemoteFrameInfo) -> i32;
    pub type remote_frame_publish = unsafe extern "C" fn(*const super::super::RemoteFrameInfo, *const u32, u32) -> i32;
    pub type remote_input_push = unsafe extern "C" fn(*const super::super::RemoteInputEvent) -> i32;
    pub type remote_input_poll = unsafe extern "C" fn(*mut super::super::RemoteInputEvent) -> i32;
    pub type remote_input_status = unsafe extern "C" fn(*mut super::super::RemoteInputStatus) -> i32;
    pub type desktop_activity_wait = unsafe extern "C" fn(u64, u64, *mut u64) -> i32;
    pub type remote_frame_map = unsafe extern "C" fn(*mut super::super::RemoteFrameMapInfo) -> i32;
    pub type program_current_console_host = unsafe extern "C" fn() -> u32;
    pub type program_request_desktop = unsafe extern "C" fn() -> i32;
    pub type program_spawn_with_console_host = unsafe extern "C" fn(*const u8, *const u8, u32, u32) -> i32;
    pub type program_spawn_with_console_host_handle = unsafe extern "C" fn(*const u8, *const u8, u32, u32, *mut super::super::ProgramProcessHandle) -> i32;
    pub type program_set_window_handle = unsafe extern "C" fn(*const super::super::ProgramProcessHandle, i32) -> i32;
    pub type console_push_input = unsafe extern "C" fn(u32, *const u8, u32) -> i32;
    pub type remote_frame_acquire = unsafe extern "C" fn() -> i32;
    pub type remote_frame_release = unsafe extern "C" fn() -> i32;
    pub type remote_frame_consumers = unsafe extern "C" fn() -> u32;
    pub type remote_frame_publish_regions = unsafe extern "C" fn(*const super::super::RemoteFrameInfo, *const u32, u32, *const super::super::DisplayDamageRect, u32) -> i32;
    pub type console_input_wait = unsafe extern "C" fn(u64, u64, *mut u64) -> i32;
    pub type physical_key_poll = unsafe extern "C" fn(*mut super::super::PhysicalKeyEvent) -> i32;
    pub type mouse_motion = unsafe extern "C" fn(*mut super::super::MouseMotion) -> i32;
    pub type remote_frame_snapshot_acquire = unsafe extern "C" fn(u32, *mut super::super::RemoteFrameInfo, *mut super::super::RemoteFrameLease) -> i32;
    pub type remote_frame_snapshot_release = unsafe extern "C" fn(*const super::super::RemoteFrameLease) -> i32;
    pub type remote_frame_source_reset = unsafe extern "C" fn() -> i32;
    pub type remote_frame_capture_stats = unsafe extern "C" fn(*mut super::super::RemoteFrameCaptureStats) -> i32;
    pub type desktop_activity_notify = unsafe extern "C" fn() -> i32;
    pub type console_read_events = unsafe extern "C" fn(*mut super::super::ConsoleInputEvent, u32) -> i32;
    pub type console_push_events = unsafe extern "C" fn(*const super::super::ProgramProcessHandle, *const super::super::ConsoleInputEvent, u32) -> i32;
    pub type console_text_info = unsafe extern "C" fn(*const super::super::ProgramProcessHandle, *mut super::super::ConsoleTextInfo) -> i32;
    pub type console_set_encoding = unsafe extern "C" fn(*const super::super::ProgramProcessHandle, u32) -> i32;
    pub type gui_activity_wait = unsafe extern "C" fn(u64, u64, u32, *mut u64) -> i32;
    pub type gui_activity_notify = unsafe extern "C" fn(u32) -> i32;
    pub type gui_pointer_capture_info = unsafe extern "C" fn(*const super::super::GuiPointerCaptureHandle, *mut super::super::GuiPointerCaptureInfo) -> i32;
    pub type gui_pointer_capture_acquire = unsafe extern "C" fn(*const super::super::GuiPointerWindowIdentity, u32, *mut super::super::GuiPointerCaptureHandle) -> i32;
    pub type gui_pointer_capture_release = unsafe extern "C" fn(*const super::super::GuiPointerCaptureHandle) -> i32;
    pub type gui_pointer_capture_host = unsafe extern "C" fn(*const super::super::GuiPointerHostRequest, *mut super::super::GuiPointerCaptureInfo) -> i32;
    pub type gui_host_input = unsafe extern "C" fn(*const super::super::GuiHostInputRequest, *mut super::super::GuiPointerWindowIdentity) -> i32;
    pub type gui_window_appearance = unsafe extern "C" fn(*const super::super::GuiPointerWindowIdentity, *mut super::super::GuiWindowAppearance) -> i32;
}
pub const R4DESK_MAGIC: u32 = 843400274;
#[repr(C)]
#[derive(Clone, Copy)]
pub struct R4XStartR4Desk2 {
    pub magic: u32, pub abi_version: u32, pub size: u32, pub flags: u32,
    pub read_key: u64,
    pub mouse_state: u64,
    pub mouse_show: u64,
    pub mouse_hide: u64,
    pub keyboard_layout_current: u64,
    pub keyboard_layout_at: u64,
    pub keyboard_layout_set: u64,
    pub program_set_window: u64,
    pub program_set_console_host: u64,
    pub program_request_host_launch: u64,
    pub program_take_host_launch: u64,
    pub program_window_id: u64,
    pub gui_window_info: u64,
    pub gui_set_window_info: u64,
    pub gui_poll_event: u64,
    pub gui_push_event: u64,
    pub gui_set_text: u64,
    pub gui_text: u64,
    pub gui_revision: u64,
    pub gui_command: u64,
    pub gui_set_title: u64,
    pub gui_title: u64,
    pub gui_set_min_size: u64,
    pub gui_min_size: u64,
    pub console_output: u64,
    pub console_revision: u64,
    pub console_state: u64,
    pub console_set_metrics: u64,
    pub console_push_key: u64,
    pub console_write: u64,
    pub console_read: u64,
    pub clipboard_write: u64,
    pub clipboard_read: u64,
    pub clipboard_revision: u64,
    pub clipboard_info: u64,
    pub clipboard_clear: u64,
    pub read_key_codepoint: u64,
    pub reserved1: u64,
    pub remote_frame_info: u64,
    pub remote_frame_read: u64,
    pub remote_frame_wait: u64,
    pub remote_frame_publish: u64,
    pub remote_input_push: u64,
    pub remote_input_poll: u64,
    pub remote_input_status: u64,
    pub desktop_activity_wait: u64,
    pub remote_frame_map: u64,
    pub program_current_console_host: u64,
    pub program_request_desktop: u64,
    pub program_spawn_with_console_host: u64,
    pub program_spawn_with_console_host_handle: u64,
    pub program_set_window_handle: u64,
    pub console_push_input: u64,
    pub remote_frame_acquire: u64,
    pub remote_frame_release: u64,
    pub remote_frame_consumers: u64,
    pub remote_frame_publish_regions: u64,
    pub console_input_wait: u64,
    pub physical_key_poll: u64,
    pub mouse_motion: u64,
    pub remote_frame_snapshot_acquire: u64,
    pub remote_frame_snapshot_release: u64,
    pub remote_frame_source_reset: u64,
    pub remote_frame_capture_stats: u64,
    pub desktop_activity_notify: u64,
    pub console_read_events: u64,
    pub console_push_events: u64,
    pub console_text_info: u64,
    pub console_set_encoding: u64,
    pub gui_activity_wait: u64,
    pub gui_activity_notify: u64,
    pub gui_pointer_capture_info: u64,
    pub gui_pointer_capture_acquire: u64,
    pub gui_pointer_capture_release: u64,
    pub gui_pointer_capture_host: u64,
    pub gui_host_input: u64,
    pub gui_window_appearance: u64,
}
impl Default for R4XStartR4Desk2 { fn default() -> Self { Self { magic: 843400274, abi_version: 1, size: 632, flags: 0,
    read_key: 0,
    mouse_state: 0,
    mouse_show: 0,
    mouse_hide: 0,
    keyboard_layout_current: 0,
    keyboard_layout_at: 0,
    keyboard_layout_set: 0,
    program_set_window: 0,
    program_set_console_host: 0,
    program_request_host_launch: 0,
    program_take_host_launch: 0,
    program_window_id: 0,
    gui_window_info: 0,
    gui_set_window_info: 0,
    gui_poll_event: 0,
    gui_push_event: 0,
    gui_set_text: 0,
    gui_text: 0,
    gui_revision: 0,
    gui_command: 0,
    gui_set_title: 0,
    gui_title: 0,
    gui_set_min_size: 0,
    gui_min_size: 0,
    console_output: 0,
    console_revision: 0,
    console_state: 0,
    console_set_metrics: 0,
    console_push_key: 0,
    console_write: 0,
    console_read: 0,
    clipboard_write: 0,
    clipboard_read: 0,
    clipboard_revision: 0,
    clipboard_info: 0,
    clipboard_clear: 0,
    read_key_codepoint: 0,
    reserved1: 0,
    remote_frame_info: 0,
    remote_frame_read: 0,
    remote_frame_wait: 0,
    remote_frame_publish: 0,
    remote_input_push: 0,
    remote_input_poll: 0,
    remote_input_status: 0,
    desktop_activity_wait: 0,
    remote_frame_map: 0,
    program_current_console_host: 0,
    program_request_desktop: 0,
    program_spawn_with_console_host: 0,
    program_spawn_with_console_host_handle: 0,
    program_set_window_handle: 0,
    console_push_input: 0,
    remote_frame_acquire: 0,
    remote_frame_release: 0,
    remote_frame_consumers: 0,
    remote_frame_publish_regions: 0,
    console_input_wait: 0,
    physical_key_poll: 0,
    mouse_motion: 0,
    remote_frame_snapshot_acquire: 0,
    remote_frame_snapshot_release: 0,
    remote_frame_source_reset: 0,
    remote_frame_capture_stats: 0,
    desktop_activity_notify: 0,
    console_read_events: 0,
    console_push_events: 0,
    console_text_info: 0,
    console_set_encoding: 0,
    gui_activity_wait: 0,
    gui_activity_notify: 0,
    gui_pointer_capture_info: 0,
    gui_pointer_capture_acquire: 0,
    gui_pointer_capture_release: 0,
    gui_pointer_capture_host: 0,
    gui_host_input: 0,
    gui_window_appearance: 0,
} } }
const _: () = { assert!(core::mem::size_of::<R4XStartR4Desk2>() == 632);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,read_key) == 16);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,mouse_state) == 24);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,mouse_show) == 32);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,mouse_hide) == 40);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,keyboard_layout_current) == 48);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,keyboard_layout_at) == 56);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,keyboard_layout_set) == 64);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,program_set_window) == 72);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,program_set_console_host) == 80);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,program_request_host_launch) == 88);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,program_take_host_launch) == 96);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,program_window_id) == 104);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,gui_window_info) == 112);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,gui_set_window_info) == 120);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,gui_poll_event) == 128);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,gui_push_event) == 136);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,gui_set_text) == 144);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,gui_text) == 152);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,gui_revision) == 160);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,gui_command) == 168);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,gui_set_title) == 176);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,gui_title) == 184);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,gui_set_min_size) == 192);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,gui_min_size) == 200);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,console_output) == 208);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,console_revision) == 216);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,console_state) == 224);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,console_set_metrics) == 232);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,console_push_key) == 240);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,console_write) == 248);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,console_read) == 256);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,clipboard_write) == 264);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,clipboard_read) == 272);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,clipboard_revision) == 280);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,clipboard_info) == 288);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,clipboard_clear) == 296);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,read_key_codepoint) == 304);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,reserved1) == 312);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,remote_frame_info) == 320);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,remote_frame_read) == 328);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,remote_frame_wait) == 336);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,remote_frame_publish) == 344);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,remote_input_push) == 352);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,remote_input_poll) == 360);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,remote_input_status) == 368);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,desktop_activity_wait) == 376);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,remote_frame_map) == 384);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,program_current_console_host) == 392);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,program_request_desktop) == 400);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,program_spawn_with_console_host) == 408);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,program_spawn_with_console_host_handle) == 416);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,program_set_window_handle) == 424);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,console_push_input) == 432);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,remote_frame_acquire) == 440);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,remote_frame_release) == 448);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,remote_frame_consumers) == 456);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,remote_frame_publish_regions) == 464);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,console_input_wait) == 472);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,physical_key_poll) == 480);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,mouse_motion) == 488);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,remote_frame_snapshot_acquire) == 496);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,remote_frame_snapshot_release) == 504);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,remote_frame_source_reset) == 512);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,remote_frame_capture_stats) == 520);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,desktop_activity_notify) == 528);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,console_read_events) == 536);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,console_push_events) == 544);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,console_text_info) == 552);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,console_set_encoding) == 560);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,gui_activity_wait) == 568);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,gui_activity_notify) == 576);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,gui_pointer_capture_info) == 584);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,gui_pointer_capture_acquire) == 592);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,gui_pointer_capture_release) == 600);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,gui_pointer_capture_host) == 608);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,gui_host_input) == 616);
    assert!(core::mem::offset_of!(R4XStartR4Desk2,gui_window_appearance) == 624);
};
pub mod R4DrawFns2 {
    pub type screen_width = unsafe extern "C" fn() -> u32;
    pub type screen_height = unsafe extern "C" fn() -> u32;
    pub type clear = unsafe extern "C" fn(u32) -> ();
    pub type rect = unsafe extern "C" fn(i32, i32, u32, u32, u32) -> ();
    pub type text = unsafe extern "C" fn(i32, i32, *const u8, u32, u32) -> ();
    pub type display_revision = unsafe extern "C" fn() -> u32;
    pub type display_begin_frame = unsafe extern "C" fn() -> i32;
    pub type display_begin_frame_rect = unsafe extern "C" fn(i32, i32, u32, u32) -> i32;
    pub type display_present = unsafe extern "C" fn() -> i32;
    pub type display_blit_xrgb32 = unsafe extern "C" fn(i32, i32, u32, u32, *const u32, u32) -> i32;
    pub type gui_clear = unsafe extern "C" fn(u32) -> i32;
    pub type gui_rect = unsafe extern "C" fn(i32, i32, u32, u32, u32) -> i32;
    pub type gui_draw_text = unsafe extern "C" fn(i32, i32, *const u8, u32, u32) -> i32;
    pub type gui_draw_text_ex = unsafe extern "C" fn(i32, i32, *const u8, u32, u32, u32, u32) -> i32;
    pub type gui_blit = unsafe extern "C" fn(i32, i32, u32, u32, u32, *const u32, u32) -> i32;
    pub type gui_raster_read = unsafe extern "C" fn(u32, u32, *mut u32, u32) -> i32;
    pub type gui_present = unsafe extern "C" fn() -> i32;
    pub type font_count = unsafe extern "C" fn() -> u32;
    pub type font_info = unsafe extern "C" fn(u32, *mut super::super::GuiFontInfo) -> i32;
    pub type font_measure = unsafe extern "C" fn(u32, *const u8, *mut super::super::GuiTextMetrics) -> i32;
    pub type gui_set_font = unsafe extern "C" fn(u32) -> i32;
    pub type gui_font = unsafe extern "C" fn(u32, *mut super::super::GuiFontInfo) -> i32;
    pub type text_font = unsafe extern "C" fn(u32, i32, i32, *const u8, u32, u32) -> ();
    pub type font_reload = unsafe extern "C" fn() -> i32;
    pub type font_glyph_row = unsafe extern "C" fn(u32, u32, u32) -> u64;
    pub type gui_blend_alpha8 = unsafe extern "C" fn(i32, i32, u32, u32, u32, u32, *const u8, u32) -> i32;
    pub type gui_frame_begin = unsafe extern "C" fn() -> i32;
    pub type gui_frame_append = unsafe extern "C" fn(*const super::super::GuiFrameCommand, u64, *const u8, u64) -> i32;
    pub type gui_frame_commit = unsafe extern "C" fn() -> i32;
    pub type gui_frame_cancel = unsafe extern "C" fn() -> i32;
    pub type gui_frame_info = unsafe extern "C" fn(*const super::super::ProgramProcessHandle, *mut super::super::GuiFrameInfo) -> i32;
    pub type gui_frame_read = unsafe extern "C" fn(*const super::super::ProgramProcessHandle, u64, *mut super::super::GuiFrameCommand, u64, *mut u8, u64, *mut super::super::GuiFrameInfo) -> i32;
    pub type display_blit_xrgb32_stride = unsafe extern "C" fn(i32, i32, u32, u32, *const u32, u32, u32) -> i32;
    pub type display_present_regions = unsafe extern "C" fn(*const super::super::DisplayPresentRequest, *const u32, u32, *const super::super::DisplayDamageRect, u32, *mut super::super::DisplayPresentResult) -> i32;
    pub type display_present_capabilities = unsafe extern "C" fn(*mut super::super::DisplayPresentCapabilities) -> i32;
    pub type display_present_completion = unsafe extern "C" fn(u64, *mut super::super::DisplayPresentCompletion) -> i32;
    pub type gui_frame_begin_damage = unsafe extern "C" fn(*const super::super::DisplayDamageRect, u32) -> i32;
    pub type gui_frame_generation_info = unsafe extern "C" fn(*const super::super::ProgramProcessHandle, u64, *mut super::super::GuiFrameGenerationInfo) -> i32;
    pub type gui_frame_generation_read = unsafe extern "C" fn(*const super::super::ProgramProcessHandle, u64, *mut super::super::GuiFrameCommand, u64, *mut u8, u64, *mut super::super::DisplayDamageRect, u32, *mut super::super::GuiFrameGenerationInfo) -> i32;
    pub type font_glyph_bitmap = unsafe extern "C" fn(u32, u32, *mut super::super::GuiGlyphBitmap) -> i32;
    pub type font_revision = unsafe extern "C" fn() -> u32;
    pub type gui_frame_begin_replace = unsafe extern "C" fn(*const super::super::DisplayDamageRect, u32) -> i32;
    pub type gui_frame_stream_info = unsafe extern "C" fn(*const super::super::ProgramProcessHandle, *mut super::super::GuiFrameStreamInfo) -> i32;
    pub type gui_shared_raster_create = unsafe extern "C" fn(*const super::super::GuiSharedRasterCreateInfo, *mut super::super::GuiSharedRasterHandle) -> i32;
    pub type gui_shared_raster_destroy = unsafe extern "C" fn(*const super::super::GuiSharedRasterHandle) -> i32;
    pub type gui_shared_raster_map_write = unsafe extern "C" fn(*const super::super::GuiSharedRasterHandle, *mut super::super::GuiSharedRasterWriteMap) -> i32;
    pub type gui_shared_raster_publish = unsafe extern "C" fn(*const super::super::GuiSharedRasterWriteMap, *mut u64) -> i32;
    pub type gui_shared_raster_acquire = unsafe extern "C" fn(*const super::super::ProgramProcessHandle, u64, *const super::super::GuiSharedRasterHandle, u64, *mut super::super::GuiSharedRasterMap) -> i32;
    pub type gui_shared_raster_release = unsafe extern "C" fn(*const super::super::GuiSharedRasterLease) -> i32;
    pub type gfx_buffer_create = unsafe extern "C" fn(*const super::super::GfxBufferDescriptor, *mut super::super::GfxBufferReference) -> i32;
    pub type gfx_buffer_describe = unsafe extern "C" fn(*const super::super::GfxBufferHandle, *mut super::super::GfxBufferDescriptor) -> i32;
    pub type gfx_buffer_import = unsafe extern "C" fn(*const super::super::GfxBufferHandle, *mut super::super::GfxBufferReference) -> i32;
    pub type gfx_buffer_release = unsafe extern "C" fn(*const super::super::GfxBufferHandle) -> i32;
    pub type gfx_buffer_map = unsafe extern "C" fn(*const super::super::GfxBufferHandle, u32, u64, u64, *mut super::super::GfxBufferMap) -> i32;
    pub type gfx_buffer_unmap = unsafe extern "C" fn(*const super::super::GfxBufferHandle) -> i32;
    pub type gfx_buffer_export_raster = unsafe extern "C" fn(*const super::super::GuiSharedRasterLease, *mut super::super::GfxBufferReference) -> i32;
    pub type gfx_buffer_stats = unsafe extern "C" fn(*mut super::super::GfxBufferStats) -> i32;
    pub type gfx_queue_open = unsafe extern "C" fn(*const super::super::GfxQueueConfig, *mut super::super::GfxQueueHandle) -> i32;
    pub type gfx_queue_close = unsafe extern "C" fn(*const super::super::GfxQueueHandle) -> i32;
    pub type gfx_queue_submit = unsafe extern "C" fn(*const super::super::GfxQueueHandle, *const super::super::GfxSubmission, *mut super::super::GfxFenceStatus) -> i32;
    pub type gfx_fence_query = unsafe extern "C" fn(*const super::super::GfxFence, *mut super::super::GfxFenceStatus) -> i32;
    pub type gfx_fence_wait = unsafe extern "C" fn(*const super::super::GfxFence, u64, u32, *mut super::super::GfxFenceStatus) -> i32;
    pub type gfx_fence_cancel = unsafe extern "C" fn(*const super::super::GfxFence) -> i32;
    pub type gfx_fence_release = unsafe extern "C" fn(*const super::super::GfxFence) -> i32;
    pub type gfx_queue_backend = unsafe extern "C" fn(u32, *mut super::super::GfxBackendBinding) -> i32;
    pub type gfx_output_revision = unsafe extern "C" fn(*mut super::super::GfxDisplayRevision) -> i32;
    pub type gfx_output_info = unsafe extern "C" fn(u32, *mut super::super::GfxOutputInfo) -> i32;
    pub type gfx_output_mode = unsafe extern "C" fn(*const super::super::GfxOutputId, u32, *mut super::super::GfxOutputMode) -> i32;
    pub type gfx_output_edid = unsafe extern "C" fn(*const super::super::GfxOutputId, u32, *mut super::super::GfxEdidBlock) -> i32;
    pub type gfx_atomic_test = unsafe extern "C" fn(*const super::super::GfxAtomicState, *mut super::super::GfxAtomicResult) -> i32;
    pub type gfx_atomic_commit = unsafe extern "C" fn(*const super::super::GfxAtomicState, *mut super::super::GfxAtomicResult) -> i32;
    pub type gfx_atomic_submit = unsafe extern "C" fn(*const super::super::GfxAtomicState, u32, *mut super::super::GfxModeStatus) -> i32;
    pub type gfx_atomic_status = unsafe extern "C" fn(u64, *mut super::super::GfxModeStatus) -> i32;
    pub type gfx_atomic_resolve = unsafe extern "C" fn(u64, u32, *mut super::super::GfxModeStatus) -> i32;
    pub type display_presentation_stats = unsafe extern "C" fn(u32, *mut super::super::DisplayPresentationStats) -> i32;
    pub type display_cursor_info = unsafe extern "C" fn(*mut super::super::DisplayCursorInfo) -> i32;
    pub type display_cursor_submit = unsafe extern "C" fn(*const super::super::DisplayCursorRequest, *mut super::super::DisplayCursorStatus) -> i32;
    pub type display_cursor_status = unsafe extern "C" fn(*mut super::super::DisplayCursorStatus) -> i32;
    pub type gfx_queue_backend_info = unsafe extern "C" fn(u32, *mut super::super::GfxBackendInfo) -> i32;
    pub type gfx_native_start = unsafe extern "C" fn(*const super::super::GfxNativeAllocation, *mut super::super::GfxNativeStatus) -> i32;
    pub type gfx_native_query = unsafe extern "C" fn(*const super::super::GfxBufferHandle, *mut super::super::GfxNativeStatus) -> i32;
    pub type gfx_native_receive = unsafe extern "C" fn(*const super::super::GfxBufferHandle, *mut super::super::GfxBufferReference) -> i32;
    pub type gfx_native_close = unsafe extern "C" fn(*const super::super::GfxBufferHandle) -> i32;
    pub type gfx_native_wait = unsafe extern "C" fn(*const super::super::GfxBufferHandle, u64, *mut super::super::GfxNativeStatus) -> i32;
    pub type gfx_queue_submit_render_list = unsafe extern "C" fn(*const super::super::GfxQueueHandle, *const super::super::GfxSubmission, *const super::super::GfxRenderList, *mut super::super::GfxFenceStatus) -> i32;
    pub type display_presentation_info = unsafe extern "C" fn(u32, *mut super::super::DisplayPresentationInfo) -> i32;
    pub type display_presentation_feedback = unsafe extern "C" fn(u32, *const super::super::GfxFence, *mut super::super::DisplayPresentationStats) -> i32;
    pub type display_output_target = unsafe extern "C" fn(u32, u32, *mut super::super::GfxOutputTarget) -> i32;
    pub type gfx_queue_submit_output = unsafe extern "C" fn(*const super::super::GfxQueueHandle, *const super::super::GfxSubmission, *const super::super::GfxOutputTarget, *mut super::super::GfxFenceStatus) -> i32;
    pub type display_output_presentation_info = unsafe extern "C" fn(*const super::super::GfxOutputTarget, *mut super::super::DisplayPresentationInfo) -> i32;
    pub type display_output_presentation_feedback = unsafe extern "C" fn(*const super::super::GfxOutputTarget, *const super::super::GfxFence, *mut super::super::DisplayPresentationStats) -> i32;
    pub type gfx_queue_submit_render_grid_list = unsafe extern "C" fn(*const super::super::GfxQueueHandle, *const super::super::GfxSubmission, *const super::super::GfxRenderGridList, *mut super::super::GfxFenceStatus) -> i32;
    pub type gfx_output_color = unsafe extern "C" fn(*const super::super::GfxOutputId, *mut super::super::GfxOutputColorState) -> i32;
    pub type gfx_queue_submit_render_color_list = unsafe extern "C" fn(*const super::super::GfxQueueHandle, *const super::super::GfxSubmission, *const super::super::GfxRenderColorList, *mut super::super::GfxFenceStatus) -> i32;
    pub type gfx_atomic_test_color = unsafe extern "C" fn(*const super::super::GfxModeColorRequest, *mut super::super::GfxAtomicResult) -> i32;
    pub type gfx_atomic_submit_color = unsafe extern "C" fn(*const super::super::GfxModeColorRequest, u32, *mut super::super::GfxModeStatus) -> i32;
    pub type gfx_output_refresh = unsafe extern "C" fn(*const super::super::GfxOutputTarget, *mut super::super::GfxOutputRefresh) -> i32;
    pub type gfx_refresh_request = unsafe extern "C" fn(*const super::super::GfxRefreshRequest, *mut super::super::GfxRefreshRequest) -> i32;
    pub type gfx_memory_budget = unsafe extern "C" fn(*const super::super::GfxDeviceBudgetRequest, *mut super::super::GfxDeviceBudgetState) -> i32;
    pub type gfx_telemetry = unsafe extern "C" fn(*const super::super::GfxTelemetryRequest, *mut super::super::GfxTelemetryState) -> i32;
    pub type gfx_output_power = unsafe extern "C" fn(*const super::super::GfxOutputId, *mut super::super::GfxOutputPower) -> i32;
    pub type gfx_power_request = unsafe extern "C" fn(*const super::super::GfxPowerRequest, *mut super::super::GfxPowerRequest) -> i32;
    pub type gfx_virtual_start = unsafe extern "C" fn(*const super::super::GfxVirtualRequest, *mut super::super::GfxVirtualStatus) -> i32;
    pub type gfx_virtual_query = unsafe extern "C" fn(*const super::super::GfxBufferHandle, *mut super::super::GfxVirtualStatus) -> i32;
    pub type gfx_virtual_close = unsafe extern "C" fn(*const super::super::GfxBufferHandle, u32) -> i32;
    pub type gfx_virtual_wait = unsafe extern "C" fn(*const super::super::GfxBufferHandle, u32, u64, *mut super::super::GfxVirtualStatus) -> i32;
    pub type gfx_buffer_map_persistent = unsafe extern "C" fn(*const super::super::GfxBufferHandle, u32, u64, u64, *mut super::super::GfxBufferMap) -> i32;
    pub type gfx_queue_backend_properties = unsafe extern "C" fn(*const super::super::GfxBackendBinding, *mut super::super::GfxBackendProperties) -> i32;
    pub type gfx_queue_submit_native = unsafe extern "C" fn(*const super::super::GfxQueueHandle, *const super::super::GfxSubmission, *const super::super::GfxNativeSubmission, *mut super::super::GfxFenceStatus) -> i32;
    pub type gfx_queue_submit_render_color_grid_list = unsafe extern "C" fn(*const super::super::GfxQueueHandle, *const super::super::GfxSubmission, *const super::super::GfxRenderColorGridList, *mut super::super::GfxFenceStatus) -> i32;
    pub type gfx_output_brightness = unsafe extern "C" fn(*const super::super::GfxOutputId, *mut super::super::GfxOutputBrightness) -> i32;
    pub type gfx_brightness_request = unsafe extern "C" fn(*const super::super::GfxBrightnessRequest, *mut super::super::GfxBrightnessRequest) -> i32;
    pub type font_prefix_metrics2 = unsafe extern "C" fn(u32, *const u8, u32, *mut super::super::FontAdvance2, u32, *mut super::super::FontAdvanceInfo2) -> i32;
}
pub const R4DRAW_MAGIC: u32 = 844579922;
#[repr(C)]
#[derive(Clone, Copy)]
pub struct R4XStartR4Draw2 {
    pub magic: u32, pub abi_version: u32, pub size: u32, pub flags: u32,
    pub screen_width: u64,
    pub screen_height: u64,
    pub clear: u64,
    pub rect: u64,
    pub text: u64,
    pub display_revision: u64,
    pub display_begin_frame: u64,
    pub display_begin_frame_rect: u64,
    pub display_present: u64,
    pub display_blit_xrgb32: u64,
    pub gui_clear: u64,
    pub gui_rect: u64,
    pub gui_draw_text: u64,
    pub gui_draw_text_ex: u64,
    pub gui_blit: u64,
    pub gui_raster_read: u64,
    pub gui_present: u64,
    pub font_count: u64,
    pub font_info: u64,
    pub font_measure: u64,
    pub gui_set_font: u64,
    pub gui_font: u64,
    pub text_font: u64,
    pub font_reload: u64,
    pub font_glyph_row: u64,
    pub gui_blend_alpha8: u64,
    pub gui_frame_begin: u64,
    pub gui_frame_append: u64,
    pub gui_frame_commit: u64,
    pub gui_frame_cancel: u64,
    pub gui_frame_info: u64,
    pub gui_frame_read: u64,
    pub display_blit_xrgb32_stride: u64,
    pub display_present_regions: u64,
    pub display_present_capabilities: u64,
    pub display_present_completion: u64,
    pub gui_frame_begin_damage: u64,
    pub gui_frame_generation_info: u64,
    pub gui_frame_generation_read: u64,
    pub font_glyph_bitmap: u64,
    pub font_revision: u64,
    pub gui_frame_begin_replace: u64,
    pub gui_frame_stream_info: u64,
    pub gui_shared_raster_create: u64,
    pub gui_shared_raster_destroy: u64,
    pub gui_shared_raster_map_write: u64,
    pub gui_shared_raster_publish: u64,
    pub gui_shared_raster_acquire: u64,
    pub gui_shared_raster_release: u64,
    pub gfx_buffer_create: u64,
    pub gfx_buffer_describe: u64,
    pub gfx_buffer_import: u64,
    pub gfx_buffer_release: u64,
    pub gfx_buffer_map: u64,
    pub gfx_buffer_unmap: u64,
    pub gfx_buffer_export_raster: u64,
    pub gfx_buffer_stats: u64,
    pub gfx_queue_open: u64,
    pub gfx_queue_close: u64,
    pub gfx_queue_submit: u64,
    pub gfx_fence_query: u64,
    pub gfx_fence_wait: u64,
    pub gfx_fence_cancel: u64,
    pub gfx_fence_release: u64,
    pub gfx_queue_backend: u64,
    pub gfx_output_revision: u64,
    pub gfx_output_info: u64,
    pub gfx_output_mode: u64,
    pub gfx_output_edid: u64,
    pub gfx_atomic_test: u64,
    pub gfx_atomic_commit: u64,
    pub gfx_atomic_submit: u64,
    pub gfx_atomic_status: u64,
    pub gfx_atomic_resolve: u64,
    pub display_presentation_stats: u64,
    pub display_cursor_info: u64,
    pub display_cursor_submit: u64,
    pub display_cursor_status: u64,
    pub gfx_queue_backend_info: u64,
    pub gfx_native_start: u64,
    pub gfx_native_query: u64,
    pub gfx_native_receive: u64,
    pub gfx_native_close: u64,
    pub gfx_native_wait: u64,
    pub gfx_queue_submit_render_list: u64,
    pub display_presentation_info: u64,
    pub display_presentation_feedback: u64,
    pub display_output_target: u64,
    pub gfx_queue_submit_output: u64,
    pub display_output_presentation_info: u64,
    pub display_output_presentation_feedback: u64,
    pub gfx_queue_submit_render_grid_list: u64,
    pub gfx_output_color: u64,
    pub gfx_queue_submit_render_color_list: u64,
    pub gfx_atomic_test_color: u64,
    pub gfx_atomic_submit_color: u64,
    pub gfx_output_refresh: u64,
    pub gfx_refresh_request: u64,
    pub gfx_memory_budget: u64,
    pub gfx_telemetry: u64,
    pub gfx_output_power: u64,
    pub gfx_power_request: u64,
    pub gfx_virtual_start: u64,
    pub gfx_virtual_query: u64,
    pub gfx_virtual_close: u64,
    pub gfx_virtual_wait: u64,
    pub gfx_buffer_map_persistent: u64,
    pub gfx_queue_backend_properties: u64,
    pub gfx_queue_submit_native: u64,
    pub gfx_queue_submit_render_color_grid_list: u64,
    pub gfx_output_brightness: u64,
    pub gfx_brightness_request: u64,
    pub font_prefix_metrics2: u64,
}
impl Default for R4XStartR4Draw2 { fn default() -> Self { Self { magic: 844579922, abi_version: 2, size: 920, flags: 0,
    screen_width: 0,
    screen_height: 0,
    clear: 0,
    rect: 0,
    text: 0,
    display_revision: 0,
    display_begin_frame: 0,
    display_begin_frame_rect: 0,
    display_present: 0,
    display_blit_xrgb32: 0,
    gui_clear: 0,
    gui_rect: 0,
    gui_draw_text: 0,
    gui_draw_text_ex: 0,
    gui_blit: 0,
    gui_raster_read: 0,
    gui_present: 0,
    font_count: 0,
    font_info: 0,
    font_measure: 0,
    gui_set_font: 0,
    gui_font: 0,
    text_font: 0,
    font_reload: 0,
    font_glyph_row: 0,
    gui_blend_alpha8: 0,
    gui_frame_begin: 0,
    gui_frame_append: 0,
    gui_frame_commit: 0,
    gui_frame_cancel: 0,
    gui_frame_info: 0,
    gui_frame_read: 0,
    display_blit_xrgb32_stride: 0,
    display_present_regions: 0,
    display_present_capabilities: 0,
    display_present_completion: 0,
    gui_frame_begin_damage: 0,
    gui_frame_generation_info: 0,
    gui_frame_generation_read: 0,
    font_glyph_bitmap: 0,
    font_revision: 0,
    gui_frame_begin_replace: 0,
    gui_frame_stream_info: 0,
    gui_shared_raster_create: 0,
    gui_shared_raster_destroy: 0,
    gui_shared_raster_map_write: 0,
    gui_shared_raster_publish: 0,
    gui_shared_raster_acquire: 0,
    gui_shared_raster_release: 0,
    gfx_buffer_create: 0,
    gfx_buffer_describe: 0,
    gfx_buffer_import: 0,
    gfx_buffer_release: 0,
    gfx_buffer_map: 0,
    gfx_buffer_unmap: 0,
    gfx_buffer_export_raster: 0,
    gfx_buffer_stats: 0,
    gfx_queue_open: 0,
    gfx_queue_close: 0,
    gfx_queue_submit: 0,
    gfx_fence_query: 0,
    gfx_fence_wait: 0,
    gfx_fence_cancel: 0,
    gfx_fence_release: 0,
    gfx_queue_backend: 0,
    gfx_output_revision: 0,
    gfx_output_info: 0,
    gfx_output_mode: 0,
    gfx_output_edid: 0,
    gfx_atomic_test: 0,
    gfx_atomic_commit: 0,
    gfx_atomic_submit: 0,
    gfx_atomic_status: 0,
    gfx_atomic_resolve: 0,
    display_presentation_stats: 0,
    display_cursor_info: 0,
    display_cursor_submit: 0,
    display_cursor_status: 0,
    gfx_queue_backend_info: 0,
    gfx_native_start: 0,
    gfx_native_query: 0,
    gfx_native_receive: 0,
    gfx_native_close: 0,
    gfx_native_wait: 0,
    gfx_queue_submit_render_list: 0,
    display_presentation_info: 0,
    display_presentation_feedback: 0,
    display_output_target: 0,
    gfx_queue_submit_output: 0,
    display_output_presentation_info: 0,
    display_output_presentation_feedback: 0,
    gfx_queue_submit_render_grid_list: 0,
    gfx_output_color: 0,
    gfx_queue_submit_render_color_list: 0,
    gfx_atomic_test_color: 0,
    gfx_atomic_submit_color: 0,
    gfx_output_refresh: 0,
    gfx_refresh_request: 0,
    gfx_memory_budget: 0,
    gfx_telemetry: 0,
    gfx_output_power: 0,
    gfx_power_request: 0,
    gfx_virtual_start: 0,
    gfx_virtual_query: 0,
    gfx_virtual_close: 0,
    gfx_virtual_wait: 0,
    gfx_buffer_map_persistent: 0,
    gfx_queue_backend_properties: 0,
    gfx_queue_submit_native: 0,
    gfx_queue_submit_render_color_grid_list: 0,
    gfx_output_brightness: 0,
    gfx_brightness_request: 0,
    font_prefix_metrics2: 0,
} } }
const _: () = { assert!(core::mem::size_of::<R4XStartR4Draw2>() == 920);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,screen_width) == 16);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,screen_height) == 24);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,clear) == 32);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,rect) == 40);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,text) == 48);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,display_revision) == 56);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,display_begin_frame) == 64);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,display_begin_frame_rect) == 72);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,display_present) == 80);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,display_blit_xrgb32) == 88);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gui_clear) == 96);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gui_rect) == 104);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gui_draw_text) == 112);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gui_draw_text_ex) == 120);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gui_blit) == 128);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gui_raster_read) == 136);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gui_present) == 144);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,font_count) == 152);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,font_info) == 160);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,font_measure) == 168);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gui_set_font) == 176);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gui_font) == 184);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,text_font) == 192);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,font_reload) == 200);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,font_glyph_row) == 208);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gui_blend_alpha8) == 216);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gui_frame_begin) == 224);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gui_frame_append) == 232);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gui_frame_commit) == 240);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gui_frame_cancel) == 248);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gui_frame_info) == 256);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gui_frame_read) == 264);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,display_blit_xrgb32_stride) == 272);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,display_present_regions) == 280);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,display_present_capabilities) == 288);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,display_present_completion) == 296);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gui_frame_begin_damage) == 304);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gui_frame_generation_info) == 312);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gui_frame_generation_read) == 320);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,font_glyph_bitmap) == 328);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,font_revision) == 336);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gui_frame_begin_replace) == 344);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gui_frame_stream_info) == 352);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gui_shared_raster_create) == 360);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gui_shared_raster_destroy) == 368);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gui_shared_raster_map_write) == 376);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gui_shared_raster_publish) == 384);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gui_shared_raster_acquire) == 392);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gui_shared_raster_release) == 400);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_buffer_create) == 408);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_buffer_describe) == 416);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_buffer_import) == 424);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_buffer_release) == 432);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_buffer_map) == 440);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_buffer_unmap) == 448);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_buffer_export_raster) == 456);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_buffer_stats) == 464);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_queue_open) == 472);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_queue_close) == 480);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_queue_submit) == 488);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_fence_query) == 496);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_fence_wait) == 504);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_fence_cancel) == 512);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_fence_release) == 520);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_queue_backend) == 528);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_output_revision) == 536);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_output_info) == 544);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_output_mode) == 552);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_output_edid) == 560);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_atomic_test) == 568);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_atomic_commit) == 576);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_atomic_submit) == 584);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_atomic_status) == 592);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_atomic_resolve) == 600);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,display_presentation_stats) == 608);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,display_cursor_info) == 616);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,display_cursor_submit) == 624);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,display_cursor_status) == 632);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_queue_backend_info) == 640);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_native_start) == 648);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_native_query) == 656);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_native_receive) == 664);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_native_close) == 672);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_native_wait) == 680);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_queue_submit_render_list) == 688);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,display_presentation_info) == 696);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,display_presentation_feedback) == 704);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,display_output_target) == 712);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_queue_submit_output) == 720);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,display_output_presentation_info) == 728);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,display_output_presentation_feedback) == 736);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_queue_submit_render_grid_list) == 744);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_output_color) == 752);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_queue_submit_render_color_list) == 760);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_atomic_test_color) == 768);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_atomic_submit_color) == 776);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_output_refresh) == 784);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_refresh_request) == 792);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_memory_budget) == 800);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_telemetry) == 808);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_output_power) == 816);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_power_request) == 824);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_virtual_start) == 832);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_virtual_query) == 840);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_virtual_close) == 848);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_virtual_wait) == 856);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_buffer_map_persistent) == 864);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_queue_backend_properties) == 872);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_queue_submit_native) == 880);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_queue_submit_render_color_grid_list) == 888);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_output_brightness) == 896);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,gfx_brightness_request) == 904);
    assert!(core::mem::offset_of!(R4XStartR4Draw2,font_prefix_metrics2) == 912);
};
pub mod R4NetFns2 {
    pub type tcp_connect = unsafe extern "C" fn(u8, u8, u8, u8, u16) -> i32;
    pub type tcp_write = unsafe extern "C" fn(u32, *const u8, u32) -> i32;
    pub type tcp_read = unsafe extern "C" fn(u32, *mut u8, u32) -> i32;
    pub type tcp_close = unsafe extern "C" fn(u32) -> i32;
    pub type tcp_summary = unsafe extern "C" fn(*mut super::super::TcpSummary) -> i32;
    pub type tcp_connection = unsafe extern "C" fn(u32, *mut super::super::TcpConnectionInfo) -> i32;
    pub type tcp_echo_listen_once = unsafe extern "C" fn(u16, *mut u8, u32) -> i32;
    pub type tcp_accept_read_once = unsafe extern "C" fn(u16, *mut u8, u32, *mut super::super::TcpAcceptResult) -> i32;
    pub type net_ipv4_send = unsafe extern "C" fn(u8, u8, u8, u8, u8, *const u8, u32) -> i32;
    pub type net_ipv4_recv = unsafe extern "C" fn(u8, *mut super::super::NetIpv4Packet, *mut u8, u32) -> i32;
    pub type net_config_get = unsafe extern "C" fn(*mut super::super::NetConfigSnapshot) -> i32;
    pub type net_config_set = unsafe extern "C" fn(*const super::super::NetConfigRequest) -> i32;
    pub type net_dns_resolve = unsafe extern "C" fn(*const u8, u32, *mut [u8; 4]) -> i32;
    pub type net_dns_resolve_server = unsafe extern "C" fn(u8, u8, u8, u8, *const u8, u32, *mut [u8; 4]) -> i32;
    pub type net_dhcp_acquire = unsafe extern "C" fn() -> i32;
    pub type net_dhcp_renew = unsafe extern "C" fn() -> i32;
    pub type net_dhcp_release = unsafe extern "C" fn() -> i32;
    pub type net_dhcp_status = unsafe extern "C" fn(*mut super::super::DhcpStatus) -> i32;
    pub type net_detail_get = unsafe extern "C" fn(u32, *mut super::super::NetDetailSnapshot) -> i32;
    pub type net_diag_run = unsafe extern "C" fn(u32, *mut super::super::NetDiagResult) -> i32;
    pub type ipc_open = unsafe extern "C" fn(u32) -> i32;
    pub type ipc_send = unsafe extern "C" fn(u32, *const u8, u32) -> i32;
    pub type ipc_recv = unsafe extern "C" fn(u32, *mut u8, u32) -> i32;
    pub type ipc_poll = unsafe extern "C" fn(u32) -> i32;
    pub type ipc_close = unsafe extern "C" fn(u32) -> i32;
    pub type ipc_summary = unsafe extern "C" fn(*mut super::super::IpcSummary) -> i32;
    pub type ipc_channel = unsafe extern "C" fn(u32, *mut super::super::IpcChannelInfo) -> i32;
    pub type serial_link_status = unsafe extern "C" fn(*mut super::super::SerialLinkStatus) -> i32;
    pub type serial_link_poll = unsafe extern "C" fn() -> i32;
    pub type serial_link_send_message = unsafe extern "C" fn(*const u8, u32) -> i32;
    pub type serial_link_host_test = unsafe extern "C" fn() -> i32;
    pub type serial_link_inbox = unsafe extern "C" fn(*mut super::super::SerialLinkMessage) -> i32;
    pub type net_service_request = unsafe extern "C" fn(u32, u16, u32, u16, *const u8, u32, *mut u8, u32) -> i32;
    pub type ipc_performance = unsafe extern "C" fn(u32, *mut super::super::IpcPerformanceSummary) -> i32;
    pub type tcp_performance = unsafe extern "C" fn(*mut super::super::TcpPerformanceInfo) -> i32;
}
pub const R4NET_MAGIC: u32 = 843402834;
#[repr(C)]
#[derive(Clone, Copy)]
pub struct R4XStartR4Net2 {
    pub magic: u32, pub abi_version: u32, pub size: u32, pub flags: u32,
    pub tcp_connect: u64,
    pub tcp_write: u64,
    pub tcp_read: u64,
    pub tcp_close: u64,
    pub tcp_summary: u64,
    pub tcp_connection: u64,
    pub tcp_echo_listen_once: u64,
    pub tcp_accept_read_once: u64,
    pub net_ipv4_send: u64,
    pub net_ipv4_recv: u64,
    pub net_config_get: u64,
    pub net_config_set: u64,
    pub net_dns_resolve: u64,
    pub net_dns_resolve_server: u64,
    pub net_dhcp_acquire: u64,
    pub net_dhcp_renew: u64,
    pub net_dhcp_release: u64,
    pub net_dhcp_status: u64,
    pub net_detail_get: u64,
    pub net_diag_run: u64,
    pub ipc_open: u64,
    pub ipc_send: u64,
    pub ipc_recv: u64,
    pub ipc_poll: u64,
    pub ipc_close: u64,
    pub ipc_summary: u64,
    pub ipc_channel: u64,
    pub serial_link_status: u64,
    pub serial_link_poll: u64,
    pub serial_link_send_message: u64,
    pub serial_link_host_test: u64,
    pub serial_link_inbox: u64,
    pub net_service_request: u64,
    pub ipc_performance: u64,
    pub tcp_performance: u64,
}
impl Default for R4XStartR4Net2 { fn default() -> Self { Self { magic: 843402834, abi_version: 1, size: 296, flags: 0,
    tcp_connect: 0,
    tcp_write: 0,
    tcp_read: 0,
    tcp_close: 0,
    tcp_summary: 0,
    tcp_connection: 0,
    tcp_echo_listen_once: 0,
    tcp_accept_read_once: 0,
    net_ipv4_send: 0,
    net_ipv4_recv: 0,
    net_config_get: 0,
    net_config_set: 0,
    net_dns_resolve: 0,
    net_dns_resolve_server: 0,
    net_dhcp_acquire: 0,
    net_dhcp_renew: 0,
    net_dhcp_release: 0,
    net_dhcp_status: 0,
    net_detail_get: 0,
    net_diag_run: 0,
    ipc_open: 0,
    ipc_send: 0,
    ipc_recv: 0,
    ipc_poll: 0,
    ipc_close: 0,
    ipc_summary: 0,
    ipc_channel: 0,
    serial_link_status: 0,
    serial_link_poll: 0,
    serial_link_send_message: 0,
    serial_link_host_test: 0,
    serial_link_inbox: 0,
    net_service_request: 0,
    ipc_performance: 0,
    tcp_performance: 0,
} } }
const _: () = { assert!(core::mem::size_of::<R4XStartR4Net2>() == 296);
    assert!(core::mem::offset_of!(R4XStartR4Net2,tcp_connect) == 16);
    assert!(core::mem::offset_of!(R4XStartR4Net2,tcp_write) == 24);
    assert!(core::mem::offset_of!(R4XStartR4Net2,tcp_read) == 32);
    assert!(core::mem::offset_of!(R4XStartR4Net2,tcp_close) == 40);
    assert!(core::mem::offset_of!(R4XStartR4Net2,tcp_summary) == 48);
    assert!(core::mem::offset_of!(R4XStartR4Net2,tcp_connection) == 56);
    assert!(core::mem::offset_of!(R4XStartR4Net2,tcp_echo_listen_once) == 64);
    assert!(core::mem::offset_of!(R4XStartR4Net2,tcp_accept_read_once) == 72);
    assert!(core::mem::offset_of!(R4XStartR4Net2,net_ipv4_send) == 80);
    assert!(core::mem::offset_of!(R4XStartR4Net2,net_ipv4_recv) == 88);
    assert!(core::mem::offset_of!(R4XStartR4Net2,net_config_get) == 96);
    assert!(core::mem::offset_of!(R4XStartR4Net2,net_config_set) == 104);
    assert!(core::mem::offset_of!(R4XStartR4Net2,net_dns_resolve) == 112);
    assert!(core::mem::offset_of!(R4XStartR4Net2,net_dns_resolve_server) == 120);
    assert!(core::mem::offset_of!(R4XStartR4Net2,net_dhcp_acquire) == 128);
    assert!(core::mem::offset_of!(R4XStartR4Net2,net_dhcp_renew) == 136);
    assert!(core::mem::offset_of!(R4XStartR4Net2,net_dhcp_release) == 144);
    assert!(core::mem::offset_of!(R4XStartR4Net2,net_dhcp_status) == 152);
    assert!(core::mem::offset_of!(R4XStartR4Net2,net_detail_get) == 160);
    assert!(core::mem::offset_of!(R4XStartR4Net2,net_diag_run) == 168);
    assert!(core::mem::offset_of!(R4XStartR4Net2,ipc_open) == 176);
    assert!(core::mem::offset_of!(R4XStartR4Net2,ipc_send) == 184);
    assert!(core::mem::offset_of!(R4XStartR4Net2,ipc_recv) == 192);
    assert!(core::mem::offset_of!(R4XStartR4Net2,ipc_poll) == 200);
    assert!(core::mem::offset_of!(R4XStartR4Net2,ipc_close) == 208);
    assert!(core::mem::offset_of!(R4XStartR4Net2,ipc_summary) == 216);
    assert!(core::mem::offset_of!(R4XStartR4Net2,ipc_channel) == 224);
    assert!(core::mem::offset_of!(R4XStartR4Net2,serial_link_status) == 232);
    assert!(core::mem::offset_of!(R4XStartR4Net2,serial_link_poll) == 240);
    assert!(core::mem::offset_of!(R4XStartR4Net2,serial_link_send_message) == 248);
    assert!(core::mem::offset_of!(R4XStartR4Net2,serial_link_host_test) == 256);
    assert!(core::mem::offset_of!(R4XStartR4Net2,serial_link_inbox) == 264);
    assert!(core::mem::offset_of!(R4XStartR4Net2,net_service_request) == 272);
    assert!(core::mem::offset_of!(R4XStartR4Net2,ipc_performance) == 280);
    assert!(core::mem::offset_of!(R4XStartR4Net2,tcp_performance) == 288);
};
pub mod R4AudioFns2 {
    pub type audio_open_stream = unsafe extern "C" fn(u32, u16, u16) -> i32;
    pub type audio_write = unsafe extern "C" fn(u32, *const u8, u32) -> i32;
    pub type audio_close = unsafe extern "C" fn(u32) -> i32;
    pub type audio_set_volume = unsafe extern "C" fn(u32, u32) -> i32;
    pub type sid_acquire = unsafe extern "C" fn() -> i32;
    pub type sid_write_register = unsafe extern "C" fn(u32, u8, u8) -> i32;
    pub type sid_release = unsafe extern "C" fn(u32) -> i32;
    pub type sid_load_data = unsafe extern "C" fn(u32, u16, *const u8, u32) -> i32;
    pub type sid_init = unsafe extern "C" fn(u32, u16, u16) -> i32;
    pub type sid_play_frame = unsafe extern "C" fn(u32, u16, u16) -> i32;
    pub type sid_stop = unsafe extern "C" fn(u32) -> i32;
    pub type sid_model_name = unsafe extern "C" fn() -> *const u8;
    pub type midi_open_synth = unsafe extern "C" fn(*const u8) -> i32;
    pub type midi_send = unsafe extern "C" fn(u32, u8, u8, u8, u8) -> i32;
    pub type midi_close = unsafe extern "C" fn(u32) -> i32;
    pub type opl3_write_register = unsafe extern "C" fn(u8, u8, u8) -> i32;
    pub type opl3_reset = unsafe extern "C" fn() -> i32;
    pub type opl3_render_block = unsafe extern "C" fn() -> i32;
    pub type opl3_stop = unsafe extern "C" fn() -> i32;
    pub type audio_output_info = unsafe extern "C" fn(u32, *mut super::super::AudioOutputInfo) -> i32;
    pub type audio_select_output = unsafe extern "C" fn(*const [u8; 64]) -> i32;
    pub type audio_stream_progress = unsafe extern "C" fn(u32, u64, *mut super::super::AudioStreamProgress) -> i32;
    pub type audio_set_stream_expectation = unsafe extern "C" fn(u32, *const super::super::AudioStreamExpectation) -> i32;
    pub type audio_close_stream_progress = unsafe extern "C" fn(u32, u64, *mut super::super::AudioStreamProgress) -> i32;
    pub type audio_output_catalog = unsafe extern "C" fn(*mut super::super::AudioOutputInfo, u32, *mut super::super::AudioOutputCatalog) -> i32;
    pub type audio_capture_io = unsafe extern "C" fn(*const super::super::AudioCaptureRequest, *mut super::super::AudioCaptureReply, *mut u8, u32) -> i32;
}
pub const R4AUDIO_MAGIC: u32 = 844448082;
#[repr(C)]
#[derive(Clone, Copy)]
pub struct R4XStartR4Audio2 {
    pub magic: u32, pub abi_version: u32, pub size: u32, pub flags: u32,
    pub audio_open_stream: u64,
    pub audio_write: u64,
    pub audio_close: u64,
    pub audio_set_volume: u64,
    pub sid_acquire: u64,
    pub sid_write_register: u64,
    pub sid_release: u64,
    pub sid_load_data: u64,
    pub sid_init: u64,
    pub sid_play_frame: u64,
    pub sid_stop: u64,
    pub sid_model_name: u64,
    pub midi_open_synth: u64,
    pub midi_send: u64,
    pub midi_close: u64,
    pub opl3_write_register: u64,
    pub opl3_reset: u64,
    pub opl3_render_block: u64,
    pub opl3_stop: u64,
    pub reserved0: u64,
    pub reserved1: u64,
    pub audio_output_info: u64,
    pub audio_select_output: u64,
    pub audio_stream_progress: u64,
    pub audio_set_stream_expectation: u64,
    pub audio_close_stream_progress: u64,
    pub audio_output_catalog: u64,
    pub audio_capture_io: u64,
}
impl Default for R4XStartR4Audio2 { fn default() -> Self { Self { magic: 844448082, abi_version: 2, size: 240, flags: 0,
    audio_open_stream: 0,
    audio_write: 0,
    audio_close: 0,
    audio_set_volume: 0,
    sid_acquire: 0,
    sid_write_register: 0,
    sid_release: 0,
    sid_load_data: 0,
    sid_init: 0,
    sid_play_frame: 0,
    sid_stop: 0,
    sid_model_name: 0,
    midi_open_synth: 0,
    midi_send: 0,
    midi_close: 0,
    opl3_write_register: 0,
    opl3_reset: 0,
    opl3_render_block: 0,
    opl3_stop: 0,
    reserved0: 0,
    reserved1: 0,
    audio_output_info: 0,
    audio_select_output: 0,
    audio_stream_progress: 0,
    audio_set_stream_expectation: 0,
    audio_close_stream_progress: 0,
    audio_output_catalog: 0,
    audio_capture_io: 0,
} } }
const _: () = { assert!(core::mem::size_of::<R4XStartR4Audio2>() == 240);
    assert!(core::mem::offset_of!(R4XStartR4Audio2,audio_open_stream) == 16);
    assert!(core::mem::offset_of!(R4XStartR4Audio2,audio_write) == 24);
    assert!(core::mem::offset_of!(R4XStartR4Audio2,audio_close) == 32);
    assert!(core::mem::offset_of!(R4XStartR4Audio2,audio_set_volume) == 40);
    assert!(core::mem::offset_of!(R4XStartR4Audio2,sid_acquire) == 48);
    assert!(core::mem::offset_of!(R4XStartR4Audio2,sid_write_register) == 56);
    assert!(core::mem::offset_of!(R4XStartR4Audio2,sid_release) == 64);
    assert!(core::mem::offset_of!(R4XStartR4Audio2,sid_load_data) == 72);
    assert!(core::mem::offset_of!(R4XStartR4Audio2,sid_init) == 80);
    assert!(core::mem::offset_of!(R4XStartR4Audio2,sid_play_frame) == 88);
    assert!(core::mem::offset_of!(R4XStartR4Audio2,sid_stop) == 96);
    assert!(core::mem::offset_of!(R4XStartR4Audio2,sid_model_name) == 104);
    assert!(core::mem::offset_of!(R4XStartR4Audio2,midi_open_synth) == 112);
    assert!(core::mem::offset_of!(R4XStartR4Audio2,midi_send) == 120);
    assert!(core::mem::offset_of!(R4XStartR4Audio2,midi_close) == 128);
    assert!(core::mem::offset_of!(R4XStartR4Audio2,opl3_write_register) == 136);
    assert!(core::mem::offset_of!(R4XStartR4Audio2,opl3_reset) == 144);
    assert!(core::mem::offset_of!(R4XStartR4Audio2,opl3_render_block) == 152);
    assert!(core::mem::offset_of!(R4XStartR4Audio2,opl3_stop) == 160);
    assert!(core::mem::offset_of!(R4XStartR4Audio2,reserved0) == 168);
    assert!(core::mem::offset_of!(R4XStartR4Audio2,reserved1) == 176);
    assert!(core::mem::offset_of!(R4XStartR4Audio2,audio_output_info) == 184);
    assert!(core::mem::offset_of!(R4XStartR4Audio2,audio_select_output) == 192);
    assert!(core::mem::offset_of!(R4XStartR4Audio2,audio_stream_progress) == 200);
    assert!(core::mem::offset_of!(R4XStartR4Audio2,audio_set_stream_expectation) == 208);
    assert!(core::mem::offset_of!(R4XStartR4Audio2,audio_close_stream_progress) == 216);
    assert!(core::mem::offset_of!(R4XStartR4Audio2,audio_output_catalog) == 224);
    assert!(core::mem::offset_of!(R4XStartR4Audio2,audio_capture_io) == 232);
};
pub mod R4DevFns2 {
    pub type device_inventory_summary = unsafe extern "C" fn(*mut super::super::DeviceInventorySummary) -> i32;
    pub type device_inventory_record = unsafe extern "C" fn(u32, *mut super::super::DeviceInventoryRecord) -> i32;
    pub type memory_summary = unsafe extern "C" fn(*mut super::super::ProgramMemorySummary) -> i32;
    pub type memory_block_count = unsafe extern "C" fn() -> u32;
    pub type memory_block = unsafe extern "C" fn(u32, *mut super::super::ProgramMemoryBlockInfo) -> i32;
    pub type memory_pressure_snapshot = unsafe extern "C" fn(*mut super::super::ProgramMemoryPressureSnapshot) -> i32;
    pub type memory_reclaim_probe = unsafe extern "C" fn(u32, *mut super::super::ProgramMemoryReclaimProbe) -> i32;
    pub type memory_backing_store_probe = unsafe extern "C" fn(*const u8, u64, u32, *mut super::super::ProgramMemoryBackingStoreProbe) -> i32;
    pub type memory_backing_store_slot_probe = unsafe extern "C" fn(*const u8, u64, u32, u64, u32, u32, u32, u32, u32, *mut super::super::ProgramMemoryBackingStoreSlotProbe) -> i32;
    pub type memory_pager_gate_probe = unsafe extern "C" fn(*const u8, u64, u32, u64, u32, *mut super::super::ProgramMemoryPagerGateProbe) -> i32;
    pub type memory_page_io_probe = unsafe extern "C" fn(*const u8, u64, u32, u32, u64, u32, u64, u64, u32, u32, u64, *mut u8, u32, *mut super::super::ProgramMemoryPageIoProbe) -> i32;
    pub type memory_vm_page_state_probe = unsafe extern "C" fn(u32, u64, u64, u32, u32, u64, u64, u32, *mut super::super::ProgramMemoryVmPageStateProbe) -> i32;
    pub type memory_vm_reserve_probe = unsafe extern "C" fn(u64, *mut super::super::ProgramVmReserveProbe) -> i32;
    pub type paging_summary = unsafe extern "C" fn(*mut super::super::PagingSummary) -> i32;
    pub type performance_summary = unsafe extern "C" fn(*mut super::super::ProgramPerformanceSummary) -> i32;
    pub type performance_task = unsafe extern "C" fn(u32, *mut super::super::ProgramTaskPerformanceInfo) -> i32;
    pub type performance_storage = unsafe extern "C" fn(u32, *mut super::super::ProgramStoragePerformanceInfo) -> i32;
    pub type performance_boot_phase = unsafe extern "C" fn(u32, *mut super::super::ProgramBootPhasePerformanceInfo) -> i32;
    pub type protocol_status = unsafe extern "C" fn(*const u8, u32, *mut super::super::ProtocolStatus) -> i32;
    pub type protocol_dispatch = unsafe extern "C" fn(*const u8, u32, u32, *const super::super::ProtocolBuffer, *mut super::super::ProtocolBuffer) -> i32;
    pub type display_summary = unsafe extern "C" fn(*mut super::super::DisplaySummary) -> i32;
    pub type hardware_summary = unsafe extern "C" fn(*mut super::super::HardwareSummary) -> i32;
    pub type boot_info_summary = unsafe extern "C" fn(*mut super::super::BootInfoSummary) -> i32;
    pub type boot_info_memory_count = unsafe extern "C" fn() -> u32;
    pub type boot_info_memory_entry = unsafe extern "C" fn(u32, *mut super::super::BootInfoMemoryEntry) -> i32;
    pub type program_instance_storage_self_test = unsafe extern "C" fn(*mut super::super::ProgramInstanceStorageSelfTestResult) -> i32;
    pub type program_registry_summary_v2 = unsafe extern "C" fn(*mut super::super::ProgramRegistrySummaryV2) -> i32;
    pub type program_registry_self_test_v2 = unsafe extern "C" fn(*mut super::super::ProgramRegistrySelfTestResultV2) -> i32;
    pub type execution_inventory_summary = unsafe extern "C" fn(*mut super::super::ProgramInventorySummary) -> i32;
    pub type program_instance_storage_summary_v2 = unsafe extern "C" fn(*mut super::super::ProgramInstanceStorageSummary) -> i32;
    pub type kernel_version = unsafe extern "C" fn(*mut super::super::KernelVersion) -> i32;
    pub type performance_boot_phase_clock = unsafe extern "C" fn(u32, *mut super::super::ProgramBootPhaseClockInfo) -> i32;
    pub type performance_irq_timing = unsafe extern "C" fn(u32, *mut super::super::ProgramIrqTimingInfo) -> i32;
    pub type performance_boot_summary = unsafe extern "C" fn(*mut super::super::ProgramBootPerformanceInfo) -> i32;
    pub type performance_driver_work = unsafe extern "C" fn(u32, *mut super::super::ProgramDriverWorkPerformanceInfo) -> i32;
    pub type performance_pci_inventory = unsafe extern "C" fn(*mut super::super::ProgramPciInventoryPerformanceInfo) -> i32;
    pub type performance_input = unsafe extern "C" fn(*mut super::super::ProgramInputPerformanceInfo) -> i32;
    pub type display_state = unsafe extern "C" fn(*mut super::super::DisplayStateInfo) -> i32;
    pub type driver_module_info = unsafe extern "C" fn(u32, *mut super::super::DriverModuleInfo) -> i32;
    pub type performance_instrumentation = unsafe extern "C" fn(*mut super::super::ProgramInstrumentationInfo) -> i32;
    pub type performance_lock = unsafe extern "C" fn(u32, *mut super::super::ProgramLockPerformanceInfo) -> i32;
    pub type performance_stack = unsafe extern "C" fn(u32, *mut super::super::ProgramStackPerformanceInfo) -> i32;
    pub type stack_fault = unsafe extern "C" fn(u32, *mut super::super::ProgramStackFaultInfo) -> i32;
    pub type memory_kernel_heap_check = unsafe extern "C" fn(*mut super::super::ProgramKernelHeapCheck) -> i32;
    pub type scheduler_kernel_check = unsafe extern "C" fn(u32, *mut super::super::ProgramKernelSchedulerCheck) -> i32;
    pub type smp_kernel_check = unsafe extern "C" fn(*mut super::super::ProgramKernelSmpCheck) -> i32;
    pub type performance_smp_tlb = unsafe extern "C" fn(*mut super::super::ProgramSmpTlbSnapshot) -> i32;
    pub type storage_block_queue_check = unsafe extern "C" fn(*mut super::super::ProgramKernelBlockQueueCheck) -> i32;
    pub type storage_nvme_check = unsafe extern "C" fn(*mut super::super::ProgramKernelNvmeCheck) -> i32;
    pub type usb_contract_check = unsafe extern "C" fn(*mut super::super::ProgramKernelUsbCheck) -> i32;
    pub type serial_count = unsafe extern "C" fn() -> u32;
    pub type serial_port_at = unsafe extern "C" fn(u32, *mut super::super::SerialPortInfo) -> i32;
    pub type serial_open = unsafe extern "C" fn(u64, u64, *const super::super::SerialConfig, *mut u64) -> i32;
    pub type serial_configure = unsafe extern "C" fn(u64, *const super::super::SerialConfig) -> i32;
    pub type serial_read = unsafe extern "C" fn(u64, *mut u8, u32, u64, *mut super::super::SerialTransfer) -> i32;
    pub type serial_write = unsafe extern "C" fn(u64, *const u8, u32, u64, *mut super::super::SerialTransfer) -> i32;
    pub type serial_drain = unsafe extern "C" fn(u64, u64) -> i32;
    pub type serial_status = unsafe extern "C" fn(u64, *mut super::super::SerialStatus) -> i32;
    pub type serial_cancel = unsafe extern "C" fn(u64) -> i32;
    pub type serial_close = unsafe extern "C" fn(u64, u32, u64) -> i32;
    pub type cpu_topology = unsafe extern "C" fn(u32, *mut super::super::CpuTopologyInfo) -> i32;
    pub type cpu_cache_topology = unsafe extern "C" fn(u32, u32, *mut super::super::CpuCacheTopologyInfo) -> i32;
    pub type cpu_lifecycle = unsafe extern "C" fn(u32, u32, u64, *mut super::super::CpuLifecycleInfo) -> i32;
    pub type kernel_cpu_lifecycle_check = unsafe extern "C" fn(*mut super::super::ProgramKernelCpuLifecycleCheck) -> i32;
    pub type cpu_capabilities = unsafe extern "C" fn(u32, *mut super::super::CpuCapabilitiesInfo) -> i32;
    pub type cpu_feature = unsafe extern "C" fn(u32, u64, u32, *mut super::super::CpuFeatureInfo) -> i32;
    pub type cpu_register_read = unsafe extern "C" fn(u32, u64, u32, *mut super::super::CpuRegisterInfo) -> i32;
    pub type kernel_cpu_register_check = unsafe extern "C" fn(u32, u64, *mut super::super::ProgramKernelCpuRegisterCheck) -> i32;
    pub type cpu_power_info = unsafe extern "C" fn(u32, u64, *mut super::super::CpuPowerInfo) -> i32;
    pub type cpu_power_capture = unsafe extern "C" fn(u32, u64, *mut super::super::CpuPowerInfo) -> i32;
    pub type cpu_performance = unsafe extern "C" fn(*const super::super::CpuPerformanceRequest, *mut super::super::CpuPerformanceInfo) -> i32;
    pub type cpu_cppc = unsafe extern "C" fn(*const super::super::CpuPerformanceRequest, *mut super::super::CpuCppcInfo) -> i32;
    pub type cpu_performance_hint = unsafe extern "C" fn(u32, u64, *mut super::super::CpuPerformanceHintInfo) -> i32;
    pub type cpu_firmware_performance = unsafe extern "C" fn(*const super::super::CpuPerformanceRequest, *mut super::super::CpuFirmwareInfo) -> i32;
    pub type cpu_idle_info = unsafe extern "C" fn(u32, *mut super::super::CpuIdleInfo) -> i32;
    pub type cpu_machine_info = unsafe extern "C" fn(u32, *mut super::super::CpuMachineInfo) -> i32;
    pub type cpu_machine_bank = unsafe extern "C" fn(u32, u64, u64, u32, *mut super::super::CpuMachineBank) -> i32;
    pub type cpu_microcode_info = unsafe extern "C" fn(u32, *mut super::super::CpuMicrocodeInfo) -> i32;
    pub type cpu_pmu_info = unsafe extern "C" fn(u32, *mut super::super::CpuPmuInfo) -> i32;
    pub type cpu_pmu_measure = unsafe extern "C" fn(u32, u64, u32, u32, *const super::super::PmuWorkFn, u64, *mut super::super::CpuPmuResult) -> i32;
    pub type cpu_pmu_result = unsafe extern "C" fn(u32, u64, u64, *mut super::super::CpuPmuResult) -> i32;
    pub type cpu_acceleration_info = unsafe extern "C" fn(*mut super::super::CpuAccelerationInfo) -> i32;
    pub type cpu_acceleration_work = unsafe extern "C" fn(u32, u32, *const super::super::CpuPureWorkFn, u64, *mut super::super::CpuAccelerationWork) -> i32;
    pub type fpu_observation = unsafe extern "C" fn(*const super::super::FpuObservationRequest, *mut super::super::FpuObservationInfo) -> i32;
    pub type firmware_system_uuid = unsafe extern "C" fn(*mut super::super::FirmwareSystemUuidInfo) -> i32;
    pub type device_inventory_capture = unsafe extern "C" fn(*mut super::super::DeviceInventoryRecord, u32, *mut super::super::DeviceInventorySnapshotInfo) -> i32;
}
pub const R4DEV_MAGIC: u32 = 844514386;
#[repr(C)]
#[derive(Clone, Copy)]
pub struct R4XStartR4Dev2 {
    pub magic: u32, pub abi_version: u32, pub size: u32, pub flags: u32,
    pub device_inventory_summary: u64,
    pub device_inventory_record: u64,
    pub memory_summary: u64,
    pub memory_block_count: u64,
    pub memory_block: u64,
    pub memory_pressure_snapshot: u64,
    pub memory_reclaim_probe: u64,
    pub memory_backing_store_probe: u64,
    pub memory_backing_store_slot_probe: u64,
    pub memory_pager_gate_probe: u64,
    pub memory_page_io_probe: u64,
    pub memory_vm_page_state_probe: u64,
    pub memory_vm_reserve_probe: u64,
    pub paging_summary: u64,
    pub performance_summary: u64,
    pub performance_task: u64,
    pub performance_storage: u64,
    pub performance_boot_phase: u64,
    pub protocol_status: u64,
    pub protocol_dispatch: u64,
    pub display_summary: u64,
    pub hardware_summary: u64,
    pub boot_info_summary: u64,
    pub boot_info_memory_count: u64,
    pub boot_info_memory_entry: u64,
    pub reserved0: u64,
    pub reserved1: u64,
    pub program_instance_storage_self_test: u64,
    pub program_registry_summary_v2: u64,
    pub program_registry_self_test_v2: u64,
    pub execution_inventory_summary: u64,
    pub program_instance_storage_summary_v2: u64,
    pub kernel_version: u64,
    pub performance_boot_phase_clock: u64,
    pub performance_irq_timing: u64,
    pub performance_boot_summary: u64,
    pub performance_driver_work: u64,
    pub performance_pci_inventory: u64,
    pub performance_input: u64,
    pub display_state: u64,
    pub driver_module_info: u64,
    pub performance_instrumentation: u64,
    pub performance_lock: u64,
    pub performance_stack: u64,
    pub stack_fault: u64,
    pub memory_kernel_heap_check: u64,
    pub scheduler_kernel_check: u64,
    pub smp_kernel_check: u64,
    pub performance_smp_tlb: u64,
    pub storage_block_queue_check: u64,
    pub storage_nvme_check: u64,
    pub usb_contract_check: u64,
    pub serial_count: u64,
    pub serial_port_at: u64,
    pub serial_open: u64,
    pub serial_configure: u64,
    pub serial_read: u64,
    pub serial_write: u64,
    pub serial_drain: u64,
    pub serial_status: u64,
    pub serial_cancel: u64,
    pub serial_close: u64,
    pub cpu_topology: u64,
    pub cpu_cache_topology: u64,
    pub cpu_lifecycle: u64,
    pub kernel_cpu_lifecycle_check: u64,
    pub cpu_capabilities: u64,
    pub cpu_feature: u64,
    pub cpu_register_read: u64,
    pub kernel_cpu_register_check: u64,
    pub cpu_power_info: u64,
    pub cpu_power_capture: u64,
    pub cpu_performance: u64,
    pub cpu_cppc: u64,
    pub cpu_performance_hint: u64,
    pub cpu_firmware_performance: u64,
    pub cpu_idle_info: u64,
    pub cpu_machine_info: u64,
    pub cpu_machine_bank: u64,
    pub cpu_microcode_info: u64,
    pub cpu_pmu_info: u64,
    pub cpu_pmu_measure: u64,
    pub cpu_pmu_result: u64,
    pub cpu_acceleration_info: u64,
    pub cpu_acceleration_work: u64,
    pub fpu_observation: u64,
    pub firmware_system_uuid: u64,
    pub device_inventory_capture: u64,
}
impl Default for R4XStartR4Dev2 { fn default() -> Self { Self { magic: 844514386, abi_version: 2, size: 720, flags: 0,
    device_inventory_summary: 0,
    device_inventory_record: 0,
    memory_summary: 0,
    memory_block_count: 0,
    memory_block: 0,
    memory_pressure_snapshot: 0,
    memory_reclaim_probe: 0,
    memory_backing_store_probe: 0,
    memory_backing_store_slot_probe: 0,
    memory_pager_gate_probe: 0,
    memory_page_io_probe: 0,
    memory_vm_page_state_probe: 0,
    memory_vm_reserve_probe: 0,
    paging_summary: 0,
    performance_summary: 0,
    performance_task: 0,
    performance_storage: 0,
    performance_boot_phase: 0,
    protocol_status: 0,
    protocol_dispatch: 0,
    display_summary: 0,
    hardware_summary: 0,
    boot_info_summary: 0,
    boot_info_memory_count: 0,
    boot_info_memory_entry: 0,
    reserved0: 0,
    reserved1: 0,
    program_instance_storage_self_test: 0,
    program_registry_summary_v2: 0,
    program_registry_self_test_v2: 0,
    execution_inventory_summary: 0,
    program_instance_storage_summary_v2: 0,
    kernel_version: 0,
    performance_boot_phase_clock: 0,
    performance_irq_timing: 0,
    performance_boot_summary: 0,
    performance_driver_work: 0,
    performance_pci_inventory: 0,
    performance_input: 0,
    display_state: 0,
    driver_module_info: 0,
    performance_instrumentation: 0,
    performance_lock: 0,
    performance_stack: 0,
    stack_fault: 0,
    memory_kernel_heap_check: 0,
    scheduler_kernel_check: 0,
    smp_kernel_check: 0,
    performance_smp_tlb: 0,
    storage_block_queue_check: 0,
    storage_nvme_check: 0,
    usb_contract_check: 0,
    serial_count: 0,
    serial_port_at: 0,
    serial_open: 0,
    serial_configure: 0,
    serial_read: 0,
    serial_write: 0,
    serial_drain: 0,
    serial_status: 0,
    serial_cancel: 0,
    serial_close: 0,
    cpu_topology: 0,
    cpu_cache_topology: 0,
    cpu_lifecycle: 0,
    kernel_cpu_lifecycle_check: 0,
    cpu_capabilities: 0,
    cpu_feature: 0,
    cpu_register_read: 0,
    kernel_cpu_register_check: 0,
    cpu_power_info: 0,
    cpu_power_capture: 0,
    cpu_performance: 0,
    cpu_cppc: 0,
    cpu_performance_hint: 0,
    cpu_firmware_performance: 0,
    cpu_idle_info: 0,
    cpu_machine_info: 0,
    cpu_machine_bank: 0,
    cpu_microcode_info: 0,
    cpu_pmu_info: 0,
    cpu_pmu_measure: 0,
    cpu_pmu_result: 0,
    cpu_acceleration_info: 0,
    cpu_acceleration_work: 0,
    fpu_observation: 0,
    firmware_system_uuid: 0,
    device_inventory_capture: 0,
} } }
const _: () = { assert!(core::mem::size_of::<R4XStartR4Dev2>() == 720);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,device_inventory_summary) == 16);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,device_inventory_record) == 24);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,memory_summary) == 32);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,memory_block_count) == 40);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,memory_block) == 48);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,memory_pressure_snapshot) == 56);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,memory_reclaim_probe) == 64);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,memory_backing_store_probe) == 72);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,memory_backing_store_slot_probe) == 80);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,memory_pager_gate_probe) == 88);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,memory_page_io_probe) == 96);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,memory_vm_page_state_probe) == 104);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,memory_vm_reserve_probe) == 112);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,paging_summary) == 120);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,performance_summary) == 128);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,performance_task) == 136);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,performance_storage) == 144);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,performance_boot_phase) == 152);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,protocol_status) == 160);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,protocol_dispatch) == 168);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,display_summary) == 176);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,hardware_summary) == 184);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,boot_info_summary) == 192);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,boot_info_memory_count) == 200);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,boot_info_memory_entry) == 208);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,reserved0) == 216);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,reserved1) == 224);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,program_instance_storage_self_test) == 232);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,program_registry_summary_v2) == 240);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,program_registry_self_test_v2) == 248);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,execution_inventory_summary) == 256);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,program_instance_storage_summary_v2) == 264);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,kernel_version) == 272);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,performance_boot_phase_clock) == 280);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,performance_irq_timing) == 288);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,performance_boot_summary) == 296);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,performance_driver_work) == 304);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,performance_pci_inventory) == 312);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,performance_input) == 320);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,display_state) == 328);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,driver_module_info) == 336);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,performance_instrumentation) == 344);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,performance_lock) == 352);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,performance_stack) == 360);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,stack_fault) == 368);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,memory_kernel_heap_check) == 376);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,scheduler_kernel_check) == 384);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,smp_kernel_check) == 392);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,performance_smp_tlb) == 400);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,storage_block_queue_check) == 408);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,storage_nvme_check) == 416);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,usb_contract_check) == 424);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,serial_count) == 432);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,serial_port_at) == 440);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,serial_open) == 448);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,serial_configure) == 456);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,serial_read) == 464);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,serial_write) == 472);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,serial_drain) == 480);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,serial_status) == 488);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,serial_cancel) == 496);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,serial_close) == 504);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,cpu_topology) == 512);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,cpu_cache_topology) == 520);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,cpu_lifecycle) == 528);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,kernel_cpu_lifecycle_check) == 536);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,cpu_capabilities) == 544);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,cpu_feature) == 552);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,cpu_register_read) == 560);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,kernel_cpu_register_check) == 568);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,cpu_power_info) == 576);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,cpu_power_capture) == 584);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,cpu_performance) == 592);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,cpu_cppc) == 600);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,cpu_performance_hint) == 608);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,cpu_firmware_performance) == 616);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,cpu_idle_info) == 624);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,cpu_machine_info) == 632);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,cpu_machine_bank) == 640);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,cpu_microcode_info) == 648);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,cpu_pmu_info) == 656);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,cpu_pmu_measure) == 664);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,cpu_pmu_result) == 672);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,cpu_acceleration_info) == 680);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,cpu_acceleration_work) == 688);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,fpu_observation) == 696);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,firmware_system_uuid) == 704);
    assert!(core::mem::offset_of!(R4XStartR4Dev2,device_inventory_capture) == 712);
};
