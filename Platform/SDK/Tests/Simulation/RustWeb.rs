#![cfg(test)]
#[path = "WebCases.rs"]
mod cases;
#[test]
fn c_and_rust_share_layout_host_callbacks_exceptions_and_canvas() {
    let result = cases::c_and_layout();
    assert!(result.is_ok(), "{result:?}");
}
#[test]
fn current_document_form_font_image_and_activation_oracles() {
    cases::document_forms_fonts_images().unwrap();
}
#[test]
fn rust_realm_borrows_callbacks_and_preserves_gc_budget_and_errors() {
    cases::script_callbacks_and_budgets().unwrap();
}
#[test]
fn rust_canvas_and_background_match_exact_original_pixels() {
    cases::canvas_and_background().unwrap();
}
#[test]
fn original_web_runtime_executes_fixture_and_releases_its_exact_realm() {
    // The existing browser host dispatcher uses more than 2 MB of stack.
    // Match its original native owner runner; the other cases keep the normal
    // Rust test-thread stack. The bare guest uses real SDK stack probes.
    std::thread::Builder::new()
        .stack_size(8 * 1024 * 1024)
        .spawn(cases::runtime_document_lifecycle)
        .unwrap()
        .join()
        .unwrap()
        .unwrap();
}
