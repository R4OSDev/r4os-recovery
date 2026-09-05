# Plattformgruppe R4SYS

<!-- R4OS-APIREF:BEGIN R4SYS (generiert von ApiContractGen aus ApiContract.json - NICHT von Hand editieren) -->
## Tabellen-Referenz R4SYS (generiert)

Kernel-Gruppentabelle `R4XStartR4Sys` v16, 1144 Bytes, 138 Funktionsfelder und 141 Slots insgesamt.
Signatur-Wahrheit: `abi.R4SysFns` (Feldname == Tabellenfeld).
Ein Feld ist nutzbar, wenn `hasFn("feld")` es als vorhanden meldet.

| Slot | Offset | Zustand | Tabellenfeld | Signatur |
| ---: | ---: | --- | --- | --- |
| 0 | 16 | function | `write` | `*const fn ([*]const u8, u32) callconv(.c) i32` |
| 1 | 24 | function | `putc` | `*const fn (u8) callconv(.c) void` |
| 2 | 32 | function | `sleep_ticks` | `*const fn (u64) callconv(.c) void` |
| 3 | 40 | function | `ticks` | `*const fn () callconv(.c) u64` |
| 4 | 48 | function | `env_get` | `*const fn ([*:0]const u8, [*]u8, u32) callconv(.c) i32` |
| 5 | 56 | function | `dir_entry` | `*const fn ([*:0]const u8, u32, [*]u8, u32) callconv(.c) i32` |
| 6 | 64 | function | `program_should_close` | `*const fn () callconv(.c) u32` |
| 7 | 72 | function | `program_class` | `*const fn ([*:0]const u8, u32) callconv(.c) i32` |
| 8 | 80 | function | `program_instance` | `*const fn (u32, *ProgramInstanceInfo) callconv(.c) i32` |
| 9 | 88 | function | `service_status` | `*const fn ([*:0]const u8, *ServiceInfo) callconv(.c) i32` |
| 10 | 96 | function | `service_open` | `*const fn ([*:0]const u8, *ServiceInfo) callconv(.c) i32` |
| 11 | 104 | function | `service_close` | `*const fn (u32) callconv(.c) i32` |
| 12 | 112 | function | `service_call` | `*const fn (u32, u16, [*]const u8, u32, *ServiceMessageHeader, [*]u8, u32, u64) callconv(.c) i32` |
| 13 | 120 | function | `service_endpoint_register` | `*const fn ([*:0]const u8, u32, *ServiceInfo) callconv(.c) i32` |
| 14 | 128 | function | `service_endpoint_unregister` | `*const fn (u32) callconv(.c) i32` |
| 15 | 136 | function | `service_endpoint_poll` | `*const fn (u32) callconv(.c) i32` |
| 16 | 144 | function | `service_endpoint_recv` | `*const fn (u32, *ServiceMessageHeader, [*]u8, u32) callconv(.c) i32` |
| 17 | 152 | function | `service_endpoint_reply` | `*const fn (u32, u32, i32, [*]const u8, u32) callconv(.c) i32` |
| 18 | 160 | function | `service_detail_by_name` | `*const fn ([*:0]const u8, *ServiceDetail) callconv(.c) i32` |
| 19 | 168 | function | `service_start` | `*const fn ([*:0]const u8, *ServiceInfo) callconv(.c) i32` |
| 20 | 176 | function | `service_stop` | `*const fn ([*:0]const u8, *ServiceInfo, u64) callconv(.c) i32` |
| 21 | 184 | function | `service_restart` | `*const fn ([*:0]const u8, *ServiceInfo) callconv(.c) i32` |
| 22 | 192 | function | `service_install` | `*const fn ([*:0]const u8, [*:0]const u8, [*:0]const u8, u32, [*:0]const u8, *ServiceInfo) callconv(.c) i32` |
| 23 | 200 | function | `service_remove` | `*const fn ([*:0]const u8) callconv(.c) i32` |
| 24 | 208 | reserved | `reserved0` | - |
| 25 | 216 | reserved | `reserved1` | - |
| 26 | 224 | function | `vm_reserve` | `*const fn (u64, u64, u64, *ProgramVmRegionInfo) callconv(.c) i32` |
| 27 | 232 | function | `vm_commit` | `*const fn (u32, u64, u64, u64) callconv(.c) i32` |
| 28 | 240 | function | `vm_decommit` | `*const fn (u32, u64, u64) callconv(.c) i32` |
| 29 | 248 | function | `vm_release` | `*const fn (u32) callconv(.c) i32` |
| 30 | 256 | function | `vm_query` | `*const fn (u32, *ProgramVmRegionInfo) callconv(.c) i32` |
| 31 | 264 | function | `thread_create` | `*const fn (ThreadEntryFn, u64, u64, u32, *u32) callconv(.c) i32` |
| 32 | 272 | function | `thread_exit` | `*const fn (i32) callconv(.c) void` |
| 33 | 280 | function | `thread_join` | `*const fn (u32, u64, *i32) callconv(.c) i32` |
| 34 | 288 | function | `thread_current` | `*const fn () callconv(.c) u32` |
| 35 | 296 | function | `thread_status` | `*const fn (u32, *ProgramThreadInfo) callconv(.c) i32` |
| 36 | 304 | function | `io_file_read` | `*const fn ([*:0]const u8, [*]u8, u64, u32, *u32) callconv(.c) i32` |
| 37 | 312 | function | `io_file_read_at` | `*const fn ([*:0]const u8, u64, [*]u8, u64, u32, *u32) callconv(.c) i32` |
| 38 | 320 | function | `io_file_write` | `*const fn ([*:0]const u8, [*]const u8, u64, u32, *u32) callconv(.c) i32` |
| 39 | 328 | function | `io_file_append` | `*const fn ([*:0]const u8, [*]const u8, u64, u32, *u32) callconv(.c) i32` |
| 40 | 336 | function | `io_file_stream_begin` | `*const fn ([*:0]const u8, u32, *u32) callconv(.c) i32` |
| 41 | 344 | function | `io_file_stream_write` | `*const fn ([*:0]const u8, u64, [*]const u8, u64, u32, *u32) callconv(.c) i32` |
| 42 | 352 | function | `io_file_stream_finish` | `*const fn ([*:0]const u8, u64, u32, *u32) callconv(.c) i32` |
| 43 | 360 | function | `io_file_stream_abort` | `*const fn ([*:0]const u8, *u32) callconv(.c) i32` |
| 44 | 368 | function | `io_service_call` | `*const fn (u32, u16, [*]const u8, u32, *ServiceMessageHeader, [*]u8, u32, u64, u32, *u32) callconv(.c) i32` |
| 45 | 376 | function | `io_status` | `*const fn (u32, *ProgramIoInfo) callconv(.c) i32` |
| 46 | 384 | function | `io_wait` | `*const fn (u32, u64, *ProgramIoInfo) callconv(.c) i32` |
| 47 | 392 | function | `io_close` | `*const fn (u32) callconv(.c) i32` |
| 48 | 400 | function | `task_yield` | `*const fn () callconv(.c) void` |
| 49 | 408 | tombstone | `reserved_shell_run` | - |
| 50 | 416 | function | `system_halt` | `*const fn () callconv(.c) void` |
| 51 | 424 | function | `system_reboot` | `*const fn () callconv(.c) void` |
| 52 | 432 | function | `system_poweroff` | `*const fn () callconv(.c) void` |
| 53 | 440 | function | `time_state` | `*const fn (*TimeState) callconv(.c) void` |
| 54 | 448 | function | `time_set_state` | `*const fn (*const TimeState) callconv(.c) i32` |
| 55 | 456 | function | `time_seconds_since_midnight` | `*const fn () callconv(.c) u32` |
| 56 | 464 | function | `dir_list` | `*const fn ([*:0]const u8, [*]u8, u32) callconv(.c) i32` |
| 57 | 472 | function | `dir_create` | `*const fn ([*:0]const u8) callconv(.c) i32` |
| 58 | 480 | function | `dir_delete` | `*const fn ([*:0]const u8) callconv(.c) i32` |
| 59 | 488 | function | `drive_info` | `*const fn (u32, *DriveInfo) callconv(.c) i32` |
| 60 | 496 | function | `file_info` | `*const fn ([*:0]const u8, *FileInfo) callconv(.c) i32` |
| 61 | 504 | function | `file_delete` | `*const fn ([*:0]const u8) callconv(.c) i32` |
| 62 | 512 | function | `file_rename` | `*const fn ([*:0]const u8, [*:0]const u8) callconv(.c) i32` |
| 63 | 520 | function | `file_copy` | `*const fn ([*:0]const u8, [*:0]const u8) callconv(.c) i32` |
| 64 | 528 | function | `file_move` | `*const fn ([*:0]const u8, [*:0]const u8) callconv(.c) i32` |
| 65 | 536 | function | `file_read` | `*const fn ([*:0]const u8, [*]u8, u32) callconv(.c) i32` |
| 66 | 544 | function | `file_write` | `*const fn ([*:0]const u8, [*]const u8, u32) callconv(.c) i32` |
| 67 | 552 | function | `file_read_at` | `*const fn ([*:0]const u8, u32, [*]u8, u32) callconv(.c) i32` |
| 68 | 560 | function | `file_append` | `*const fn ([*:0]const u8, [*]const u8, u32) callconv(.c) i32` |
| 69 | 568 | function | `file_stream_begin` | `*const fn ([*:0]const u8, u32) callconv(.c) i32` |
| 70 | 576 | function | `file_stream_write` | `*const fn ([*:0]const u8, u64, [*]const u8, u32, u32) callconv(.c) i32` |
| 71 | 584 | function | `file_stream_finish` | `*const fn ([*:0]const u8, u64, u32) callconv(.c) i32` |
| 72 | 592 | function | `file_stream_abort` | `*const fn ([*:0]const u8) callconv(.c) i32` |
| 73 | 600 | function | `env_set` | `*const fn ([*:0]const u8, [*]const u8, u32) callconv(.c) i32` |
| 74 | 608 | function | `registry_key_info` | `*const fn ([*:0]const u8, *RegistryKeyInfo) callconv(.c) i32` |
| 75 | 616 | function | `registry_enum_key` | `*const fn ([*:0]const u8, u32, [*]u8, u32) callconv(.c) i32` |
| 76 | 624 | function | `registry_enum_value` | `*const fn ([*:0]const u8, u32, *RegistryValueInfo) callconv(.c) i32` |
| 77 | 632 | function | `registry_get_value` | `*const fn ([*:0]const u8, [*:0]const u8, *RegistryValueInfo, [*]u8, u32) callconv(.c) i32` |
| 78 | 640 | function | `registry_set_value` | `*const fn ([*:0]const u8, [*:0]const u8, u16, [*]const u8, u32) callconv(.c) i32` |
| 79 | 648 | function | `registry_delete_value` | `*const fn ([*:0]const u8, [*:0]const u8) callconv(.c) i32` |
| 80 | 656 | function | `service_info` | `*const fn (u32, *ServiceInfo) callconv(.c) i32` |
| 81 | 664 | function | `service_detail` | `*const fn (u32, *ServiceDetail) callconv(.c) i32` |
| 82 | 672 | function | `service_set_start_mode` | `*const fn ([*:0]const u8, u32, *ServiceInfo) callconv(.c) i32` |
| 83 | 680 | function | `service_endpoint_wait` | `*const fn (u32, u64) callconv(.c) i32` |
| 84 | 688 | function | `program_run` | `*const fn ([*:0]const u8, [*:0]const u8) callconv(.c) i32` |
| 85 | 696 | function | `program_launch` | `*const fn ([*:0]const u8, [*:0]const u8, u32) callconv(.c) i32` |
| 86 | 704 | function | `program_spawn` | `*const fn ([*:0]const u8, [*:0]const u8, u32) callconv(.c) i32` |
| 87 | 712 | function | `program_kill` | `*const fn (u32) callconv(.c) i32` |
| 88 | 720 | function | `program_status` | `*const fn (*ProgramStatus) callconv(.c) void` |
| 89 | 728 | function | `program_request_close` | `*const fn (u32) callconv(.c) i32` |
| 90 | 736 | function | `program_reap_instance` | `*const fn (u32) callconv(.c) i32` |
| 91 | 744 | function | `boot_log_info` | `*const fn (*BootLogInfo) callconv(.c) i32` |
| 92 | 752 | function | `boot_log_read` | `*const fn (u32, [*]u8, u32) callconv(.c) i32` |
| 93 | 760 | function | `program_spawn_handle` | `*const fn ([*:0]const u8, [*:0]const u8, u32, *ProgramProcessHandle) callconv(.c) i32` |
| 94 | 768 | function | `program_open_handle` | `*const fn (u32, *ProgramProcessHandle) callconv(.c) i32` |
| 95 | 776 | function | `program_handle_status` | `*const fn (*const ProgramProcessHandle, *ProgramInstanceInfo) callconv(.c) i32` |
| 96 | 784 | function | `program_handle_request_close` | `*const fn (*const ProgramProcessHandle) callconv(.c) i32` |
| 97 | 792 | function | `program_handle_kill` | `*const fn (*const ProgramProcessHandle) callconv(.c) i32` |
| 98 | 800 | function | `program_handle_wait` | `*const fn (*const ProgramProcessHandle, u64, *ProgramProcessCompletion) callconv(.c) i32` |
| 99 | 808 | function | `program_handle_reap` | `*const fn (*const ProgramProcessHandle, *ProgramProcessCompletion) callconv(.c) i32` |
| 100 | 816 | function | `program_completion_read` | `*const fn (*const ProgramProcessHandle, u32, [*]u8, u32, *u32) callconv(.c) i32` |
| 101 | 824 | function | `program_inventory_begin` | `*const fn (*ProgramInventoryCursor, *ProgramInventorySummary) callconv(.c) i32` |
| 102 | 832 | function | `program_inventory_programs` | `*const fn (*ProgramInventoryCursor, [*]ProgramInstanceSnapshot, u32, *ProgramInventoryPageInfo) callconv(.c) i32` |
| 103 | 840 | function | `program_inventory_tasks` | `*const fn (*ProgramInventoryCursor, [*]ProgramTaskSnapshot, u32, *ProgramInventoryPageInfo) callconv(.c) i32` |
| 104 | 848 | function | `program_inventory_threads` | `*const fn (*ProgramInventoryCursor, [*]ProgramThreadSnapshot, u32, *ProgramInventoryPageInfo) callconv(.c) i32` |
| 105 | 856 | function | `thread_create_handle` | `*const fn (ThreadEntryFn, u64, u64, u32, *ProgramJoinHandle) callconv(.c) i32` |
| 106 | 864 | function | `thread_handle_join` | `*const fn (*const ProgramJoinHandle, u64, *i32) callconv(.c) i32` |
| 107 | 872 | function | `thread_handle_status` | `*const fn (*const ProgramJoinHandle, *ProgramThreadInfo) callconv(.c) i32` |
| 108 | 880 | function | `file_replace_atomic` | `*const fn ([*:0]const u8, [*:0]const u8, [*:0]const u8, u32) callconv(.c) i32` |
| 109 | 888 | function | `file_delete_if_match` | `*const fn ([*:0]const u8, u64, u32) callconv(.c) i32` |
| 110 | 896 | function | `file_update_atomic_checked` | `*const fn ([*:0]const u8, [*:0]const u8, [*:0]const u8, u64, u32, u64, u32, u32) callconv(.c) i32` |
| 111 | 904 | function | `path_names_equal_collated` | `*const fn ([*:0]const u8, [*:0]const u8) callconv(.c) i32` |
| 112 | 912 | function | `file_update_cleanup_checked` | `*const fn ([*:0]const u8, [*:0]const u8, [*:0]const u8, [*:0]const u8, u64, u32, u64, u32, u64, u32, u32) callconv(.c) i32` |
| 113 | 920 | function | `file_stream_declare_publish` | `*const fn ([*:0]const u8, [*:0]const u8, [*:0]const u8, u32) callconv(.c) i32` |
| 114 | 928 | function | `module_resource_stat` | `*const fn ([*:0]const u8, u32, u32, ?[*:0]const u8) callconv(.c) i32` |
| 115 | 936 | function | `module_resource_read` | `*const fn ([*:0]const u8, u32, u32, ?[*:0]const u8, [*]u8, u32) callconv(.c) i32` |
| 116 | 944 | function | `program_module_path` | `*const fn ([*]u8, u32) callconv(.c) i32` |
| 117 | 952 | function | `program_module_running` | `*const fn ([*:0]const u8) callconv(.c) i32` |
| 118 | 960 | function | `monotonic_clock` | `*const fn (*MonotonicClockInfo) callconv(.c) i32` |
| 119 | 968 | function | `boot_ready` | `*const fn () callconv(.c) i32` |
| 120 | 976 | function | `registry_snapshot_begin` | `*const fn ([*:0]const u8, u32, *RegistrySnapshotCursor) callconv(.c) i32` |
| 121 | 984 | function | `registry_snapshot_page` | `*const fn (*RegistrySnapshotCursor, [*]RegistrySnapshotEntry, u32, [*]u8, u32, *RegistrySnapshotPageInfo) callconv(.c) i32` |
| 122 | 992 | function | `registry_batch_mutate` | `*const fn ([*]const RegistryBatchOperation, u32, [*]const u8, u32, *RegistryBatchResult) callconv(.c) i32` |
| 123 | 1000 | function | `io_file_write_at` | `*const fn ([*:0]const u8, u64, [*]const u8, u64, u32, *u32) callconv(.c) i32` |
| 124 | 1008 | function | `io_file_info` | `*const fn ([*:0]const u8, u32, *u32) callconv(.c) i32` |
| 125 | 1016 | function | `io_file_lock` | `*const fn ([*:0]const u8, u64, u64, u32, *u32) callconv(.c) i32` |
| 126 | 1024 | function | `storage_inventory` | `*const fn (*StorageInventory) callconv(.c) i32` |
| 127 | 1032 | function | `storage_device` | `*const fn (u64, u32, *StorageDeviceInfo) callconv(.c) i32` |
| 128 | 1040 | function | `storage_partition` | `*const fn (u64, *const StorageDeviceRef, u32, *StoragePartitionInfo) callconv(.c) i32` |
| 129 | 1048 | function | `storage_volume` | `*const fn (u64, u32, *StorageVolumeInfo) callconv(.c) i32` |
| 130 | 1056 | function | `storage_claim_begin` | `*const fn (*const StorageTarget, *u64) callconv(.c) i32` |
| 131 | 1064 | function | `storage_claim_end` | `*const fn (u64, u32) callconv(.c) i32` |
| 132 | 1072 | function | `storage_read` | `*const fn (*const StorageTarget, u64, u32, [*]u8, u32) callconv(.c) i32` |
| 133 | 1080 | function | `storage_claim_read` | `*const fn (u64, u64, u32, [*]u8, u32) callconv(.c) i32` |
| 134 | 1088 | function | `storage_claim_write` | `*const fn (u64, u64, u32, [*]const u8, u32) callconv(.c) i32` |
| 135 | 1096 | function | `storage_claim_flush` | `*const fn (u64) callconv(.c) i32` |
| 136 | 1104 | function | `storage_rescan` | `*const fn (*const StorageDeviceRef) callconv(.c) i32` |
| 137 | 1112 | function | `storage_mount` | `*const fn (*const StorageTarget, u32, *StorageVolumeRef) callconv(.c) i32` |
| 138 | 1120 | function | `storage_unmount` | `*const fn (*const StorageVolumeRef) callconv(.c) i32` |
| 139 | 1128 | function | `storage_use_begin` | `*const fn ([*:0]const u8, *u64) callconv(.c) i32` |
| 140 | 1136 | function | `storage_use_end` | `*const fn (u64) callconv(.c) i32` |
<!-- R4OS-APIREF:END R4SYS -->