#![cfg(test)]
#[path = "SubsystemCases.rs"]
mod cases;
#[path = "PublishedFrame.rs"]
mod published_frame26;
#[test]
fn clock_and_launch() {
    cases::clock_launch().unwrap();
}
#[test]
fn same_runtime_work_pause_reset_close() {
    cases::runtime().unwrap();
}
#[test]
fn refused_callback_has_no_uninitialized_guard() {
    cases::refused_driver().unwrap();
}
#[test]
fn same_video_damage_resize_raster() {
    cases::video().unwrap();
}
#[test]
fn catalogue_resolver_and_exact_host_callback() {
    cases::catalogue().unwrap();
}
#[test]
fn audio_error_keeps_guest_time_video_and_one_close() {
    cases::audio_failure().unwrap();
}
