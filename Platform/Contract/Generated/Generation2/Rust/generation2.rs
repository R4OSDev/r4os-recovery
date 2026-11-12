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
pub use super::R4SysFns as R4SysFns2;
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
impl R4XStartR4Sys2 {
    pub fn project_provider(source: &super::R4XStartR4Sys) -> Self { Self {
        write: source.write as u64,
        putc: source.putc as u64,
        sleep_ticks: source.sleep_ticks as u64,
        ticks: source.ticks as u64,
        env_get: source.env_get as u64,
        dir_entry: source.dir_entry as u64,
        program_should_close: source.program_should_close as u64,
        program_class: source.program_class as u64,
        program_instance: source.program_instance as u64,
        service_status: source.service_status as u64,
        service_open: source.service_open as u64,
        service_close: source.service_close as u64,
        service_call: source.service_call as u64,
        service_endpoint_register: source.service_endpoint_register as u64,
        service_endpoint_unregister: source.service_endpoint_unregister as u64,
        service_endpoint_poll: source.service_endpoint_poll as u64,
        service_endpoint_recv: source.service_endpoint_recv as u64,
        service_endpoint_reply: source.service_endpoint_reply as u64,
        service_detail_by_name: source.service_detail_by_name as u64,
        service_start: source.service_start as u64,
        service_stop: source.service_stop as u64,
        service_restart: source.service_restart as u64,
        service_install: source.service_install as u64,
        service_remove: source.service_remove as u64,
        vm_reserve: source.vm_reserve as u64,
        vm_commit: source.vm_commit as u64,
        vm_decommit: source.vm_decommit as u64,
        vm_release: source.vm_release as u64,
        vm_query: source.vm_query as u64,
        thread_create: source.thread_create as u64,
        thread_exit: source.thread_exit as u64,
        thread_join: source.thread_join as u64,
        thread_current: source.thread_current as u64,
        thread_status: source.thread_status as u64,
        io_file_read: source.io_file_read as u64,
        io_file_read_at: source.io_file_read_at as u64,
        io_file_write: source.io_file_write as u64,
        io_file_append: source.io_file_append as u64,
        io_file_stream_begin: source.io_file_stream_begin as u64,
        io_file_stream_write: source.io_file_stream_write as u64,
        io_file_stream_finish: source.io_file_stream_finish as u64,
        io_file_stream_abort: source.io_file_stream_abort as u64,
        io_service_call: source.io_service_call as u64,
        io_status: source.io_status as u64,
        io_wait: source.io_wait as u64,
        io_close: source.io_close as u64,
        task_yield: source.task_yield as u64,
        system_halt: source.system_halt as u64,
        system_reboot: source.system_reboot as u64,
        system_poweroff: source.system_poweroff as u64,
        time_state: source.time_state as u64,
        time_set_state: source.time_set_state as u64,
        time_seconds_since_midnight: source.time_seconds_since_midnight as u64,
        dir_list: source.dir_list as u64,
        dir_create: source.dir_create as u64,
        dir_delete: source.dir_delete as u64,
        drive_info: source.drive_info as u64,
        file_info: source.file_info as u64,
        file_delete: source.file_delete as u64,
        file_rename: source.file_rename as u64,
        file_copy: source.file_copy as u64,
        file_move: source.file_move as u64,
        file_read: source.file_read as u64,
        file_write: source.file_write as u64,
        file_read_at: source.file_read_at as u64,
        file_append: source.file_append as u64,
        file_stream_begin: source.file_stream_begin as u64,
        file_stream_write: source.file_stream_write as u64,
        file_stream_finish: source.file_stream_finish as u64,
        file_stream_abort: source.file_stream_abort as u64,
        env_set: source.env_set as u64,
        registry_key_info: source.registry_key_info as u64,
        registry_enum_key: source.registry_enum_key as u64,
        registry_enum_value: source.registry_enum_value as u64,
        registry_get_value: source.registry_get_value as u64,
        registry_set_value: source.registry_set_value as u64,
        registry_delete_value: source.registry_delete_value as u64,
        service_info: source.service_info as u64,
        service_detail: source.service_detail as u64,
        service_set_start_mode: source.service_set_start_mode as u64,
        service_endpoint_wait: source.service_endpoint_wait as u64,
        program_run: source.program_run as u64,
        program_launch: source.program_launch as u64,
        program_spawn: source.program_spawn as u64,
        program_kill: source.program_kill as u64,
        program_status: source.program_status as u64,
        program_request_close: source.program_request_close as u64,
        program_reap_instance: source.program_reap_instance as u64,
        boot_log_info: source.boot_log_info as u64,
        boot_log_read: source.boot_log_read as u64,
        program_spawn_handle: source.program_spawn_handle as u64,
        program_open_handle: source.program_open_handle as u64,
        program_handle_status: source.program_handle_status as u64,
        program_handle_request_close: source.program_handle_request_close as u64,
        program_handle_kill: source.program_handle_kill as u64,
        program_handle_wait: source.program_handle_wait as u64,
        program_handle_reap: source.program_handle_reap as u64,
        program_completion_read: source.program_completion_read as u64,
        program_inventory_begin: source.program_inventory_begin as u64,
        program_inventory_programs: source.program_inventory_programs as u64,
        program_inventory_tasks: source.program_inventory_tasks as u64,
        program_inventory_threads: source.program_inventory_threads as u64,
        thread_create_handle: source.thread_create_handle as u64,
        thread_handle_join: source.thread_handle_join as u64,
        thread_handle_status: source.thread_handle_status as u64,
        file_replace_atomic: source.file_replace_atomic as u64,
        file_delete_if_match: source.file_delete_if_match as u64,
        file_update_atomic_checked: source.file_update_atomic_checked as u64,
        path_names_equal_collated: source.path_names_equal_collated as u64,
        file_update_cleanup_checked: source.file_update_cleanup_checked as u64,
        file_stream_declare_publish: source.file_stream_declare_publish as u64,
        module_resource_stat: source.module_resource_stat as u64,
        module_resource_read: source.module_resource_read as u64,
        program_module_path: source.program_module_path as u64,
        program_module_running: source.program_module_running as u64,
        monotonic_clock: source.monotonic_clock as u64,
        boot_ready: source.boot_ready as u64,
        registry_snapshot_begin: source.registry_snapshot_begin as u64,
        registry_snapshot_page: source.registry_snapshot_page as u64,
        registry_batch_mutate: source.registry_batch_mutate as u64,
        io_file_write_at: source.io_file_write_at as u64,
        io_file_info: source.io_file_info as u64,
        io_file_lock: source.io_file_lock as u64,
        storage_inventory: source.storage_inventory as u64,
        storage_device: source.storage_device as u64,
        storage_partition: source.storage_partition as u64,
        storage_volume: source.storage_volume as u64,
        storage_claim_begin: source.storage_claim_begin as u64,
        storage_claim_end: source.storage_claim_end as u64,
        storage_read: source.storage_read as u64,
        storage_claim_read: source.storage_claim_read as u64,
        storage_claim_write: source.storage_claim_write as u64,
        storage_claim_flush: source.storage_claim_flush as u64,
        storage_rescan: source.storage_rescan as u64,
        storage_mount: source.storage_mount as u64,
        storage_unmount: source.storage_unmount as u64,
        storage_use_begin: source.storage_use_begin as u64,
        storage_use_end: source.storage_use_end as u64,
        directory_change_begin: source.directory_change_begin as u64,
        directory_change_poll: source.directory_change_poll as u64,
        file_copy_buffered: source.file_copy_buffered as u64,
        notification_create: source.notification_create as u64,
        notification_query: source.notification_query as u64,
        notification_notify: source.notification_notify as u64,
        notification_wait: source.notification_wait as u64,
        notification_close: source.notification_close as u64,
        program_local_get: source.program_local_get as u64,
        program_local_publish: source.program_local_publish as u64,
        thread_current_handle: source.thread_current_handle as u64,
        cpu_capacity: source.cpu_capacity as u64,
        program_exit: source.program_exit as u64,
        platform_input_snapshot: source.platform_input_snapshot as u64,
        directory_next: source.directory_next as u64,
        thread_placement_get: source.thread_placement_get as u64,
        thread_placement_set: source.thread_placement_set as u64,
        system_power_transition: source.system_power_transition as u64,
        entropy_source_info: source.entropy_source_info as u64,
        entropy_fill: source.entropy_fill as u64,
        program_lifecycle_begin: source.program_lifecycle_begin as u64,
        program_lifecycle_programs: source.program_lifecycle_programs as u64,
        drive_info_geometry: source.drive_info_geometry as u64,
        directory_batch: source.directory_batch as u64,
        program_observation_retain: source.program_observation_retain as u64,
        program_observation_wait: source.program_observation_wait as u64,
        program_observation_read: source.program_observation_read as u64,
        program_observation_release: source.program_observation_release as u64,
        file_name_limits: source.file_name_limits as u64,
        service_bound_detail: source.service_bound_detail as u64,
        service_stop_bound: source.service_stop_bound as u64,
        service_inventory_page: source.service_inventory_page as u64,
        service_control_bound: source.service_control_bound as u64,
        system_update_target_supported: source.system_update_target_supported as u64,
        file_metadata2: source.file_metadata2 as u64,
        directory_metadata_batch2: source.directory_metadata_batch2 as u64,
        waitset_create: source.waitset_create as u64,
        waitset_enroll: source.waitset_enroll as u64,
        waitset_rearm: source.waitset_rearm as u64,
        waitset_remove: source.waitset_remove as u64,
        waitset_wait: source.waitset_wait as u64,
        waitset_close: source.waitset_close as u64,
        waitset_source_prepare: source.waitset_source_prepare as u64,
        byte_pipe_create: source.byte_pipe_create as u64,
        byte_pipe_dup: source.byte_pipe_dup as u64,
        byte_pipe_read: source.byte_pipe_read as u64,
        byte_pipe_write: source.byte_pipe_write as u64,
        byte_pipe_cancel: source.byte_pipe_cancel as u64,
        byte_pipe_close: source.byte_pipe_close as u64,
        byte_pipe_info: source.byte_pipe_info as u64,
        program_launch_io: source.program_launch_io as u64,
        program_stdio: source.program_stdio as u64,
        ..Self::default()
    } }
}
pub use super::R4DeskFns as R4DeskFns2;
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
impl R4XStartR4Desk2 {
    pub fn project_provider(source: &super::R4XStartR4Desk) -> Self { Self {
        read_key: source.read_key as u64,
        mouse_state: source.mouse_state as u64,
        mouse_show: source.mouse_show as u64,
        mouse_hide: source.mouse_hide as u64,
        keyboard_layout_current: source.keyboard_layout_current as u64,
        keyboard_layout_at: source.keyboard_layout_at as u64,
        keyboard_layout_set: source.keyboard_layout_set as u64,
        program_set_window: source.program_set_window as u64,
        program_set_console_host: source.program_set_console_host as u64,
        program_request_host_launch: source.program_request_host_launch as u64,
        program_take_host_launch: source.program_take_host_launch as u64,
        program_window_id: source.program_window_id as u64,
        gui_window_info: source.gui_window_info as u64,
        gui_set_window_info: source.gui_set_window_info as u64,
        gui_poll_event: source.gui_poll_event as u64,
        gui_push_event: source.gui_push_event as u64,
        gui_set_text: source.gui_set_text as u64,
        gui_text: source.gui_text as u64,
        gui_revision: source.gui_revision as u64,
        gui_command: source.gui_command as u64,
        gui_set_title: source.gui_set_title as u64,
        gui_title: source.gui_title as u64,
        gui_set_min_size: source.gui_set_min_size as u64,
        gui_min_size: source.gui_min_size as u64,
        console_output: source.console_output as u64,
        console_revision: source.console_revision as u64,
        console_state: source.console_state as u64,
        console_set_metrics: source.console_set_metrics as u64,
        console_push_key: source.console_push_key as u64,
        console_write: source.console_write as u64,
        console_read: source.console_read as u64,
        clipboard_write: source.clipboard_write as u64,
        clipboard_read: source.clipboard_read as u64,
        clipboard_revision: source.clipboard_revision as u64,
        clipboard_info: source.clipboard_info as u64,
        clipboard_clear: source.clipboard_clear as u64,
        read_key_codepoint: source.read_key_codepoint as u64,
        remote_frame_info: source.remote_frame_info as u64,
        remote_frame_read: source.remote_frame_read as u64,
        remote_frame_wait: source.remote_frame_wait as u64,
        remote_frame_publish: source.remote_frame_publish as u64,
        remote_input_push: source.remote_input_push as u64,
        remote_input_poll: source.remote_input_poll as u64,
        remote_input_status: source.remote_input_status as u64,
        desktop_activity_wait: source.desktop_activity_wait as u64,
        remote_frame_map: source.remote_frame_map as u64,
        program_current_console_host: source.program_current_console_host as u64,
        program_request_desktop: source.program_request_desktop as u64,
        program_spawn_with_console_host: source.program_spawn_with_console_host as u64,
        program_spawn_with_console_host_handle: source.program_spawn_with_console_host_handle as u64,
        program_set_window_handle: source.program_set_window_handle as u64,
        console_push_input: source.console_push_input as u64,
        remote_frame_acquire: source.remote_frame_acquire as u64,
        remote_frame_release: source.remote_frame_release as u64,
        remote_frame_consumers: source.remote_frame_consumers as u64,
        remote_frame_publish_regions: source.remote_frame_publish_regions as u64,
        console_input_wait: source.console_input_wait as u64,
        physical_key_poll: source.physical_key_poll as u64,
        mouse_motion: source.mouse_motion as u64,
        remote_frame_snapshot_acquire: source.remote_frame_snapshot_acquire as u64,
        remote_frame_snapshot_release: source.remote_frame_snapshot_release as u64,
        remote_frame_source_reset: source.remote_frame_source_reset as u64,
        remote_frame_capture_stats: source.remote_frame_capture_stats as u64,
        desktop_activity_notify: source.desktop_activity_notify as u64,
        console_read_events: source.console_read_events as u64,
        console_push_events: source.console_push_events as u64,
        console_text_info: source.console_text_info as u64,
        console_set_encoding: source.console_set_encoding as u64,
        gui_activity_wait: source.gui_activity_wait as u64,
        gui_activity_notify: source.gui_activity_notify as u64,
        gui_pointer_capture_info: source.gui_pointer_capture_info as u64,
        gui_pointer_capture_acquire: source.gui_pointer_capture_acquire as u64,
        gui_pointer_capture_release: source.gui_pointer_capture_release as u64,
        gui_pointer_capture_host: source.gui_pointer_capture_host as u64,
        gui_host_input: source.gui_host_input as u64,
        gui_window_appearance: source.gui_window_appearance as u64,
        ..Self::default()
    } }
}
pub use super::R4DrawFns as R4DrawFns2;
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
impl R4XStartR4Draw2 {
    pub fn project_provider(source: &super::R4XStartR4Draw) -> Self { Self {
        screen_width: source.screen_width as u64,
        screen_height: source.screen_height as u64,
        clear: source.clear as u64,
        rect: source.rect as u64,
        text: source.text as u64,
        display_revision: source.display_revision as u64,
        display_begin_frame: source.display_begin_frame as u64,
        display_begin_frame_rect: source.display_begin_frame_rect as u64,
        display_present: source.display_present as u64,
        display_blit_xrgb32: source.display_blit_xrgb32 as u64,
        gui_clear: source.gui_clear as u64,
        gui_rect: source.gui_rect as u64,
        gui_draw_text: source.gui_draw_text as u64,
        gui_draw_text_ex: source.gui_draw_text_ex as u64,
        gui_blit: source.gui_blit as u64,
        gui_raster_read: source.gui_raster_read as u64,
        gui_present: source.gui_present as u64,
        font_count: source.font_count as u64,
        font_info: source.font_info as u64,
        font_measure: source.font_measure as u64,
        gui_set_font: source.gui_set_font as u64,
        gui_font: source.gui_font as u64,
        text_font: source.text_font as u64,
        font_reload: source.font_reload as u64,
        font_glyph_row: source.font_glyph_row as u64,
        gui_blend_alpha8: source.gui_blend_alpha8 as u64,
        gui_frame_begin: source.gui_frame_begin as u64,
        gui_frame_append: source.gui_frame_append as u64,
        gui_frame_commit: source.gui_frame_commit as u64,
        gui_frame_cancel: source.gui_frame_cancel as u64,
        gui_frame_info: source.gui_frame_info as u64,
        gui_frame_read: source.gui_frame_read as u64,
        display_blit_xrgb32_stride: source.display_blit_xrgb32_stride as u64,
        display_present_regions: source.display_present_regions as u64,
        display_present_capabilities: source.display_present_capabilities as u64,
        display_present_completion: source.display_present_completion as u64,
        gui_frame_begin_damage: source.gui_frame_begin_damage as u64,
        gui_frame_generation_info: source.gui_frame_generation_info as u64,
        gui_frame_generation_read: source.gui_frame_generation_read as u64,
        font_glyph_bitmap: source.font_glyph_bitmap as u64,
        font_revision: source.font_revision as u64,
        gui_frame_begin_replace: source.gui_frame_begin_replace as u64,
        gui_frame_stream_info: source.gui_frame_stream_info as u64,
        gui_shared_raster_create: source.gui_shared_raster_create as u64,
        gui_shared_raster_destroy: source.gui_shared_raster_destroy as u64,
        gui_shared_raster_map_write: source.gui_shared_raster_map_write as u64,
        gui_shared_raster_publish: source.gui_shared_raster_publish as u64,
        gui_shared_raster_acquire: source.gui_shared_raster_acquire as u64,
        gui_shared_raster_release: source.gui_shared_raster_release as u64,
        gfx_buffer_create: source.gfx_buffer_create as u64,
        gfx_buffer_describe: source.gfx_buffer_describe as u64,
        gfx_buffer_import: source.gfx_buffer_import as u64,
        gfx_buffer_release: source.gfx_buffer_release as u64,
        gfx_buffer_map: source.gfx_buffer_map as u64,
        gfx_buffer_unmap: source.gfx_buffer_unmap as u64,
        gfx_buffer_export_raster: source.gfx_buffer_export_raster as u64,
        gfx_buffer_stats: source.gfx_buffer_stats as u64,
        gfx_queue_open: source.gfx_queue_open as u64,
        gfx_queue_close: source.gfx_queue_close as u64,
        gfx_queue_submit: source.gfx_queue_submit as u64,
        gfx_fence_query: source.gfx_fence_query as u64,
        gfx_fence_wait: source.gfx_fence_wait as u64,
        gfx_fence_cancel: source.gfx_fence_cancel as u64,
        gfx_fence_release: source.gfx_fence_release as u64,
        gfx_queue_backend: source.gfx_queue_backend as u64,
        gfx_output_revision: source.gfx_output_revision as u64,
        gfx_output_info: source.gfx_output_info as u64,
        gfx_output_mode: source.gfx_output_mode as u64,
        gfx_output_edid: source.gfx_output_edid as u64,
        gfx_atomic_test: source.gfx_atomic_test as u64,
        gfx_atomic_commit: source.gfx_atomic_commit as u64,
        gfx_atomic_submit: source.gfx_atomic_submit as u64,
        gfx_atomic_status: source.gfx_atomic_status as u64,
        gfx_atomic_resolve: source.gfx_atomic_resolve as u64,
        display_presentation_stats: source.display_presentation_stats as u64,
        display_cursor_info: source.display_cursor_info as u64,
        display_cursor_submit: source.display_cursor_submit as u64,
        display_cursor_status: source.display_cursor_status as u64,
        gfx_queue_backend_info: source.gfx_queue_backend_info as u64,
        gfx_native_start: source.gfx_native_start as u64,
        gfx_native_query: source.gfx_native_query as u64,
        gfx_native_receive: source.gfx_native_receive as u64,
        gfx_native_close: source.gfx_native_close as u64,
        gfx_native_wait: source.gfx_native_wait as u64,
        gfx_queue_submit_render_list: source.gfx_queue_submit_render_list as u64,
        display_presentation_info: source.display_presentation_info as u64,
        display_presentation_feedback: source.display_presentation_feedback as u64,
        display_output_target: source.display_output_target as u64,
        gfx_queue_submit_output: source.gfx_queue_submit_output as u64,
        display_output_presentation_info: source.display_output_presentation_info as u64,
        display_output_presentation_feedback: source.display_output_presentation_feedback as u64,
        gfx_queue_submit_render_grid_list: source.gfx_queue_submit_render_grid_list as u64,
        gfx_output_color: source.gfx_output_color as u64,
        gfx_queue_submit_render_color_list: source.gfx_queue_submit_render_color_list as u64,
        gfx_atomic_test_color: source.gfx_atomic_test_color as u64,
        gfx_atomic_submit_color: source.gfx_atomic_submit_color as u64,
        gfx_output_refresh: source.gfx_output_refresh as u64,
        gfx_refresh_request: source.gfx_refresh_request as u64,
        gfx_memory_budget: source.gfx_memory_budget as u64,
        gfx_telemetry: source.gfx_telemetry as u64,
        gfx_output_power: source.gfx_output_power as u64,
        gfx_power_request: source.gfx_power_request as u64,
        gfx_virtual_start: source.gfx_virtual_start as u64,
        gfx_virtual_query: source.gfx_virtual_query as u64,
        gfx_virtual_close: source.gfx_virtual_close as u64,
        gfx_virtual_wait: source.gfx_virtual_wait as u64,
        gfx_buffer_map_persistent: source.gfx_buffer_map_persistent as u64,
        gfx_queue_backend_properties: source.gfx_queue_backend_properties as u64,
        gfx_queue_submit_native: source.gfx_queue_submit_native as u64,
        gfx_queue_submit_render_color_grid_list: source.gfx_queue_submit_render_color_grid_list as u64,
        gfx_output_brightness: source.gfx_output_brightness as u64,
        gfx_brightness_request: source.gfx_brightness_request as u64,
        font_prefix_metrics2: source.font_prefix_metrics2 as u64,
        ..Self::default()
    } }
}
pub use super::R4NetFns as R4NetFns2;
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
impl R4XStartR4Net2 {
    pub fn project_provider(source: &super::R4XStartR4Net) -> Self { Self {
        tcp_connect: source.tcp_connect as u64,
        tcp_write: source.tcp_write as u64,
        tcp_read: source.tcp_read as u64,
        tcp_close: source.tcp_close as u64,
        tcp_summary: source.tcp_summary as u64,
        tcp_connection: source.tcp_connection as u64,
        tcp_echo_listen_once: source.tcp_echo_listen_once as u64,
        tcp_accept_read_once: source.tcp_accept_read_once as u64,
        net_ipv4_send: source.net_ipv4_send as u64,
        net_ipv4_recv: source.net_ipv4_recv as u64,
        net_config_get: source.net_config_get as u64,
        net_config_set: source.net_config_set as u64,
        net_dns_resolve: source.net_dns_resolve as u64,
        net_dns_resolve_server: source.net_dns_resolve_server as u64,
        net_dhcp_acquire: source.net_dhcp_acquire as u64,
        net_dhcp_renew: source.net_dhcp_renew as u64,
        net_dhcp_release: source.net_dhcp_release as u64,
        net_dhcp_status: source.net_dhcp_status as u64,
        net_detail_get: source.net_detail_get as u64,
        net_diag_run: source.net_diag_run as u64,
        ipc_open: source.ipc_open as u64,
        ipc_send: source.ipc_send as u64,
        ipc_recv: source.ipc_recv as u64,
        ipc_poll: source.ipc_poll as u64,
        ipc_close: source.ipc_close as u64,
        ipc_summary: source.ipc_summary as u64,
        ipc_channel: source.ipc_channel as u64,
        serial_link_status: source.serial_link_status as u64,
        serial_link_poll: source.serial_link_poll as u64,
        serial_link_send_message: source.serial_link_send_message as u64,
        serial_link_host_test: source.serial_link_host_test as u64,
        serial_link_inbox: source.serial_link_inbox as u64,
        net_service_request: source.net_service_request as u64,
        ipc_performance: source.ipc_performance as u64,
        tcp_performance: source.tcp_performance as u64,
        ..Self::default()
    } }
}
pub use super::R4AudioFns as R4AudioFns2;
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
impl R4XStartR4Audio2 {
    pub fn project_provider(source: &super::R4XStartR4Audio) -> Self { Self {
        audio_open_stream: source.audio_open_stream as u64,
        audio_write: source.audio_write as u64,
        audio_close: source.audio_close as u64,
        audio_set_volume: source.audio_set_volume as u64,
        sid_acquire: source.sid_acquire as u64,
        sid_write_register: source.sid_write_register as u64,
        sid_release: source.sid_release as u64,
        sid_load_data: source.sid_load_data as u64,
        sid_init: source.sid_init as u64,
        sid_play_frame: source.sid_play_frame as u64,
        sid_stop: source.sid_stop as u64,
        sid_model_name: source.sid_model_name as u64,
        midi_open_synth: source.midi_open_synth as u64,
        midi_send: source.midi_send as u64,
        midi_close: source.midi_close as u64,
        opl3_write_register: source.opl3_write_register as u64,
        opl3_reset: source.opl3_reset as u64,
        opl3_render_block: source.opl3_render_block as u64,
        opl3_stop: source.opl3_stop as u64,
        audio_output_info: source.audio_output_info as u64,
        audio_select_output: source.audio_select_output as u64,
        audio_stream_progress: source.audio_stream_progress as u64,
        audio_set_stream_expectation: source.audio_set_stream_expectation as u64,
        audio_close_stream_progress: source.audio_close_stream_progress as u64,
        audio_output_catalog: source.audio_output_catalog as u64,
        audio_capture_io: source.audio_capture_io as u64,
        ..Self::default()
    } }
}
pub use super::R4DevFns as R4DevFns2;
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
impl R4XStartR4Dev2 {
    pub fn project_provider(source: &super::R4XStartR4Dev) -> Self { Self {
        device_inventory_summary: source.device_inventory_summary as u64,
        device_inventory_record: source.device_inventory_record as u64,
        memory_summary: source.memory_summary as u64,
        memory_block_count: source.memory_block_count as u64,
        memory_block: source.memory_block as u64,
        memory_pressure_snapshot: source.memory_pressure_snapshot as u64,
        memory_reclaim_probe: source.memory_reclaim_probe as u64,
        memory_backing_store_probe: source.memory_backing_store_probe as u64,
        memory_backing_store_slot_probe: source.memory_backing_store_slot_probe as u64,
        memory_pager_gate_probe: source.memory_pager_gate_probe as u64,
        memory_page_io_probe: source.memory_page_io_probe as u64,
        memory_vm_page_state_probe: source.memory_vm_page_state_probe as u64,
        memory_vm_reserve_probe: source.memory_vm_reserve_probe as u64,
        paging_summary: source.paging_summary as u64,
        performance_summary: source.performance_summary as u64,
        performance_task: source.performance_task as u64,
        performance_storage: source.performance_storage as u64,
        performance_boot_phase: source.performance_boot_phase as u64,
        protocol_status: source.protocol_status as u64,
        protocol_dispatch: source.protocol_dispatch as u64,
        display_summary: source.display_summary as u64,
        hardware_summary: source.hardware_summary as u64,
        boot_info_summary: source.boot_info_summary as u64,
        boot_info_memory_count: source.boot_info_memory_count as u64,
        boot_info_memory_entry: source.boot_info_memory_entry as u64,
        program_instance_storage_self_test: source.program_instance_storage_self_test as u64,
        program_registry_summary_v2: source.program_registry_summary_v2 as u64,
        program_registry_self_test_v2: source.program_registry_self_test_v2 as u64,
        execution_inventory_summary: source.execution_inventory_summary as u64,
        program_instance_storage_summary_v2: source.program_instance_storage_summary_v2 as u64,
        kernel_version: source.kernel_version as u64,
        performance_boot_phase_clock: source.performance_boot_phase_clock as u64,
        performance_irq_timing: source.performance_irq_timing as u64,
        performance_boot_summary: source.performance_boot_summary as u64,
        performance_driver_work: source.performance_driver_work as u64,
        performance_pci_inventory: source.performance_pci_inventory as u64,
        performance_input: source.performance_input as u64,
        display_state: source.display_state as u64,
        driver_module_info: source.driver_module_info as u64,
        performance_instrumentation: source.performance_instrumentation as u64,
        performance_lock: source.performance_lock as u64,
        performance_stack: source.performance_stack as u64,
        stack_fault: source.stack_fault as u64,
        memory_kernel_heap_check: source.memory_kernel_heap_check as u64,
        scheduler_kernel_check: source.scheduler_kernel_check as u64,
        smp_kernel_check: source.smp_kernel_check as u64,
        performance_smp_tlb: source.performance_smp_tlb as u64,
        storage_block_queue_check: source.storage_block_queue_check as u64,
        storage_nvme_check: source.storage_nvme_check as u64,
        usb_contract_check: source.usb_contract_check as u64,
        serial_count: source.serial_count as u64,
        serial_port_at: source.serial_port_at as u64,
        serial_open: source.serial_open as u64,
        serial_configure: source.serial_configure as u64,
        serial_read: source.serial_read as u64,
        serial_write: source.serial_write as u64,
        serial_drain: source.serial_drain as u64,
        serial_status: source.serial_status as u64,
        serial_cancel: source.serial_cancel as u64,
        serial_close: source.serial_close as u64,
        cpu_topology: source.cpu_topology as u64,
        cpu_cache_topology: source.cpu_cache_topology as u64,
        cpu_lifecycle: source.cpu_lifecycle as u64,
        kernel_cpu_lifecycle_check: source.kernel_cpu_lifecycle_check as u64,
        cpu_capabilities: source.cpu_capabilities as u64,
        cpu_feature: source.cpu_feature as u64,
        cpu_register_read: source.cpu_register_read as u64,
        kernel_cpu_register_check: source.kernel_cpu_register_check as u64,
        cpu_power_info: source.cpu_power_info as u64,
        cpu_power_capture: source.cpu_power_capture as u64,
        cpu_performance: source.cpu_performance as u64,
        cpu_cppc: source.cpu_cppc as u64,
        cpu_performance_hint: source.cpu_performance_hint as u64,
        cpu_firmware_performance: source.cpu_firmware_performance as u64,
        cpu_idle_info: source.cpu_idle_info as u64,
        cpu_machine_info: source.cpu_machine_info as u64,
        cpu_machine_bank: source.cpu_machine_bank as u64,
        cpu_microcode_info: source.cpu_microcode_info as u64,
        cpu_pmu_info: source.cpu_pmu_info as u64,
        cpu_pmu_measure: source.cpu_pmu_measure as u64,
        cpu_pmu_result: source.cpu_pmu_result as u64,
        cpu_acceleration_info: source.cpu_acceleration_info as u64,
        cpu_acceleration_work: source.cpu_acceleration_work as u64,
        fpu_observation: source.fpu_observation as u64,
        firmware_system_uuid: source.firmware_system_uuid as u64,
        device_inventory_capture: source.device_inventory_capture as u64,
        ..Self::default()
    } }
}
