const std = @import("std");
const css = @import("css.zig");
const html = @import("html.zig");
const http = @import("http.zig");
const javascript = @import("javascript.zig");
const navigation = @import("web_navigation.zig");
const security = @import("web_security.zig");
const web_url = @import("web_url.zig");
const web_encoding = @import("web_encoding.zig");
const web_fetch = @import("web_fetch.zig");
const web_images = @import("web_images.zig");
const web_fonts = @import("web_fonts.zig");
const web_font_cache = @import("web_font_cache.zig");
const web_resources = @import("web_resources.zig");
const web_crypto = @import("web_crypto.zig");
const web_canvas = @import("web_canvas.zig");
const web_streams_source = @embedFile("web_streams.js");

pub const max_script_programs: usize = 16;
pub const max_listeners: usize = 48;
pub const max_timers: usize = 32;
pub const max_abort_deadlines: usize = 32;
pub const max_abort_followers: usize = 64;
pub const max_mutation_observers: usize = 16;
pub const max_mutation_registrations: usize = 8;
pub const max_mutation_records: usize = 64;
pub const max_attribute_filter_names: usize = 8;
pub const max_requests: usize = 8;
pub const max_actions: usize = 16;
pub const max_xhr: usize = 8;
pub const max_event_name_bytes: usize = 32;
pub const max_response_body_bytes: usize = 128 * 1024;
pub const max_font_response_body_bytes: usize = @intCast(web_font_cache.default_max_object_bytes);
const host_object_window: u16 = 1;
const host_object_document: u16 = 2;
const host_object_location: u16 = 3;
const host_object_local_storage: u16 = 4;
const host_object_session_storage: u16 = 5;
const host_object_url: u16 = 6;
const host_object_url_search_params: u16 = 7;
const host_object_url_search_params_keys: u16 = 8;
const host_object_url_search_params_values: u16 = 9;
const host_object_url_search_params_entries: u16 = 10;
const host_object_text_encoder: u16 = 11;
const host_object_text_decoder: u16 = 12;
const host_object_headers: u16 = 13;
const host_object_headers_keys: u16 = 14;
const host_object_headers_values: u16 = 15;
const host_object_headers_entries: u16 = 16;
const host_object_response: u16 = 17;
const host_object_body_stream: u16 = 18;
const host_object_body_reader: u16 = 19;
const host_object_request: u16 = 20;
const host_object_abort_controller: u16 = 21;
const host_object_abort_signal: u16 = 22;
const host_object_count_queuing_strategy: u16 = 23;
const host_object_byte_length_queuing_strategy: u16 = 24;
const host_object_mutation_observer: u16 = 25;
const host_object_event: u16 = 26;
const host_object_history: u16 = 27;
const host_object_navigation: u16 = 28;
const host_object_navigation_entry: u16 = 29;
const host_object_performance_navigation_timing: u16 = 30;
const host_object_frame_window: u16 = 31;
const host_object_frame_document: u16 = 32;
const host_object_frame_node: u16 = 33;
const host_object_canvas_context_base: u16 = 0x0800;
const host_object_node_base: u16 = 0x1000;

const RequestField = enum(u8) {
    method,
    url,
    headers,
    destination,
    referrer,
    referrer_policy,
    mode,
    credentials,
    cache,
    redirect,
    integrity,
    keepalive,
    signal,
    duplex,
};

const abort_aborted: usize = 0;
const abort_reason: usize = 1;
const abort_onabort: usize = 2;
const abort_listener_count: usize = 3;
const abort_listener_base: usize = 4;
const abort_listener_once_base: usize = abort_listener_base + 16;

pub const Error = javascript.Error || html.Error || security.Error || navigation.UrlError || web_url.Error || web_encoding.Error || web_fetch.Error || web_resources.Error || web_fonts.Error || web_crypto.Error || web_canvas.Error || error{
    NotInitialized,
    StaleGeneration,
    ScriptLimit,
    ScriptAllocation,
    ListenerLimit,
    TimerLimit,
    RequestLimit,
    ActionLimit,
    AbortLimit,
    MutationLimit,
    XhrLimit,
    RequestNotFound,
    RequestState,
    SecurityBlocked,
    CorsBlocked,
    ResponseTooLarge,
};

pub const ProgramAllocator = javascript.ProgramAllocator;

pub const RequestKind = enum(u8) {
    fetch,
    xhr,
    script,
    stylesheet,
    image,
    subdocument,
    font,
};

pub const RequestState = enum(u8) {
    free,
    queued,
    in_flight,
    complete,
    failed,
    aborted,
};

pub const FetchRedirectMode = enum(u8) {
    follow,
    error_mode,
    manual,
};

pub const PendingRequest = struct {
    state: RequestState = .free,
    id: u32 = 0,
    generation: u32 = 0,
    kind: RequestKind = .fetch,
    mode: security.RequestMode = .cors,
    credentials: security.CredentialsMode = .same_origin,
    method: http.Method = .get,
    redirect: FetchRedirectMode = .follow,
    request_headers: [web_fetch.max_serialized_bytes]u8 = undefined,
    request_headers_len: usize = 0,
    signal: javascript.Value = .undefined,
    url: navigation.Url = .{},
    target_origin: security.Origin = .{},
    promise: javascript.Value = .undefined,
    xhr: javascript.Value = .undefined,
    resource_index: u8 = std.math.maxInt(u8),
    module_index: u8 = std.math.maxInt(u8),
    status: u16 = 0,
    secure: bool = false,
    redirected: bool = false,
    manual_redirect: bool = false,
    response_url: [navigation.url_capacity + 1]u8 = undefined,
    response_url_len: usize = 0,
    response_content_type: [256]u8 = undefined,
    response_content_type_len: usize = 0,
    response_headers: [web_fetch.max_serialized_bytes]u8 = undefined,
    response_headers_len: usize = 0,
    response_csp: [security.max_policy_bytes]u8 = undefined,
    response_csp_len: usize = 0,
    body: [max_response_body_bytes]u8 = undefined,
    body_len: usize = 0,
    response_byte_count: usize = 0,

    pub fn bodyBytes(self: *const PendingRequest) []const u8 {
        return self.body[0..self.body_len];
    }

    pub fn requestHeaders(self: *const PendingRequest) []const u8 {
        return self.request_headers[0..self.request_headers_len];
    }
};

pub const ResponseMeta = struct {
    status: u16,
    secure: bool,
    content_type: []const u8 = "",
    content_security_policy: []const u8 = "",
    headers: []const u8 = "",
    redirected: bool = false,
    final_url: []const u8 = "",
    access_control_allow_origin: []const u8 = "",
    access_control_allow_credentials: bool = false,
    set_cookies: [http.max_set_cookie_headers]?[]const u8 = [_]?[]const u8{null} ** http.max_set_cookie_headers,
    set_cookie_count: usize = 0,
    manual_redirect: bool = false,
    cookies_processed: bool = false,
};

const RequestQueueOptions = struct {
    mode: security.RequestMode = .cors,
    credentials: security.CredentialsMode = .same_origin,
    method: http.Method = .get,
    redirect: FetchRedirectMode = .follow,
    headers: []const u8 = "",
    body: []const u8 = "",
    signal: javascript.Value = .undefined,
    resource_index: u8 = std.math.maxInt(u8),
    module_index: u8 = std.math.maxInt(u8),
};

const ModuleLoadState = enum(u8) {
    free,
    discovered,
    queued,
    fetching,
    registered,
    failed,
};

const ModuleLoad = struct {
    state: ModuleLoadState = .free,
    generation: u32 = 0,
    url: navigation.Url = .{},
    request_id: u32 = 0,
};

pub const ResourceCompletion = struct {
    generation: u32,
    resource_id: u32,
    node: u16,
    kind: web_resources.Kind,
    role: ImageRole = .content,
    requested_url: navigation.Url,
    final_url: navigation.Url,
    /// Compatibility alias for `final_url` used by existing consumers.
    url: navigation.Url,
    status: u16,
    redirected: bool,
    content_type: []const u8,
    content_security_policy: []const u8,
    body: []const u8,
    byte_count: usize,
    /// Populated for `kind == .font`; otherwise the sentinel values remain.
    font_face_index: u16 = std.math.maxInt(u16),
    font_source_index: u8 = std.math.maxInt(u8),
    font_format: web_fonts.FontFormat = .unspecified,
    font_source_origin: FontSourceOrigin = .network,
    /// Requesting document origin. Font caches must partition aliases by
    /// this value so a CORS-approved response cannot be reused by another
    /// origin without its own successful fetch.
    request_origin: security.Origin = .{},
};

pub const ResourceHandler = struct {
    context: ?*anyopaque = null,
    complete: ?*const fn (?*anyopaque, ResourceCompletion) bool = null,
};

pub const ImageRole = enum(u8) {
    content,
    css_background,
};

pub const FontDemand = struct {
    family_list: []const u8,
    text: []const u8,
    weight: u16 = 400,
    style: web_fonts.FontStyle = .normal,
    oblique_angle_tenth: i16 = 140,
    stretch_hundred: u32 = 10_000,

    fn matchRequest(self: FontDemand) web_fonts.MatchRequest {
        return .{
            .family_list = self.family_list,
            .text = self.text,
            .weight = self.weight,
            .style = self.style,
            .oblique_angle_tenth = self.oblique_angle_tenth,
            .stretch_hundred = self.stretch_hundred,
        };
    }
};

pub const FontDemandSyncStats = struct {
    demanded_faces: usize = 0,
    retained_faces: usize = 0,
    queued_faces: usize = 0,
    available_faces: usize = 0,
    failed_faces: usize = 0,
};

/// Aggregate state of one CSS face for activation coordinators. This is
/// intentionally distinct from per-source ResourceEvent failures: a failed
/// URL may still be followed by another declared `src` candidate.
pub const FontFaceStatus = enum(u8) {
    absent,
    loading,
    ready,
    failed,
};

pub const FontSourceOrigin = enum(u8) {
    network,
    local,
    cache,
};

pub const FontSourceProbe = struct {
    generation: u32,
    document_id: u64,
    face_index: u16,
    source_index: u8,
    format: web_fonts.FontFormat,
    family: []const u8,
    source_value: []const u8,
    resolved_url: navigation.Url = .{},
    request_origin: security.Origin = .{},
};

/// Synchronous availability probes supplied by the application. A local hit
/// identifies a concrete installed face and needs no resource consumer. A
/// cache hit only identifies persistent bytes: after both the declared URL
/// and the returned final URL pass the current document's security policy,
/// `ResourceHandler.complete` is called with `.font_source_origin = .cache`,
/// an empty body, and both URLs so the application can load and decode those
/// bytes. The callbacks must not retain the borrowed family/source slices.
pub const FontSourceHandler = struct {
    context: ?*anyopaque = null,
    local_available: ?*const fn (?*anyopaque, FontSourceProbe) bool = null,
    /// On a hit, writes the response's validated final URL. The runtime
    /// authorizes both the declared and final target against the current
    /// document before accepting persistent bytes.
    cached_available: ?*const fn (?*anyopaque, FontSourceProbe, *navigation.Url) bool = null,
};

pub const CssImageSource = struct {
    node: u16,
    raw_value: []const u8,
    /// Final external stylesheet URL. Empty means the document BASE URL.
    base_url: []const u8 = "",
};

pub const CssImageSyncStats = struct {
    present: usize = 0,
    retained: usize = 0,
    selected: usize = 0,
    retired: usize = 0,
    failed: usize = 0,
};

pub const ResourcePhase = enum(u8) {
    selected,
    queued,
    fetching,
    response,
    ready,
    failed,
    aborted,
    replaced,
};

pub const ResourceFailure = enum(u8) {
    none,
    selection,
    policy,
    queue,
    fetch,
    http_status,
    response_limit,
    consumer,
};

pub const ResourceMime = security.Fixed(256);

/// Bounded value snapshot of one document-resource transition.  It never
/// borrows request buffers and can therefore be retained by diagnostics.
pub const ResourceEvent = struct {
    phase: ResourcePhase,
    failure: ResourceFailure = .none,
    generation: u32,
    resource_id: u32,
    request_id: u32 = 0,
    node: u16,
    kind: web_resources.Kind,
    role: ImageRole = .content,
    requested_url: navigation.Url = .{},
    final_url: navigation.Url = .{},
    status: u16 = 0,
    redirected: bool = false,
    content_type: ResourceMime = .{},
    byte_count: usize = 0,
    font_face_index: u16 = std.math.maxInt(u16),
    font_source_index: u8 = std.math.maxInt(u8),
    font_format: web_fonts.FontFormat = .unspecified,
    font_source_origin: FontSourceOrigin = .network,
};

pub const ResourceObserver = struct {
    context: ?*anyopaque = null,
    report: ?*const fn (?*anyopaque, ResourceEvent) void = null,
};

const ImageResourceState = struct {
    resource_id: u32 = 0,
    role: ImageRole = .content,
    selection: security.Fixed(navigation.url_capacity) = .{},
    selection_hash: u64 = 0,
    selection_len: usize = 0,
    requested_url: navigation.Url = .{},
    terminal_event_sent: bool = false,
};

const FontFacePhase = enum(u8) {
    free,
    loading,
    ready,
    failed,
};

const FontFallbackResult = enum(u8) {
    queued,
    ready,
    exhausted,
};

const FontFaceResourceState = struct {
    phase: FontFacePhase = .free,
    face_index: u16 = std.math.maxInt(u16),
    next_source_index: u8 = 0,
    active_resource_id: u32 = 0,
};

const FontResourceState = struct {
    resource_id: u32 = 0,
    face_index: u16 = std.math.maxInt(u16),
    source_index: u8 = std.math.maxInt(u8),
    format: web_fonts.FontFormat = .unspecified,
    requested_url: navigation.Url = .{},
    cached_final_url: navigation.Url = .{},
    source_origin: FontSourceOrigin = .network,
    consumer_complete: bool = false,
    response_byte_count: usize = 0,
};

pub const FrameInfo = struct {
    url: navigation.Url,
    same_origin: bool,
    complete: bool,
    document: ?*html.Document = null,
    runtime: ?*WebRuntime = null,
};

pub const FrameLookup = struct {
    context: ?*anyopaque = null,
    inspect: ?*const fn (?*anyopaque, security.Origin, u32, u16) ?FrameInfo = null,
};

pub const ActionKind = enum(u8) {
    navigate,
    replace,
    reload,
    back,
    forward,
    push_state,
    replace_state,
    traverse,
    form_submit,
    dom_changed,
};

pub const Action = struct {
    kind: ActionKind = .dom_changed,
    generation: u32 = 0,
    node: u16 = html.none,
    delta: i32 = 0,
    url: navigation.Url = .{},
};

pub const Timing = struct {
    time_origin_ms: f64 = 0,
    navigation_start_ms: f64 = 0,
    fetch_start_ms: f64 = 0,
    request_start_ms: f64 = 0,
    response_start_ms: f64 = 0,
    response_end_ms: f64 = 0,
    dom_interactive_ms: f64 = 0,
    dom_content_loaded_start_ms: f64 = 0,
    dom_content_loaded_end_ms: f64 = 0,
    dom_complete_ms: f64 = 0,
    load_event_start_ms: f64 = 0,
    load_event_end_ms: f64 = 0,
    now_ms: f64 = 0,
};

pub const Environment = struct {
    viewport_width: u32 = 0,
    viewport_height: u32 = 0,
    screen_width: u32 = 0,
    screen_height: u32 = 0,
    color_depth: u8 = 24,
    hardware_concurrency: u16 = 0,
    online: bool = false,
    language: []const u8 = "und",
    user_agent: []const u8 = "Klickifax/0.21 R4OS",
    platform: []const u8 = "R4OS x86_64",
};

/// Snapshot of the latest page-script diagnostic.  This is intentionally a
/// value-only view: callers can display it for troubleshooting without
/// gaining access to mutable runtime internals.
pub const ScriptDiagnostics = struct {
    error_count: usize = 0,
    phase: javascript.DiagnosticPhase = .none,
    error_name: []const u8 = "",
    source_name: []const u8 = "",
    line: u32 = 0,
    column: u32 = 0,
};

pub const ScriptExecutionPhase = enum(u8) {
    begin,
    finish,
};

const DocumentReadyState = enum {
    loading,
    interactive,
    complete,
};

pub const ScriptExecutionEvent = struct {
    phase: ScriptExecutionPhase,
    node: u16,
    source_name: []const u8,
    source: []const u8,
    steps: usize,
    success: bool,
};

pub const ScriptObserver = struct {
    context: ?*anyopaque = null,
    report: ?*const fn (?*anyopaque, ScriptExecutionEvent) void = null,
};

pub const MonotonicClock = struct {
    context: ?*anyopaque = null,
    now_milliseconds: ?*const fn (?*anyopaque) f64 = null,
};

const Listener = struct {
    occupied: bool = false,
    generation: u32 = 0,
    target: u32 = 0,
    event_name: security.Fixed(max_event_name_bytes) = .{},
    callback: javascript.Value = .undefined,
    once: bool = false,
    capture: bool = false,
};

const Timer = struct {
    occupied: bool = false,
    generation: u32 = 0,
    id: u32 = 0,
    due_ms: f64 = 0,
    interval_ms: f64 = 0,
    callback: javascript.Value = .undefined,
};

const AbortDeadline = struct {
    occupied: bool = false,
    generation: u32 = 0,
    due_ms: f64 = 0,
    signal: javascript.Value = .undefined,
};

const AbortFollower = struct {
    occupied: bool = false,
    generation: u32 = 0,
    source: javascript.Value = .undefined,
    target: javascript.Value = .undefined,
};

const Xhr = struct {
    occupied: bool = false,
    generation: u32 = 0,
    object: javascript.Value = .undefined,
    method: [8]u8 = .{0} ** 8,
    method_len: usize = 0,
    url: navigation.Url = .{},
    mode: security.RequestMode = .cors,
};

const MutationKind = enum {
    attributes,
    character_data,
    child_list,
};

const MutationRegistration = struct {
    target: u16 = html.none,
    child_list: bool = false,
    attributes: bool = false,
    character_data: bool = false,
    subtree: bool = false,
    attribute_old_value: bool = false,
    character_data_old_value: bool = false,
    attribute_filter: [max_attribute_filter_names]security.Fixed(64) = [_]security.Fixed(64){.{}} ** max_attribute_filter_names,
    attribute_filter_count: usize = 0,
    attribute_filter_present: bool = false,
};

const TransientMutationRoot = struct {
    root: u16 = html.none,
    registration: usize = 0,
};

const MutationObserverState = struct {
    occupied: bool = false,
    object: javascript.Value = .undefined,
    callback: javascript.Value = .undefined,
    delivery: javascript.Value = .undefined,
    registrations: [max_mutation_registrations]MutationRegistration = [_]MutationRegistration{.{}} ** max_mutation_registrations,
    registration_count: usize = 0,
    records: [max_mutation_records]javascript.Value = [_]javascript.Value{.undefined} ** max_mutation_records,
    record_count: usize = 0,
    transient_roots: [max_mutation_records]TransientMutationRoot = [_]TransientMutationRoot{.{}} ** max_mutation_records,
    transient_root_count: usize = 0,
    delivery_queued: bool = false,
};

const DomQuery = union(enum) {
    selector: []const u8,
    tag: []const u8,
    class: []const u8,
};

const FrameNodeCache = struct {
    iframe_node: u16 = html.none,
    child_node: u16 = html.none,
    object: javascript.Value = .undefined,
};

const HostOp = enum(u16) {
    add_event_listener,
    remove_event_listener,
    document_get_element_by_id,
    document_query_selector,
    document_query_selector_all,
    document_get_elements_by_tag_name,
    document_get_elements_by_class_name,
    document_create_element,
    document_create_text_node,
    document_get_cookie,
    document_set_cookie,
    frame_document_get_element_by_id,
    frame_document_query_selector,
    frame_node_get_attribute,
    frame_node_set_attribute,
    node_get_attribute,
    node_set_attribute,
    node_has_attribute,
    node_remove_attribute,
    node_toggle_attribute,
    node_append_child,
    node_insert_before,
    node_remove_child,
    node_replace_child,
    node_remove,
    node_clone_node,
    node_contains,
    node_has_child_nodes,
    node_query_selector,
    node_query_selector_all,
    node_matches,
    node_closest,
    node_replace_text,
    node_add_event_listener,
    mutation_observer_constructor,
    mutation_observer_observe,
    mutation_observer_disconnect,
    mutation_observer_take_records,
    mutation_observer_deliver,
    event_constructor,
    dispatch_event,
    event_stop_propagation,
    event_stop_immediate_propagation,
    location_assign,
    location_replace,
    location_reload,
    history_back,
    history_forward,
    history_go,
    history_push_state,
    history_replace_state,
    location_to_string,
    navigation_entries,
    navigation_navigate,
    navigation_reload,
    navigation_back,
    navigation_forward,
    navigation_traverse_to,
    navigation_update_current_entry,
    navigation_entry_get_state,
    storage_get,
    storage_set,
    storage_remove,
    storage_clear,
    storage_key,
    performance_now,
    performance_get_entries,
    performance_entries_by_type,
    performance_entries_by_name,
    performance_entry_to_json,
    performance_navigation_timing_constructor,
    set_timeout,
    clear_timeout,
    set_interval,
    clear_interval,
    fetch,
    stream_get_reader,
    stream_get_locked,
    stream_read,
    stream_cancel,
    stream_release_lock,
    xhr_constructor,
    xhr_open,
    xhr_send,
    xhr_abort,
    url_constructor,
    url_can_parse,
    url_parse,
    url_to_string,
    url_search_params_constructor,
    url_search_params_append,
    url_search_params_delete,
    url_search_params_get,
    url_search_params_get_all,
    url_search_params_has,
    url_search_params_set,
    url_search_params_sort,
    url_search_params_to_string,
    url_search_params_keys,
    url_search_params_values,
    url_search_params_entries,
    url_search_params_for_each,
    url_search_params_iterator_next,
    url_get_href,
    url_get_origin,
    url_get_protocol,
    url_get_username,
    url_get_password,
    url_get_host,
    url_get_hostname,
    url_get_port,
    url_get_pathname,
    url_get_search,
    url_get_search_params,
    url_get_hash,
    url_set_href,
    url_set_protocol,
    url_set_username,
    url_set_password,
    url_set_host,
    url_set_hostname,
    url_set_port,
    url_set_pathname,
    url_set_search,
    url_set_hash,
    url_search_params_get_size,
    text_encoder_constructor,
    text_encoder_get_encoding,
    text_encoder_encode,
    text_encoder_encode_into,
    text_decoder_constructor,
    text_decoder_get_encoding,
    text_decoder_get_fatal,
    text_decoder_get_ignore_bom,
    text_decoder_decode,
    headers_constructor,
    headers_append,
    headers_delete,
    headers_get,
    headers_get_set_cookie,
    headers_has,
    headers_set,
    headers_for_each,
    headers_keys,
    headers_values,
    headers_entries,
    headers_iterator_next,
    response_constructor,
    response_error,
    response_redirect,
    response_json_static,
    response_clone,
    response_text,
    response_json,
    response_bytes,
    response_array_buffer,
    response_get_type,
    response_get_url,
    response_get_redirected,
    response_get_status,
    response_get_ok,
    response_get_status_text,
    response_get_headers,
    response_get_body,
    response_get_body_used,
    request_constructor,
    request_clone,
    request_text,
    request_json,
    request_bytes,
    request_array_buffer,
    request_get_method,
    request_get_url,
    request_get_headers,
    request_get_destination,
    request_get_referrer,
    request_get_referrer_policy,
    request_get_mode,
    request_get_credentials,
    request_get_cache,
    request_get_redirect,
    request_get_integrity,
    request_get_keepalive,
    request_get_signal,
    request_get_duplex,
    request_get_body,
    request_get_body_used,
    abort_controller_constructor,
    abort_controller_abort,
    abort_controller_get_signal,
    abort_signal_throw_if_aborted,
    abort_signal_abort_static,
    abort_signal_timeout_static,
    abort_signal_any_static,
    abort_signal_get_aborted,
    abort_signal_get_reason,
    abort_signal_add_event_listener,
    abort_signal_remove_event_listener,
    abort_signal_get_onabort,
    abort_signal_set_onabort,
    count_queuing_strategy_constructor,
    byte_length_queuing_strategy_constructor,
    queuing_strategy_get_high_water_mark,
    count_queuing_strategy_get_size,
    byte_length_queuing_strategy_get_size,
    count_queuing_strategy_size,
    byte_length_queuing_strategy_size,
    feature_supported,
    navigator_send_beacon,
    crypto_get_random_values,
    crypto_random_uuid,
    subtle_digest,
    canvas_get_context,
    canvas_fill_rect,
    canvas_clear_rect,
    canvas_begin_path,
    canvas_move_to,
    canvas_line_to,
    canvas_stroke,
    canvas_fill_text,
    canvas_translate,
    canvas_scale,
    canvas_rotate,
    canvas_save,
    canvas_restore,
    canvas_set_transform,
    canvas_get_image_data,
    canvas_put_image_data,
    form_submit,
    event_prevent_default,
};

pub const EventTarget = union(enum) {
    window,
    document,
    navigation,
    node: u16,
    xhr: u16,
};

pub const Dispatch = struct {
    queued: usize,
    serial: u32,
};

pub const WebRuntime = struct {
    runtime: *javascript.Runtime = undefined,
    runtime_memory: ?[*]u8 = null,
    programs: [max_script_programs]?*javascript.Program = [_]?*javascript.Program{null} ** max_script_programs,
    program_count: usize = 0,
    platform_program: ?*javascript.Program = null,
    program_allocator: ProgramAllocator = undefined,
    execution_stop: javascript.Stop = .{},
    execution_step_budget: usize = javascript.default_step_budget,
    script_observer: ScriptObserver = .{},
    monotonic_clock: MonotonicClock = .{},
    document: ?*html.Document = null,
    storage: ?*security.BrowserStorage = null,
    generation: u32 = 0,
    security_context: security.SecurityContext = .{},
    document_url: navigation.Url = .{},
    history_urls: [navigation.history_capacity]navigation.Url = [_]navigation.Url{.{}} ** navigation.history_capacity,
    history_states: [navigation.history_capacity]javascript.Value = [_]javascript.Value{.null_value} ** navigation.history_capacity,
    history_same_document: [navigation.history_capacity]bool = [_]bool{false} ** navigation.history_capacity,
    history_ids: [navigation.history_capacity]u64 = [_]u64{0} ** navigation.history_capacity,
    next_history_id: u64 = 1,
    navigation_entry_objects: [navigation.history_capacity]javascript.Value = [_]javascript.Value{.undefined} ** navigation.history_capacity,
    performance_navigation_entry: javascript.Value = .undefined,
    history_count: usize = 0,
    history_index: usize = 0,
    history_scroll_manual: bool = false,
    listeners: [max_listeners]Listener = [_]Listener{.{}} ** max_listeners,
    timers: [max_timers]Timer = [_]Timer{.{}} ** max_timers,
    abort_deadlines: [max_abort_deadlines]AbortDeadline = [_]AbortDeadline{.{}} ** max_abort_deadlines,
    abort_followers: [max_abort_followers]AbortFollower = [_]AbortFollower{.{}} ** max_abort_followers,
    requests: [max_requests]PendingRequest = [_]PendingRequest{.{}} ** max_requests,
    resources: web_resources.Scheduler = .{},
    modules: [javascript.max_modules]ModuleLoad = [_]ModuleLoad{.{}} ** javascript.max_modules,
    module_roots: [javascript.max_modules]u8 = [_]u8{std.math.maxInt(u8)} ** javascript.max_modules,
    module_root_modules: [javascript.max_modules]u8 = [_]u8{std.math.maxInt(u8)} ** javascript.max_modules,
    module_count: usize = 0,
    module_root_count: usize = 0,
    resource_handler: ResourceHandler = .{},
    resource_observer: ResourceObserver = .{},
    font_source_handler: FontSourceHandler = .{},
    image_resources: [web_resources.max_resources]ImageResourceState = [_]ImageResourceState{.{}} ** web_resources.max_resources,
    font_resources: [web_resources.max_resources]FontResourceState = [_]FontResourceState{.{}} ** web_resources.max_resources,
    font_faces: [web_fonts.max_faces]FontFaceResourceState = [_]FontFaceResourceState{.{}} ** web_fonts.max_faces,
    font_registry: ?*const web_fonts.Registry = null,
    font_document_id: u64 = 0,
    frame_lookup: FrameLookup = .{},
    actions: [max_actions]Action = [_]Action{.{}} ** max_actions,
    action_count: usize = 0,
    xhrs: [max_xhr]Xhr = [_]Xhr{.{}} ** max_xhr,
    mutation_observers: [max_mutation_observers]MutationObserverState = [_]MutationObserverState{.{}} ** max_mutation_observers,
    node_objects: [html.max_nodes]javascript.Value = [_]javascript.Value{.undefined} ** html.max_nodes,
    frame_document_objects: [html.max_nodes]javascript.Value = [_]javascript.Value{.undefined} ** html.max_nodes,
    frame_window_objects: [html.max_nodes]javascript.Value = [_]javascript.Value{.undefined} ** html.max_nodes,
    frame_node_objects: [64]FrameNodeCache = [_]FrameNodeCache{.{}} ** 64,
    next_timer_id: u32 = 1,
    timer_pump_cursor: usize = 0,
    clock_utc_origin_ms: f64 = 0,
    clock_monotonic_origin_ms: f64 = 0,
    clock_offset_minutes: i32 = 0,
    next_request_id: u32 = 1,
    timing: Timing = .{},
    document_ready_state: DocumentReadyState = .loading,
    script_scratch: [javascript.max_source_bytes]u8 = undefined,
    encoding_input: [web_encoding.max_input_bytes]u8 = undefined,
    encoding_output: [web_encoding.max_output_bytes]u8 = undefined,
    last_block_reason: security.BlockReason = .none,
    script_error_count: usize = 0,
    last_script_phase: javascript.DiagnosticPhase = .none,
    last_script_error_name: security.Fixed(64) = .{},
    last_script_source_name: security.Fixed(navigation.url_capacity) = .{},
    last_script_line: u32 = 0,
    last_script_column: u32 = 0,
    environment: Environment = .{},
    canvases: web_canvas.Manager = undefined,
    canvas_contexts: [web_canvas.max_surfaces]javascript.Value = [_]javascript.Value{.undefined} ** web_canvas.max_surfaces,
    dom_dirty: bool = false,
    dom_action_pending: bool = false,
    next_event_serial: u32 = 1,
    cancelled_event_serial: u32 = 0,

    pub fn initialize(self: *WebRuntime, program_allocator: ProgramAllocator) void {
        self.programs = [_]?*javascript.Program{null} ** max_script_programs;
        self.program_count = 0;
        self.platform_program = null;
        self.program_allocator = program_allocator;
        self.execution_stop = .{};
        self.execution_step_budget = javascript.default_step_budget;
        self.script_observer = .{};
        self.monotonic_clock = .{};
        self.last_script_phase = .none;
        self.last_script_error_name = .{};
        self.last_script_source_name = .{};
        self.last_script_line = 0;
        self.last_script_column = 0;
        self.environment = .{};
        self.canvases.initialize(.{ .context = self, .allocate = canvasAllocate, .free = canvasFree });
        self.canvas_contexts = [_]javascript.Value{.undefined} ** web_canvas.max_surfaces;
        self.document = null;
        self.storage = null;
        self.generation = 0;
        self.clock_utc_origin_ms = 0;
        self.clock_monotonic_origin_ms = 0;
        self.clock_offset_minutes = 0;
        self.timing = .{};
        self.document_ready_state = .loading;
        self.history_urls = [_]navigation.Url{.{}} ** navigation.history_capacity;
        self.history_states = [_]javascript.Value{.null_value} ** navigation.history_capacity;
        self.history_same_document = [_]bool{false} ** navigation.history_capacity;
        self.history_ids = [_]u64{0} ** navigation.history_capacity;
        self.next_history_id = 1;
        self.navigation_entry_objects = [_]javascript.Value{.undefined} ** navigation.history_capacity;
        self.performance_navigation_entry = .undefined;
        self.history_count = 0;
        self.history_index = 0;
        self.history_scroll_manual = false;
        self.node_objects = [_]javascript.Value{.undefined} ** html.max_nodes;
        self.frame_document_objects = [_]javascript.Value{.undefined} ** html.max_nodes;
        self.frame_window_objects = [_]javascript.Value{.undefined} ** html.max_nodes;
        self.frame_node_objects = [_]FrameNodeCache{.{}} ** 64;
        self.mutation_observers = [_]MutationObserverState{.{}} ** max_mutation_observers;
        self.resources.reset(0);
        self.resetModules();
        self.resource_handler = .{};
        self.resource_observer = .{};
        self.font_source_handler = .{};
        self.image_resources = [_]ImageResourceState{.{}} ** web_resources.max_resources;
        self.font_resources = [_]FontResourceState{.{}} ** web_resources.max_resources;
        self.font_faces = [_]FontFaceResourceState{.{}} ** web_fonts.max_faces;
        self.font_registry = null;
        self.font_document_id = 0;
        self.frame_lookup = .{};
        self.runtime = undefined;
        self.runtime_memory = null;
    }

    pub fn javascriptRuntime(self: *WebRuntime) ?*javascript.Runtime {
        return if (self.runtime_memory != null) self.runtime else null;
    }

    pub fn javascriptRealmActive(self: *const WebRuntime) bool {
        return self.runtime_memory != null;
    }

    pub fn javascriptRealmBytes(self: *const WebRuntime) usize {
        return if (self.javascriptRealmActive()) @sizeOf(javascript.Runtime) else 0;
    }

    fn ensureJavascriptRealm(self: *WebRuntime) Error!void {
        if (self.javascriptRealmActive()) return;
        if (self.document == null or self.storage == null) return error.NotInitialized;
        const memory = self.program_allocator.allocate(
            self.program_allocator.context,
            @sizeOf(javascript.Runtime),
            @alignOf(javascript.Runtime),
        ) orelse return error.ScriptAllocation;
        self.runtime = @ptrCast(@alignCast(memory));
        self.runtime_memory = memory;
        self.runtime.* = undefined;
        self.runtime.initialize(self.program_allocator);
        self.runtime.setExternalRootMarker(.{ .context = self, .mark = markRuntimeRoots });
        self.runtime.setClockSource(.{ .context = self, .now_milliseconds = runtimeClockNow, .offset_minutes = runtimeClockOffset });
        errdefer self.releaseJavascriptRealm();

        try self.runtime.init();
        self.runtime.setStop(self.execution_stop);
        self.runtime.setStepBudget(self.execution_step_budget);
        try self.installBindings();
        const platform_program = self.program_allocator.create(self.program_allocator.context) orelse return error.ScriptAllocation;
        self.platform_program = platform_program;
        // The embedded platform layer is trusted initialization, not page
        // work. A caller cancellation or page-sized step budget must only
        // constrain subsequently evaluated website code.
        self.runtime.setStop(.{});
        self.runtime.setStepBudget(javascript.default_step_budget);
        _ = try self.runtime.evaluateNamedScriptSource(platform_program, "r4os:web-streams", web_streams_source);
        self.runtime.setStop(self.execution_stop);
        self.runtime.setStepBudget(self.execution_step_budget);
        const global_object = self.runtime.global("globalThis") orelse return error.TypeError;
        for ([_][]const u8{ "ReadableStream", "ReadableStreamDefaultReader", "ReadableStreamDefaultController", "ReadableStreamBYOBReader", "ReadableStreamBYOBRequest", "ReadableByteStreamController", "WritableStream", "WritableStreamDefaultWriter", "WritableStreamDefaultController", "TransformStream", "TransformStreamDefaultController" }) |name| {
            try self.runtime.defineGlobal(name, try self.runtime.get(global_object, name), true);
        }
    }

    pub fn setExecutionPolicy(self: *WebRuntime, stop: javascript.Stop, step_budget: usize) void {
        self.execution_stop = stop;
        self.execution_step_budget = step_budget;
        if (self.javascriptRealmActive()) {
            self.runtime.setStop(stop);
            self.runtime.setStepBudget(step_budget);
        }
    }

    pub fn setScriptObserver(self: *WebRuntime, observer: ScriptObserver) void {
        self.script_observer = observer;
    }

    pub fn setMonotonicClock(self: *WebRuntime, clock: MonotonicClock) void {
        self.monotonic_clock = clock;
    }

    pub fn setEnvironment(self: *WebRuntime, environment: Environment) void {
        self.environment = environment;
        if (self.document != null) self.refreshResponsiveImages() catch {};
    }

    pub fn setViewport(self: *WebRuntime, width: u32, height: u32) void {
        self.environment.viewport_width = width;
        self.environment.viewport_height = height;
        if (self.document == null or !self.javascriptRealmActive()) return;
        if (self.runtime.global("window")) |window| {
            self.runtime.set(window, "innerWidth", .{ .number = @floatFromInt(width) }) catch {};
            self.runtime.set(window, "innerHeight", .{ .number = @floatFromInt(height) }) catch {};
            self.runtime.set(window, "outerWidth", .{ .number = @floatFromInt(width) }) catch {};
            self.runtime.set(window, "outerHeight", .{ .number = @floatFromInt(height) }) catch {};
        }
        self.refreshResponsiveImages() catch {};
    }

    pub fn setResourceHandler(self: *WebRuntime, handler: ResourceHandler) void {
        self.resource_handler = handler;
    }

    pub fn setResourceObserver(self: *WebRuntime, observer: ResourceObserver) void {
        self.resource_observer = observer;
    }

    pub fn setFontSourceHandler(self: *WebRuntime, handler: FontSourceHandler) void {
        self.font_source_handler = handler;
    }

    /// Retires only document web-font work so a changed conditional
    /// `@font-face` set can be selected again without disturbing scripts,
    /// images, stylesheets or subdocuments from the same generation.
    pub fn resetFontFaces(self: *WebRuntime) void {
        for (self.resources.entries[0..self.resources.count], 0..) |entry, resource_index| {
            if (entry.generation != self.generation or entry.kind != .font) continue;
            self.abortResourceRequest(entry.request_id);
            if (!entry.state.terminal()) {
                self.resources.entries[resource_index].state = .aborted;
                self.reportResourceTransition(resource_index, .aborted, .none, null);
            }
        }
        self.font_resources = [_]FontResourceState{.{}} ** web_resources.max_resources;
        self.font_faces = [_]FontFaceResourceState{.{}} ** web_fonts.max_faces;
        self.font_registry = null;
        self.font_document_id = 0;
    }

    pub fn setResourceImageRole(self: *WebRuntime, resource_id: u32, role: ImageRole) bool {
        for (self.resources.entries[0..self.resources.count], 0..) |entry, index| {
            if (entry.id != resource_id or entry.generation != self.generation or entry.kind != .image) continue;
            if (self.image_resources[index].resource_id != resource_id) self.image_resources[index] = .{ .resource_id = resource_id };
            self.image_resources[index].role = role;
            return true;
        }
        return false;
    }

    /// Synchronizes the currently rendered single-layer CSS image sources.
    /// Sources are keyed by DOM node and the CSS background role, so an IMG
    /// element may own its replaced content and a background independently.
    pub fn syncCssImages(self: *WebRuntime, sources: []const CssImageSource) Error!CssImageSyncStats {
        _ = self.document orelse return error.NotInitialized;
        if (sources.len > web_resources.max_resources) return error.ResourceLimit;
        var stats = CssImageSyncStats{};

        var resource_index: usize = 0;
        while (resource_index < self.resources.count) : (resource_index += 1) {
            const entry = self.resources.entries[resource_index];
            if (entry.generation != self.generation or entry.kind != .image) continue;
            const state = self.image_resources[resource_index];
            if (state.resource_id != entry.id or state.role != .css_background) continue;
            var present = false;
            for (sources) |source| {
                if (source.node == entry.node) {
                    present = true;
                    break;
                }
            }
            if (present) continue;
            self.retireCssImageResource(resource_index);
            stats.retired += 1;
        }

        for (sources, 0..) |source, source_index| {
            var duplicate = false;
            for (sources[0..source_index]) |previous| {
                if (previous.node == source.node) {
                    duplicate = true;
                    break;
                }
            }
            if (duplicate) continue;
            stats.present += 1;
            const result = try self.syncCssImageSource(source);
            switch (result) {
                .retained => stats.retained += 1,
                .selected => stats.selected += 1,
                .failed => stats.failed += 1,
            }
        }
        return stats;
    }

    /// Adds the web-font faces that are actually referenced by rendered text
    /// to the document resource queue. Repeated calls are additive and
    /// idempotent for one registry/document pair. `local()` candidates never
    /// create network requests; loadable URL candidates are tried in declared
    /// source order until the resource consumer accepts one.
    pub fn syncFontDemands(
        self: *WebRuntime,
        registry: *const web_fonts.Registry,
        demands: []const FontDemand,
    ) Error!FontDemandSyncStats {
        var demanded: [web_fonts.max_faces]bool = [_]bool{false} ** web_fonts.max_faces;
        var selected: [web_fonts.max_faces]u16 = undefined;
        for (demands) |demand| {
            const count = try registry.collectNeededFaces(demand.matchRequest(), selected[0..]);
            for (selected[0..count]) |face_index| {
                if (face_index < demanded.len) demanded[face_index] = true;
            }
        }

        var faces: [web_fonts.max_faces]u16 = undefined;
        var face_count: usize = 0;
        for (demanded, 0..) |needed, face_index| {
            if (!needed) continue;
            faces[face_count] = @intCast(face_index);
            face_count += 1;
        }
        return self.syncFontFaces(registry, faces[0..face_count]);
    }

    /// Lower-level companion for renderers that already aggregate and
    /// de-duplicate face indices while walking their render operations.
    pub fn syncFontFaces(
        self: *WebRuntime,
        registry: *const web_fonts.Registry,
        face_indices: []const u16,
    ) Error!FontDemandSyncStats {
        _ = self.document orelse return error.NotInitialized;
        if (self.font_registry) |current| {
            if (current != registry or self.font_document_id != registry.document_id) return error.StaleGeneration;
        } else {
            self.font_registry = registry;
            self.font_document_id = registry.document_id;
        }

        var demanded: [web_fonts.max_faces]bool = [_]bool{false} ** web_fonts.max_faces;
        for (face_indices) |face_index| {
            if (face_index >= registry.face_count or face_index >= demanded.len) return error.InvalidResource;
            demanded[face_index] = true;
        }

        var stats = FontDemandSyncStats{};
        for (demanded, 0..) |needed, raw_face_index| {
            if (!needed) continue;
            stats.demanded_faces += 1;
            const face_index: u16 = @intCast(raw_face_index);
            const face_state = &self.font_faces[raw_face_index];
            if (face_state.phase != .free) {
                if (face_state.face_index != face_index) return error.StaleGeneration;
                switch (face_state.phase) {
                    .loading, .ready => stats.retained_faces += 1,
                    .failed => stats.failed_faces += 1,
                    .free => unreachable,
                }
                continue;
            }
            face_state.* = .{ .phase = .loading, .face_index = face_index };
            const fallback = self.queueNextFontFallback(face_index) catch |err| {
                face_state.* = .{ .phase = .failed, .face_index = face_index };
                // Earlier local() probes in this same demand batch may have
                // already produced scheduler-ready resources.  Preserve the
                // original capacity error, but finish those successful
                // resources before returning so runtime face state, observer
                // events, and resourcesSettled() cannot remain half-applied.
                if (err == error.ResourceLimit) _ = self.runReadyResources() catch 0;
                return err;
            };
            switch (fallback) {
                .queued => stats.queued_faces += 1,
                .ready => stats.available_faces += 1,
                .exhausted => stats.failed_faces += 1,
            }
        }
        self.queueDiscoveredResources() catch |err| if (err != error.RequestLimit) return err;
        _ = try self.runReadyResources();
        return stats;
    }

    pub fn fontFaceStatus(self: *const WebRuntime, face_index: u16) FontFaceStatus {
        if (face_index >= self.font_faces.len) return .absent;
        const state = self.font_faces[face_index];
        if (state.face_index != face_index) return .absent;
        return switch (state.phase) {
            .free => .absent,
            .loading => .loading,
            .ready => .ready,
            .failed => .failed,
        };
    }

    pub fn setFrameLookup(self: *WebRuntime, lookup: FrameLookup) void {
        self.frame_lookup = lookup;
    }

    pub fn deinit(self: *WebRuntime) void {
        self.releaseJavascriptRealm();
        self.canvases.deinit();
        self.document = null;
        self.storage = null;
    }

    pub fn setClockState(self: *WebRuntime, utc_milliseconds: f64, monotonic_milliseconds: f64, offset_minutes: i32) void {
        self.clock_utc_origin_ms = utc_milliseconds;
        self.clock_monotonic_origin_ms = monotonic_milliseconds;
        self.clock_offset_minutes = offset_minutes;
    }

    pub fn setNavigationSnapshot(self: *WebRuntime, entries: []const navigation.Url, entry_ids: []const u64, current_index: usize) Error!void {
        if (entries.len == 0 or entries.len > self.history_urls.len or entry_ids.len != entries.len or current_index >= entries.len) return error.InvalidValue;
        self.history_urls = [_]navigation.Url{.{}} ** navigation.history_capacity;
        self.history_states = [_]javascript.Value{.null_value} ** navigation.history_capacity;
        self.history_same_document = [_]bool{false} ** navigation.history_capacity;
        self.history_ids = [_]u64{0} ** navigation.history_capacity;
        self.navigation_entry_objects = [_]javascript.Value{.undefined} ** navigation.history_capacity;
        self.performance_navigation_entry = .undefined;
        @memcpy(self.history_urls[0..entries.len], entries);
        @memcpy(self.history_ids[0..entry_ids.len], entry_ids);
        self.history_count = entries.len;
        self.history_index = current_index;
        self.history_same_document[current_index] = true;
        self.next_history_id = 1;
        for (entry_ids) |entry_id| self.next_history_id = @max(self.next_history_id, entry_id +% 1);
        self.document_url = self.history_urls[current_index];
    }

    pub fn beginDocument(
        self: *WebRuntime,
        document: *html.Document,
        browser_storage: *security.BrowserStorage,
        url: []const u8,
        csp: []const u8,
        generation: u32,
        now_ms: f64,
    ) Error!void {
        if (self.document != null) self.reportOutstandingResources(.replaced);
        self.releaseJavascriptRealm();
        self.canvases.reset();
        self.canvas_contexts = [_]javascript.Value{.undefined} ** web_canvas.max_surfaces;
        self.document = null;
        self.storage = null;
        self.generation = 0;
        self.security_context = .{};
        self.document_url = .{};
        self.history_urls = [_]navigation.Url{.{}} ** navigation.history_capacity;
        self.history_states = [_]javascript.Value{.null_value} ** navigation.history_capacity;
        self.history_same_document = [_]bool{false} ** navigation.history_capacity;
        self.history_ids = [_]u64{0} ** navigation.history_capacity;
        self.next_history_id = 1;
        self.navigation_entry_objects = [_]javascript.Value{.undefined} ** navigation.history_capacity;
        self.performance_navigation_entry = .undefined;
        self.history_count = 0;
        self.history_index = 0;
        self.history_scroll_manual = false;
        for (&self.listeners) |*listener| listener.* = .{};
        for (&self.timers) |*entry| entry.* = .{};
        for (&self.abort_deadlines) |*entry| entry.* = .{};
        for (&self.abort_followers) |*entry| entry.* = .{};
        for (&self.requests) |*request| request.* = .{};
        self.resources.reset(generation);
        self.image_resources = [_]ImageResourceState{.{}} ** web_resources.max_resources;
        self.font_resources = [_]FontResourceState{.{}} ** web_resources.max_resources;
        self.font_faces = [_]FontFaceResourceState{.{}} ** web_fonts.max_faces;
        self.font_registry = null;
        self.font_document_id = 0;
        self.resetModules();
        for (&self.actions) |*action| action.* = .{};
        self.action_count = 0;
        for (&self.xhrs) |*xhr| xhr.* = .{};
        for (&self.mutation_observers) |*observer| observer.* = .{};
        self.next_timer_id = 1;
        self.timer_pump_cursor = 0;
        self.next_request_id = 1;
        self.timing = .{};
        self.document_ready_state = .loading;
        self.last_block_reason = .none;
        self.script_error_count = 0;
        self.last_script_phase = .none;
        self.last_script_error_name = .{};
        self.last_script_source_name = .{};
        self.last_script_line = 0;
        self.last_script_column = 0;
        self.dom_dirty = false;
        self.dom_action_pending = false;
        self.node_objects = [_]javascript.Value{.undefined} ** html.max_nodes;
        self.frame_document_objects = [_]javascript.Value{.undefined} ** html.max_nodes;
        self.frame_window_objects = [_]javascript.Value{.undefined} ** html.max_nodes;
        self.frame_node_objects = [_]FrameNodeCache{.{}} ** 64;
        self.next_event_serial = 1;
        self.cancelled_event_serial = 0;
        self.document = document;
        self.storage = browser_storage;
        self.generation = generation;
        self.document_url = try navigation.parse(url);
        self.history_urls[0] = self.document_url;
        self.history_states[0] = .null_value;
        self.history_same_document[0] = true;
        self.history_ids[0] = self.next_history_id;
        self.next_history_id += 1;
        self.history_count = 1;
        self.history_index = 0;
        self.security_context = try security.SecurityContext.init(self.document_url.bytes(), generation, csp);
        self.timing = .{
            .time_origin_ms = now_ms,
            .navigation_start_ms = now_ms,
            .fetch_start_ms = now_ms,
            .request_start_ms = now_ms,
            .now_ms = now_ms,
        };
    }

    pub fn abortDocument(self: *WebRuntime) void {
        const aborted_generation = self.generation;
        self.reportOutstandingResources(.aborted);
        self.resources.abort(aborted_generation);
        for (self.modules[0..self.module_count]) |*module| {
            if (module.generation == aborted_generation and module.state != .registered and module.state != .failed) module.state = .failed;
        }
        if (self.generation != std.math.maxInt(u32)) self.generation += 1;
        self.listeners = [_]Listener{.{}} ** max_listeners;
        self.timers = [_]Timer{.{}} ** max_timers;
        self.timer_pump_cursor = 0;
        self.abort_deadlines = [_]AbortDeadline{.{}} ** max_abort_deadlines;
        self.abort_followers = [_]AbortFollower{.{}} ** max_abort_followers;
        self.mutation_observers = [_]MutationObserverState{.{}} ** max_mutation_observers;
        for (&self.requests) |*request| {
            if (request.state == .queued or request.state == .in_flight) request.state = .aborted;
        }
        self.actions = [_]Action{.{}} ** max_actions;
        self.action_count = 0;
        self.document = null;
        self.dom_dirty = false;
        self.dom_action_pending = false;
        self.canvases.reset();
        self.canvas_contexts = [_]javascript.Value{.undefined} ** web_canvas.max_surfaces;
        self.font_registry = null;
        self.font_document_id = 0;
        self.releaseJavascriptRealm();
    }

    pub fn executeDocumentScripts(self: *WebRuntime) Error!usize {
        const document = self.document orelse return error.NotInitialized;
        self.resources.reset(self.generation);
        self.image_resources = [_]ImageResourceState{.{}} ** web_resources.max_resources;
        self.font_resources = [_]FontResourceState{.{}} ** web_resources.max_resources;
        self.font_faces = [_]FontFaceResourceState{.{}} ** web_fonts.max_faces;
        self.font_registry = null;
        self.font_document_id = 0;
        var node_index: usize = 0;
        while (node_index < document.node_count) : (node_index += 1) {
            const index: u16 = @intCast(node_index);
            const kind = web_resources.resourceKind(document, index) orelse continue;
            if (kind == .script and !executableScript(document, index)) continue;
            const external = switch (kind) {
                .script => document.attribute(index, "src") != null,
                .image => if (imageSelection(document, index, self.environment)) |selection| !isDataReference(selection.url) else false,
                .stylesheet => document.attribute(index, "href") != null,
                .subdocument => document.attribute(index, "src") != null,
                .font => false,
            };
            const script_mode = if (kind == .script) web_resources.classifyScript(document, index, false) else .none;
            const resource_index = self.resources.discover(index, kind, script_mode, external) catch {
                if (kind == .script) self.script_error_count += 1;
                continue;
            };
            if (kind == .image) self.initializeImageResource(resource_index, if (imageSelection(document, index, self.environment)) |selection| selection.url else "");
            if (external) continue;
            self.reportResourceTransition(resource_index, .selected, .none, self.document_url);
            if (kind == .script and !self.security_context.allowsInlineScript(document.attribute(index, "nonce") orelse "")) {
                self.last_block_reason = .content_security_policy;
                self.script_error_count += 1;
                self.resources.reject(resource_index) catch {};
                self.reportResourceTransition(resource_index, .failed, .policy, self.document_url);
                self.dispatchResourceTerminalEvent(resource_index, false);
                continue;
            }
            self.resources.markReady(resource_index) catch {};
        }
        self.resources.finishParsing();
        try self.queueDiscoveredResources();
        defer self.document_ready_state = .interactive;
        const executed = try self.runReadyResources();
        self.timing.dom_interactive_ms = self.timing.now_ms;
        self.refreshTimingBindings();
        return executed;
    }

    pub fn resourcesSettled(self: *const WebRuntime) bool {
        return self.resources.settled();
    }

    pub fn scriptDiagnostics(self: *const WebRuntime) ScriptDiagnostics {
        if (self.last_script_error_name.len > 0) return .{
            .error_count = self.script_error_count,
            .phase = self.last_script_phase,
            .error_name = self.last_script_error_name.bytes(),
            .source_name = self.last_script_source_name.bytes(),
            .line = self.last_script_line,
            .column = self.last_script_column,
        };
        if (!self.javascriptRealmActive()) return .{
            .error_count = self.script_error_count,
        };
        return .{
            .error_count = self.script_error_count,
            .phase = self.runtime.diagnosticPhase(),
            .error_name = self.runtime.diagnosticErrorName(),
            .source_name = self.runtime.diagnosticSourceName(),
            .line = self.runtime.diagnosticLine(),
            .column = self.runtime.diagnosticColumn(),
        };
    }

    pub fn executeSource(self: *WebRuntime, source: []const u8) Error!javascript.Value {
        return self.executeNamedSource(self.document_url.bytes(), source);
    }

    pub fn executeNamedSource(self: *WebRuntime, source_name: []const u8, source: []const u8) Error!javascript.Value {
        try self.ensureJavascriptRealm();
        if (self.program_count >= self.programs.len) return error.ScriptLimit;
        const program = self.program_allocator.create(self.program_allocator.context) orelse return error.ScriptAllocation;
        self.programs[self.program_count] = program;
        self.program_count += 1;
        return self.runtime.evaluateNamedScriptSource(program, source_name, source) catch |err| {
            self.program_count -= 1;
            self.programs[self.program_count] = null;
            self.program_allocator.destroy(self.program_allocator.context, program);
            return err;
        };
    }

    fn queueNextFontFallback(self: *WebRuntime, face_index: u16) Error!FontFallbackResult {
        const registry = self.font_registry orelse return error.NotInitialized;
        if (face_index >= registry.face_count or face_index >= self.font_faces.len) return error.InvalidResource;
        const face = registry.faces[face_index];
        const face_state = &self.font_faces[face_index];
        while (face_state.next_source_index < face.source_count) {
            const source_index = face_state.next_source_index;
            face_state.next_source_index += 1;
            const source = registry.faceSource(face_index, source_index) orelse continue;
            const source_value = registry.sourceValue(@as(usize, face.source_start) + source_index);
            const probe_base = FontSourceProbe{
                .generation = self.generation,
                .document_id = registry.document_id,
                .face_index = face_index,
                .source_index = source_index,
                .format = source.format,
                .family = registry.family(face_index),
                .source_value = source_value,
                .request_origin = self.security_context.document_origin,
            };
            if (source.kind == .local) {
                // Reserve the scheduler identity before the application is
                // allowed to publish a concrete installed face.  A failed
                // reservation must never run a side-effecting local probe.
                const resource_index = try self.allocateFontResourceEntry(false);
                const entry = self.resources.entries[resource_index];
                self.font_resources[resource_index] = .{
                    .resource_id = entry.id,
                    .face_index = face_index,
                    .source_index = source_index,
                    .format = source.format,
                    .source_origin = .local,
                };
                const available = if (self.font_source_handler.local_available) |probe|
                    probe(self.font_source_handler.context, probe_base)
                else
                    false;
                if (!available) {
                    // A local miss is source selection, not a resource
                    // failure.  Make the private reservation reusable without
                    // emitting an observer transition for a source that was
                    // never selected.
                    try self.resources.reject(resource_index);
                    self.font_resources[resource_index] = .{};
                    continue;
                }
                face_state.phase = .loading;
                face_state.active_resource_id = entry.id;
                self.reportResourceTransition(resource_index, .selected, .none, null);
                try self.resources.markReady(resource_index);
                return .ready;
            }
            if (!source.format.loadable()) continue;

            const resource_index = try self.allocateFontResourceEntry(true);
            const entry = self.resources.entries[resource_index];
            self.font_resources[resource_index] = .{
                .resource_id = entry.id,
                .face_index = face_index,
                .source_index = source_index,
                .format = source.format,
            };

            const section_base = registry.sectionBaseUrl(face.source_section);
            const base = if (section_base.len == 0)
                self.document_url
            else
                navigation.parse(section_base) catch {
                    try self.resources.reject(resource_index);
                    self.reportResourceTransition(resource_index, .failed, .selection, null);
                    continue;
                };
            const target = navigation.resolve(&base, source_value) catch {
                try self.resources.reject(resource_index);
                self.reportResourceTransition(resource_index, .failed, .selection, null);
                continue;
            };
            self.font_resources[resource_index].requested_url = target;
            face_state.phase = .loading;
            face_state.active_resource_id = entry.id;
            const decision = self.security_context.authorize(self.generation, target.bytes(), .font, .cors);
            if (!decision.allowed) {
                self.last_block_reason = decision.reason;
                try self.resources.reject(resource_index);
                self.reportResourceTransition(resource_index, .failed, .policy, target);
                face_state.active_resource_id = 0;
                continue;
            }
            const cached_probe = FontSourceProbe{
                .generation = probe_base.generation,
                .document_id = probe_base.document_id,
                .face_index = probe_base.face_index,
                .source_index = probe_base.source_index,
                .format = probe_base.format,
                .family = probe_base.family,
                .source_value = probe_base.source_value,
                .resolved_url = target,
                .request_origin = self.security_context.document_origin,
            };
            var cached_final_url = target;
            const cached = if (self.font_source_handler.cached_available) |probe|
                probe(self.font_source_handler.context, cached_probe, &cached_final_url)
            else
                false;
            if (cached) {
                const final_decision = self.security_context.authorize(self.generation, cached_final_url.bytes(), .font, .cors);
                if (final_decision.allowed) {
                    self.resources.entries[resource_index].request_required = false;
                    self.font_resources[resource_index].source_origin = .cache;
                    self.font_resources[resource_index].cached_final_url = cached_final_url;
                    self.reportResourceTransition(resource_index, .selected, .none, target);
                    try self.resources.markReady(resource_index);
                    return .ready;
                }
                self.last_block_reason = final_decision.reason;
            }
            return .queued;
        }
        face_state.phase = .failed;
        face_state.active_resource_id = 0;
        return .exhausted;
    }

    fn allocateFontResourceEntry(self: *WebRuntime, request_required: bool) Error!usize {
        for (self.resources.entries[0..self.resources.count], 0..) |entry, resource_index| {
            if (entry.generation != self.generation or entry.kind != .font or !entry.state.terminal()) continue;
            const sequence = entry.sequence;
            self.resources.entries[resource_index] = .{
                .id = self.nextResourceIdentity(),
                .generation = self.generation,
                .sequence = sequence,
                .node = html.none,
                .kind = .font,
                .script_mode = .none,
                .request_required = request_required,
            };
            self.font_resources[resource_index] = .{};
            return resource_index;
        }
        return self.resources.discover(html.none, .font, .none, request_required);
    }

    fn finishFontResource(self: *WebRuntime, resource_index: usize, success: bool) void {
        if (resource_index >= self.resources.count or resource_index >= self.font_resources.len) return;
        const entry = self.resources.entries[resource_index];
        if (entry.kind != .font) return;
        const resource = self.font_resources[resource_index];
        if (resource.resource_id != entry.id or resource.face_index >= self.font_faces.len) return;
        const face_state = &self.font_faces[resource.face_index];
        if (face_state.face_index != resource.face_index or face_state.active_resource_id != entry.id) return;
        face_state.active_resource_id = 0;
        if (success) {
            face_state.phase = .ready;
            return;
        }
        // A persistent hit is only a source probe, not a decoded face. If its
        // consumer rejects stale, corrupt, or otherwise unusable cache bytes,
        // retry the same declared URL through the ordinary authorized network
        // path before advancing to the next CSS source candidate.
        if (resource.source_origin == .cache) {
            self.queueCachedFontNetworkRetry(resource_index, resource) catch {
                _ = self.queueNextFontFallback(resource.face_index) catch {
                    face_state.phase = .failed;
                };
            };
            return;
        }
        _ = self.queueNextFontFallback(resource.face_index) catch {
            face_state.phase = .failed;
        };
    }

    fn queueCachedFontNetworkRetry(self: *WebRuntime, resource_index: usize, cached: FontResourceState) Error!void {
        if (resource_index >= self.resources.count or cached.requested_url.len == 0 or cached.face_index >= self.font_faces.len)
            return error.InvalidResource;
        const previous = self.resources.entries[resource_index];
        if (previous.generation != self.generation or previous.kind != .font or !previous.state.terminal())
            return error.InvalidResource;
        self.resources.entries[resource_index] = .{
            .id = self.nextResourceIdentity(),
            .generation = self.generation,
            .sequence = previous.sequence,
            .node = html.none,
            .kind = .font,
            .script_mode = .none,
            .request_required = true,
        };
        const entry = self.resources.entries[resource_index];
        self.font_resources[resource_index] = .{
            .resource_id = entry.id,
            .face_index = cached.face_index,
            .source_index = cached.source_index,
            .format = cached.format,
            .requested_url = cached.requested_url,
            .source_origin = .network,
        };
        const face_state = &self.font_faces[cached.face_index];
        face_state.phase = .loading;
        face_state.active_resource_id = entry.id;
    }

    fn queueDiscoveredResources(self: *WebRuntime) Error!void {
        const document = self.document orelse return error.NotInitialized;
        while (self.resources.pendingRequestSlot()) |resource_index| {
            const entry = self.resources.entries[resource_index];
            const tracked_image = if (entry.kind == .image and resource_index < self.image_resources.len and
                self.image_resources[resource_index].resource_id == entry.id)
                self.image_resources[resource_index]
            else
                ImageResourceState{};
            const target = if (entry.kind == .image and tracked_image.role == .css_background and tracked_image.requested_url.len > 0)
                tracked_image.requested_url
            else if (entry.kind == .font and resource_index < self.font_resources.len and
                self.font_resources[resource_index].resource_id == entry.id and
                self.font_resources[resource_index].requested_url.len > 0)
                self.font_resources[resource_index].requested_url
            else
                resourceTarget(document, entry.node, entry.kind, &self.document_url, self.environment) catch {
                    self.resources.reject(resource_index) catch {};
                    self.reportResourceTransition(resource_index, .failed, .selection, null);
                    self.dispatchResourceTerminalEvent(resource_index, false);
                    self.finishFontResource(resource_index, false);
                    if (entry.kind == .script) self.script_error_count += 1;
                    continue;
                };
            const request_kind: RequestKind = switch (entry.kind) {
                .script => .script,
                .stylesheet => .stylesheet,
                .image => .image,
                .subdocument => .subdocument,
                .font => .font,
            };
            const script_type = document.attribute(entry.node, "type") orelse "";
            const mode: security.RequestMode = switch (entry.kind) {
                .script => if (std.ascii.eqlIgnoreCase(script_type, "module")) .cors else .no_cors,
                .subdocument => .navigate,
                .font => .cors,
                .stylesheet, .image => .no_cors,
            };
            const request_id = self.queueRequest(target, request_kind, .undefined, .undefined, .{
                .mode = mode,
                .credentials = if (entry.kind == .font or
                    (entry.kind == .script and std.ascii.eqlIgnoreCase(script_type, "module"))) .same_origin else .include,
                .resource_index = @intCast(resource_index),
            }) catch |err| {
                if (err == error.RequestLimit) return;
                self.resources.reject(resource_index) catch {};
                self.reportResourceTransition(
                    resource_index,
                    .failed,
                    if (err == error.SecurityBlocked) .policy else .queue,
                    target,
                );
                self.dispatchResourceTerminalEvent(resource_index, false);
                self.finishFontResource(resource_index, false);
                if (entry.kind == .script) self.script_error_count += 1;
                continue;
            };
            try self.resources.queue(resource_index, request_id);
            if (entry.kind == .image) self.image_resources[resource_index].requested_url = target;
            self.reportResourceTransition(resource_index, .selected, .none, target);
            self.reportResourceTransition(resource_index, .queued, .none, target);
        }
    }

    fn runReadyResources(self: *WebRuntime) Error!usize {
        const document = self.document orelse return error.NotInitialized;
        var executed_scripts: usize = 0;
        while (self.resources.takeRunnable()) |resource_index| {
            const entry = self.resources.entries[resource_index];
            const request = if (entry.request_id != web_resources.no_request) self.findRequest(entry.request_id) else null;
            var success = true;
            var resource_failure: ResourceFailure = .consumer;
            if (entry.kind == .script) {
                const source = if (request) |value|
                    value.bodyBytes()
                else
                    document.textContent(entry.node, self.script_scratch[0..]) catch blk: {
                        success = false;
                        break :blk self.script_scratch[0..0];
                    };
                if (success and source.len > 0) {
                    const source_name = if (request) |value| value.url.bytes() else self.document_url.bytes();
                    const script_type = document.attribute(entry.node, "type") orelse "";
                    if (std.ascii.eqlIgnoreCase(script_type, "module")) {
                        var inline_name: [navigation.url_capacity + 1]u8 = undefined;
                        const module_name = if (request) |value|
                            value.response_url[0..value.response_url_len]
                        else
                            std.fmt.bufPrint(&inline_name, "{s}#r4-inline-module-{d}", .{ source_name, entry.id }) catch source_name;
                        if (request) |value| value.state = .free;
                        self.startModuleRoot(@intCast(resource_index), module_name, source) catch {
                            self.failModuleGraph();
                            self.finishResourceEntry(resource_index, false) catch {};
                            self.script_error_count += 1;
                        };
                        try self.queueDiscoveredResources();
                        continue;
                    } else {
                        var inline_name: [navigation.url_capacity + 32]u8 = undefined;
                        const evaluated_name = if (request != null)
                            source_name
                        else
                            std.fmt.bufPrint(&inline_name, "{s}#r4-inline-script-{d}", .{ source_name, entry.id }) catch source_name;
                        self.reportScriptExecution(.{
                            .phase = .begin,
                            .node = entry.node,
                            .source_name = evaluated_name,
                            .source = source,
                            .steps = 0,
                            .success = false,
                        });
                        _ = self.executeNamedSource(evaluated_name, source) catch |err| {
                            self.captureScriptFailure(err);
                            success = false;
                        };
                        self.reportScriptExecution(.{
                            .phase = .finish,
                            .node = entry.node,
                            .source_name = evaluated_name,
                            .source = source,
                            .steps = if (self.javascriptRealmActive()) self.runtime.stats.steps else 0,
                            .success = success,
                        });
                    }
                }
                if (success) executed_scripts += 1 else self.script_error_count += 1;
            } else {
                var body: []const u8 = if (request) |value| value.bodyBytes() else document.attribute(entry.node, "srcdoc") orelse "";
                var content_type: []const u8 = if (request) |value| value.response_content_type[0..value.response_content_type_len] else "text/html";
                const target = if (request) |value|
                    navigation.parse(value.response_url[0..value.response_url_len]) catch value.url
                else
                    self.document_url;
                if (entry.kind == .image and request == null) embedded_image: {
                    const selection = imageSelection(document, entry.node, self.environment) orelse {
                        resource_failure = .selection;
                        success = false;
                        break :embedded_image;
                    };
                    if (!isDataReference(selection.url)) {
                        resource_failure = .selection;
                        success = false;
                        break :embedded_image;
                    }
                    const decision = self.security_context.allowsEmbeddedScheme(self.generation, .image, "data:");
                    if (!decision.allowed) {
                        self.last_block_reason = decision.reason;
                        resource_failure = .policy;
                        success = false;
                        break :embedded_image;
                    }
                    const decoded = web_images.decodeDataUrl(selection.url, self.script_scratch[0..]) catch |err| {
                        resource_failure = if (err == error.TooLarge or err == error.BufferTooSmall) .response_limit else .selection;
                        success = false;
                        break :embedded_image;
                    };
                    body = decoded.bytes;
                    content_type = decoded.media_type;
                }
                if (success) {
                    const tracked_font = entry.kind == .font and
                        self.font_resources[resource_index].resource_id == entry.id;
                    if (tracked_font and self.font_resources[resource_index].source_origin == .cache) {
                        success = self.consumeCachedFontResource(resource_index);
                    } else {
                        const font_already_consumed = tracked_font and
                            (self.font_resources[resource_index].source_origin == .local or
                                self.font_resources[resource_index].consumer_complete);
                        if (!font_already_consumed) if (self.resource_handler.complete) |complete| {
                            success = complete(self.resource_handler.context, .{
                                .generation = self.generation,
                                .resource_id = entry.id,
                                .node = entry.node,
                                .kind = entry.kind,
                                .role = if (self.image_resources[resource_index].resource_id == entry.id) self.image_resources[resource_index].role else .content,
                                .requested_url = if (request) |value| value.url else self.document_url,
                                .final_url = target,
                                .url = target,
                                .status = if (request) |value| value.status else 0,
                                .redirected = if (request) |value| value.redirected else false,
                                .content_type = content_type,
                                .content_security_policy = if (request) |value| value.response_csp[0..value.response_csp_len] else "",
                                .body = body,
                                .byte_count = body.len,
                                .font_face_index = if (entry.kind == .font and self.font_resources[resource_index].resource_id == entry.id)
                                    self.font_resources[resource_index].face_index
                                else
                                    std.math.maxInt(u16),
                                .font_source_index = if (entry.kind == .font and self.font_resources[resource_index].resource_id == entry.id)
                                    self.font_resources[resource_index].source_index
                                else
                                    std.math.maxInt(u8),
                                .font_format = if (entry.kind == .font and self.font_resources[resource_index].resource_id == entry.id)
                                    self.font_resources[resource_index].format
                                else
                                    .unspecified,
                                .font_source_origin = if (entry.kind == .font and self.font_resources[resource_index].resource_id == entry.id)
                                    self.font_resources[resource_index].source_origin
                                else
                                    .network,
                                .request_origin = self.security_context.document_origin,
                            });
                        };
                    }
                }
            }

            try self.resources.finish(resource_index, success);
            self.reportResourceTransition(resource_index, if (success) .ready else .failed, if (success) .none else resource_failure, null);
            self.dispatchResourceTerminalEvent(resource_index, success);
            self.finishFontResource(resource_index, success);
            if (request) |value| value.state = if (success) .free else .failed;
            try self.queueDiscoveredResources();
        }
        return executed_scripts;
    }

    fn reportScriptExecution(self: *WebRuntime, event: ScriptExecutionEvent) void {
        const report = self.script_observer.report orelse return;
        report(self.script_observer.context, event);
    }

    fn reportResourceTransition(
        self: *WebRuntime,
        resource_index: usize,
        phase: ResourcePhase,
        failure: ResourceFailure,
        selected_url: ?navigation.Url,
    ) void {
        const report = self.resource_observer.report orelse return;
        if (resource_index >= self.resources.count) return;
        const entry = self.resources.entries[resource_index];
        const request = self.resourceRequest(entry.request_id);
        const tracked_url = if (resource_index < self.image_resources.len and self.image_resources[resource_index].resource_id == entry.id)
            self.image_resources[resource_index].requested_url
        else if (resource_index < self.font_resources.len and self.font_resources[resource_index].resource_id == entry.id)
            self.font_resources[resource_index].requested_url
        else
            navigation.Url{};
        const role: ImageRole = if (resource_index < self.image_resources.len and self.image_resources[resource_index].resource_id == entry.id)
            self.image_resources[resource_index].role
        else
            .content;
        const requested_url = selected_url orelse if (request) |value| value.url else tracked_url;
        var final_url = requested_url;
        var event = ResourceEvent{
            .phase = phase,
            .failure = failure,
            .generation = entry.generation,
            .resource_id = entry.id,
            .request_id = if (request) |value| value.id else entry.request_id,
            .node = entry.node,
            .kind = entry.kind,
            .role = role,
            .requested_url = requested_url,
            .final_url = final_url,
            .font_face_index = if (entry.kind == .font and self.font_resources[resource_index].resource_id == entry.id)
                self.font_resources[resource_index].face_index
            else
                std.math.maxInt(u16),
            .font_source_index = if (entry.kind == .font and self.font_resources[resource_index].resource_id == entry.id)
                self.font_resources[resource_index].source_index
            else
                std.math.maxInt(u8),
            .font_format = if (entry.kind == .font and self.font_resources[resource_index].resource_id == entry.id)
                self.font_resources[resource_index].format
            else
                .unspecified,
            .font_source_origin = if (entry.kind == .font and self.font_resources[resource_index].resource_id == entry.id)
                self.font_resources[resource_index].source_origin
            else
                .network,
        };
        if (entry.kind == .font and self.font_resources[resource_index].resource_id == entry.id and
            self.font_resources[resource_index].source_origin == .cache and
            self.font_resources[resource_index].cached_final_url.len > 0)
        {
            event.final_url = self.font_resources[resource_index].cached_final_url;
            event.redirected = !std.mem.eql(u8, requested_url.bytes(), event.final_url.bytes());
        }
        if (request) |value| {
            if (value.response_url_len > 0) {
                final_url = navigation.parse(value.response_url[0..value.response_url_len]) catch requested_url;
                event.final_url = final_url;
            }
            event.status = value.status;
            event.redirected = value.redirected;
            event.content_type.set(value.response_content_type[0..value.response_content_type_len]) catch {};
            event.byte_count = if (value.response_byte_count > 0) value.response_byte_count else value.body_len;
        }
        report(self.resource_observer.context, event);
    }

    fn reportOutstandingResources(self: *WebRuntime, phase: ResourcePhase) void {
        for (self.resources.entries[0..self.resources.count], 0..) |entry, index| {
            if (entry.generation != self.generation or entry.state.terminal()) continue;
            self.reportResourceTransition(index, phase, .none, null);
        }
    }

    fn resourceRequest(self: *const WebRuntime, request_id: u32) ?*const PendingRequest {
        if (request_id == web_resources.no_request) return null;
        for (&self.requests) |*request| {
            if (request.id == request_id and request.state != .free) return request;
        }
        return null;
    }

    fn initializeImageResource(self: *WebRuntime, resource_index: usize, selection: []const u8) void {
        if (resource_index >= self.resources.count or resource_index >= self.image_resources.len) return;
        const entry = self.resources.entries[resource_index];
        self.image_resources[resource_index] = .{ .resource_id = entry.id };
        self.image_resources[resource_index].selection_hash = selectionHash(selection);
        self.image_resources[resource_index].selection_len = selection.len;
        self.image_resources[resource_index].selection.set(selection) catch {};
    }

    fn imageSelectionMatches(state: *const ImageResourceState, resource_id: u32, selection: []const u8) bool {
        return state.resource_id == resource_id and state.selection_len == selection.len and
            state.selection_hash == selectionHash(selection);
    }

    fn dispatchResourceTerminalEvent(self: *WebRuntime, resource_index: usize, success: bool) void {
        if (resource_index >= self.resources.count or resource_index >= self.image_resources.len) return;
        const entry = self.resources.entries[resource_index];
        const state = &self.image_resources[resource_index];
        if (state.resource_id != entry.id) state.* = .{ .resource_id = entry.id };
        if (state.terminal_event_sent) return;
        state.terminal_event_sent = true;
        if (!self.javascriptRealmActive()) return;
        if (state.role != .content) return;
        const event = self.makeDomEvent(if (success) "load" else "error", false, false, false, 0) catch return;
        const target = self.makeNode(entry.node) catch return;
        if (target != .undefined) _ = self.dispatchDomEvent(eventTargetToken(.{ .node = entry.node }), target, event) catch false;
    }

    fn imageResourceIndex(self: *const WebRuntime, node: u16, role: ImageRole) ?usize {
        var found: ?usize = null;
        for (self.resources.entries[0..self.resources.count], 0..) |entry, index| {
            if (entry.generation != self.generation or entry.kind != .image or entry.node != node) continue;
            const state = self.image_resources[index];
            const entry_role = if (state.resource_id == entry.id) state.role else ImageRole.content;
            if (entry_role == role) found = index;
        }
        return found;
    }

    fn nextResourceIdentity(self: *WebRuntime) u32 {
        const id = self.resources.next_id;
        self.resources.next_id +%= 1;
        if (self.resources.next_id == 0) self.resources.next_id = 1;
        return id;
    }

    fn abortResourceRequest(self: *WebRuntime, request_id: u32) void {
        if (request_id == web_resources.no_request) return;
        for (&self.requests) |*request| {
            if (request.id != request_id or request.generation != self.generation or request.state == .free) continue;
            request.state = .aborted;
            return;
        }
    }

    const CssImageSyncResult = enum(u8) {
        retained,
        selected,
        failed,
    };

    fn retireCssImageResource(self: *WebRuntime, resource_index: usize) void {
        if (resource_index >= self.resources.count) return;
        const entry = self.resources.entries[resource_index];
        self.abortResourceRequest(entry.request_id);
        if (!entry.state.terminal()) self.resources.entries[resource_index].state = .aborted;
        self.reportResourceTransition(resource_index, .aborted, .none, null);
    }

    fn syncCssImageSource(self: *WebRuntime, source: CssImageSource) Error!CssImageSyncResult {
        const document = self.document orelse return error.NotInitialized;
        if (source.node >= document.node_count or document.nodes[source.node].kind != .element) return error.InvalidValue;
        const context = web_images.Context{
            .viewport_width = @max(1, self.environment.viewport_width),
            .viewport_height = @max(1, self.environment.viewport_height),
            .device_pixel_ratio_milli = 1000,
        };
        const selection = web_images.selectCssImage(source.raw_value, context);
        const reference = if (selection) |value| value.url else "";
        const embedded = selection != null and isDataReference(reference);
        var target = navigation.Url{};
        var selection_identity = reference;
        if (selection != null and !embedded) {
            const base = if (source.base_url.len > 0)
                navigation.parse(source.base_url) catch return self.failCssImageSelection(source.node, reference)
            else
                effectiveDocumentBase(document, &self.document_url);
            target = navigation.resolve(&base, reference) catch return self.failCssImageSelection(source.node, reference);
            selection_identity = target.bytes();
        }

        if (self.imageResourceIndex(source.node, .css_background)) |existing_index| {
            const old_entry = self.resources.entries[existing_index];
            const old_state = &self.image_resources[existing_index];
            if (selection != null and old_entry.state != .aborted and
                imageSelectionMatches(old_state, old_entry.id, selection_identity)) return .retained;
            self.reportResourceTransition(existing_index, .replaced, .none, null);
            self.abortResourceRequest(old_entry.request_id);
            self.resetCssImageEntry(existing_index, source.node, selection != null and !embedded, selection_identity, target);
            if (selection == null) return self.rejectCssImage(existing_index, .selection);
            if (embedded) return self.completeEmbeddedCssImage(existing_index, reference);
            try self.queueDiscoveredResources();
            return .selected;
        }

        const resource_index = try self.allocateCssImageEntry(source.node, selection != null and !embedded);
        self.initializeImageResource(resource_index, selection_identity);
        self.image_resources[resource_index].role = .css_background;
        self.image_resources[resource_index].requested_url = target;
        if (selection == null) return self.rejectCssImage(resource_index, .selection);
        if (embedded) return self.completeEmbeddedCssImage(resource_index, reference);
        try self.queueDiscoveredResources();
        return .selected;
    }

    fn allocateCssImageEntry(self: *WebRuntime, node: u16, request_required: bool) Error!usize {
        for (self.resources.entries[0..self.resources.count], 0..) |entry, index| {
            const state = self.image_resources[index];
            if (entry.generation == self.generation and entry.kind == .image and entry.state.terminal() and
                state.resource_id == entry.id and state.role == .css_background)
            {
                self.resetCssImageEntry(index, node, request_required, "", .{});
                return index;
            }
        }
        const index = try self.resources.discover(node, .image, .none, request_required);
        self.initializeImageResource(index, "");
        self.image_resources[index].role = .css_background;
        return index;
    }

    fn resetCssImageEntry(
        self: *WebRuntime,
        resource_index: usize,
        node: u16,
        request_required: bool,
        selection: []const u8,
        target: navigation.Url,
    ) void {
        const sequence = self.resources.entries[resource_index].sequence;
        self.resources.entries[resource_index] = .{
            .id = self.nextResourceIdentity(),
            .generation = self.generation,
            .sequence = sequence,
            .node = node,
            .kind = .image,
            .script_mode = .none,
            .request_required = request_required,
        };
        self.initializeImageResource(resource_index, selection);
        self.image_resources[resource_index].role = .css_background;
        self.image_resources[resource_index].requested_url = target;
    }

    fn failCssImageSelection(self: *WebRuntime, node: u16, reference: []const u8) Error!CssImageSyncResult {
        if (self.imageResourceIndex(node, .css_background)) |existing_index| {
            const old_entry = self.resources.entries[existing_index];
            self.reportResourceTransition(existing_index, .replaced, .none, null);
            self.abortResourceRequest(old_entry.request_id);
            self.resetCssImageEntry(existing_index, node, false, reference, .{});
            return self.rejectCssImage(existing_index, .selection);
        }
        const index = try self.allocateCssImageEntry(node, false);
        self.initializeImageResource(index, reference);
        self.image_resources[index].role = .css_background;
        return self.rejectCssImage(index, .selection);
    }

    fn rejectCssImage(self: *WebRuntime, resource_index: usize, failure: ResourceFailure) Error!CssImageSyncResult {
        try self.resources.reject(resource_index);
        self.reportResourceTransition(resource_index, .failed, failure, null);
        return .failed;
    }

    fn completeEmbeddedCssImage(self: *WebRuntime, resource_index: usize, reference: []const u8) Error!CssImageSyncResult {
        const decision = self.security_context.allowsEmbeddedScheme(self.generation, .image, "data:");
        if (!decision.allowed) {
            self.last_block_reason = decision.reason;
            return self.rejectCssImage(resource_index, .policy);
        }
        const decoded = web_images.decodeDataUrl(reference, self.script_scratch[0..]) catch |err| {
            return self.rejectCssImage(resource_index, if (err == error.TooLarge or err == error.BufferTooSmall) .response_limit else .selection);
        };
        const entry = self.resources.entries[resource_index];
        self.reportResourceTransition(resource_index, .selected, .none, self.document_url);
        self.resources.entries[resource_index].state = .running;
        var success = true;
        if (self.resource_handler.complete) |complete| success = complete(self.resource_handler.context, .{
            .generation = self.generation,
            .resource_id = entry.id,
            .node = entry.node,
            .kind = entry.kind,
            .role = .css_background,
            .requested_url = self.document_url,
            .final_url = self.document_url,
            .url = self.document_url,
            .status = 0,
            .redirected = false,
            .content_type = decoded.media_type,
            .content_security_policy = "",
            .body = decoded.bytes,
            .byte_count = decoded.bytes.len,
        });
        try self.resources.finish(resource_index, success);
        self.reportResourceTransition(resource_index, if (success) .ready else .failed, if (success) .none else .consumer, null);
        return if (success) .selected else .failed;
    }

    fn reselectImageNode(self: *WebRuntime, node: u16) Error!void {
        const document = self.document orelse return error.NotInitialized;
        const resource_index = self.imageResourceIndex(node, .content) orelse return;
        const old_entry = self.resources.entries[resource_index];
        const selection = imageSelection(document, node, self.environment);
        const reference = if (selection) |value| value.url else "";
        const old_state = &self.image_resources[resource_index];
        if (old_entry.state != .aborted and imageSelectionMatches(old_state, old_entry.id, reference)) return;
        const role = if (old_state.resource_id == old_entry.id) old_state.role else ImageRole.content;

        self.reportResourceTransition(resource_index, .replaced, .none, null);
        self.abortResourceRequest(old_entry.request_id);
        const request_required = selection != null and !isDataReference(reference);
        self.resources.entries[resource_index] = .{
            .id = self.nextResourceIdentity(),
            .generation = self.generation,
            .sequence = old_entry.sequence,
            .node = old_entry.node,
            .kind = .image,
            .script_mode = .none,
            .request_required = request_required,
        };
        self.initializeImageResource(resource_index, reference);
        self.image_resources[resource_index].role = role;

        if (selection == null) {
            try self.resources.reject(resource_index);
            self.reportResourceTransition(resource_index, .failed, .selection, null);
            self.dispatchResourceTerminalEvent(resource_index, false);
            return;
        }
        if (request_required) {
            try self.queueDiscoveredResources();
            return;
        }
        self.reportResourceTransition(resource_index, .selected, .none, self.document_url);
        try self.resources.markReady(resource_index);
        _ = try self.runReadyResources();
    }

    fn refreshResponsiveImages(self: *WebRuntime) Error!void {
        const document = self.document orelse return;
        var index: usize = 0;
        while (index < self.resources.count) : (index += 1) {
            const entry = self.resources.entries[index];
            if (entry.generation != self.generation or entry.kind != .image or entry.node >= document.node_count) continue;
            const state = self.image_resources[index];
            if (state.resource_id == entry.id and state.role != .content) continue;
            try self.reselectImageNode(entry.node);
        }
    }

    fn refreshPictureImages(self: *WebRuntime, picture: u16) Error!void {
        const document = self.document orelse return error.NotInitialized;
        if (picture >= document.node_count or document.nodes[picture].kind != .element or
            !std.ascii.eqlIgnoreCase(document.nodeName(picture), "picture")) return;
        var child = document.nodes[picture].first_child;
        while (child != html.none) {
            if (document.nodes[child].kind == .element and std.ascii.eqlIgnoreCase(document.nodeName(child), "img")) try self.reselectImageNode(child);
            child = document.nodes[child].next_sibling;
        }
    }

    fn refreshImageSelectionForMutation(self: *WebRuntime, node: u16, attribute: []const u8) Error!void {
        const document = self.document orelse return error.NotInitialized;
        if (node >= document.node_count or document.nodes[node].kind != .element) return;
        const name = document.nodeName(node);
        if (std.ascii.eqlIgnoreCase(name, "img")) {
            if (attribute.len == 0 or std.ascii.eqlIgnoreCase(attribute, "src") or
                std.ascii.eqlIgnoreCase(attribute, "srcset") or std.ascii.eqlIgnoreCase(attribute, "sizes"))
                try self.reselectImageNode(node);
            return;
        }
        if (std.ascii.eqlIgnoreCase(name, "source") and
            (attribute.len == 0 or std.ascii.eqlIgnoreCase(attribute, "srcset") or
                std.ascii.eqlIgnoreCase(attribute, "sizes") or std.ascii.eqlIgnoreCase(attribute, "media") or
                std.ascii.eqlIgnoreCase(attribute, "type")))
        {
            const parent = document.nodes[node].parent;
            if (parent != html.none) try self.refreshPictureImages(parent);
        } else if (std.ascii.eqlIgnoreCase(name, "picture")) {
            try self.refreshPictureImages(node);
        }
    }

    fn cancelImageResourcesInSubtree(self: *WebRuntime, root: u16, depth: usize) void {
        if (depth > html.max_depth) return;
        const document = self.document orelse return;
        if (root >= document.node_count) return;
        for ([_]ImageRole{ .content, .css_background }) |role| {
            if (self.imageResourceIndex(root, role)) |resource_index| {
                const entry = self.resources.entries[resource_index];
                if (!entry.state.terminal()) {
                    self.reportResourceTransition(resource_index, .replaced, .none, null);
                    self.abortResourceRequest(entry.request_id);
                    self.resources.entries[resource_index].state = .aborted;
                }
            }
        }
        var child = document.nodes[root].first_child;
        while (child != html.none) {
            self.cancelImageResourcesInSubtree(child, depth + 1);
            child = document.nodes[child].next_sibling;
        }
    }

    fn captureScriptFailure(self: *WebRuntime, err: anyerror) void {
        if (!self.javascriptRealmActive()) {
            self.last_script_phase = .host;
            self.last_script_error_name.set(@errorName(err)) catch {};
            self.last_script_source_name = .{};
            self.last_script_line = 0;
            self.last_script_column = 0;
            return;
        }
        self.last_script_phase = self.runtime.diagnosticPhase();
        const diagnostic_name = self.runtime.diagnosticErrorName();
        self.last_script_error_name.set(if (diagnostic_name.len > 0) diagnostic_name else @errorName(err)) catch {};
        self.last_script_source_name.set(self.runtime.diagnosticSourceName()) catch {};
        self.last_script_line = self.runtime.diagnosticLine();
        self.last_script_column = self.runtime.diagnosticColumn();
    }

    fn resetModules(self: *WebRuntime) void {
        self.modules = [_]ModuleLoad{.{}} ** javascript.max_modules;
        self.module_roots = [_]u8{std.math.maxInt(u8)} ** javascript.max_modules;
        self.module_root_modules = [_]u8{std.math.maxInt(u8)} ** javascript.max_modules;
        self.module_count = 0;
        self.module_root_count = 0;
    }

    fn startModuleRoot(self: *WebRuntime, resource_index: u8, name: []const u8, source: []const u8) Error!void {
        if (self.module_root_count >= self.module_roots.len) return error.ModuleLimit;
        const module_index = try self.registerModuleLoad(name, source);
        self.module_roots[self.module_root_count] = resource_index;
        self.module_root_modules[self.module_root_count] = @intCast(module_index);
        self.module_root_count += 1;
        try self.discoverModuleDependencies(module_index);
        try self.queueModuleRequests();
        try self.finishModuleGraphIfSettled();
    }

    fn registerModuleLoad(self: *WebRuntime, name: []const u8, source: []const u8) Error!usize {
        try self.ensureJavascriptRealm();
        const parsed = try navigation.parse(name);
        if (self.findModuleLoad(parsed.bytes())) |existing| {
            if (self.modules[existing].state != .registered) return error.RequestState;
            return existing;
        }
        if (self.module_count >= self.modules.len) return error.ModuleLimit;
        const index = self.module_count;
        try self.runtime.registerModule(parsed.bytes(), source);
        self.modules[index] = .{ .state = .registered, .generation = self.generation, .url = parsed };
        self.module_count += 1;
        return index;
    }

    fn discoverModuleDependencies(self: *WebRuntime, module_index: usize) Error!void {
        if (module_index >= self.module_count or self.modules[module_index].state != .registered) return error.RequestState;
        var dependencies: [javascript.max_modules][]const u8 = undefined;
        const module_name = self.modules[module_index].url.bytes();
        const count = try self.runtime.moduleDependencies(module_name, dependencies[0..]);
        for (dependencies[0..count]) |specifier| {
            if (!validModuleSpecifier(specifier)) return error.InvalidCharacter;
            const target = try navigation.resolve(&self.modules[module_index].url, specifier);
            if (self.findModuleLoad(target.bytes()) != null) continue;
            if (self.module_count >= self.modules.len) return error.ModuleLimit;
            self.modules[self.module_count] = .{
                .state = .discovered,
                .generation = self.generation,
                .url = target,
            };
            self.module_count += 1;
        }
    }

    fn queueModuleRequests(self: *WebRuntime) Error!void {
        for (self.modules[0..self.module_count], 0..) |*module, index| {
            if (module.state != .discovered) continue;
            const request_id = self.queueRequest(module.url, .script, .undefined, .undefined, .{
                .mode = .cors,
                .credentials = .same_origin,
                .module_index = @intCast(index),
            }) catch |err| {
                if (err == error.RequestLimit) return;
                module.state = .failed;
                self.failModuleGraph();
                return err;
            };
            module.request_id = request_id;
            module.state = .queued;
        }
    }

    fn completeModuleRequest(self: *WebRuntime, request: *PendingRequest) Error!void {
        const index: usize = request.module_index;
        if (index >= self.module_count or self.modules[index].generation != self.generation or self.modules[index].state != .fetching) return error.StaleGeneration;
        try self.runtime.registerModule(self.modules[index].url.bytes(), request.bodyBytes());
        self.modules[index].state = .registered;
        try self.discoverModuleDependencies(index);
        request.state = .free;
        try self.queueModuleRequests();
        try self.finishModuleGraphIfSettled();
    }

    fn finishModuleGraphIfSettled(self: *WebRuntime) Error!void {
        if (self.module_root_count == 0) return;
        for (self.modules[0..self.module_count]) |module| {
            if (module.state == .failed) {
                self.failModuleGraph();
                return;
            }
            if (module.state != .registered) return;
        }
        var success = true;
        for (self.module_root_modules[0..self.module_root_count]) |module_index| {
            if (module_index >= self.module_count) {
                success = false;
                break;
            }
            _ = self.runtime.evaluateModule(self.modules[module_index].url.bytes()) catch {
                success = false;
                break;
            };
        }
        const roots = self.module_root_count;
        self.module_root_count = 0;
        for (self.module_roots[0..roots]) |resource_index| self.finishResourceEntry(resource_index, success) catch {};
        if (!success) self.script_error_count += roots;
    }

    fn failModuleGraph(self: *WebRuntime) void {
        const roots = self.module_root_count;
        self.module_root_count = 0;
        for (self.module_roots[0..roots]) |resource_index| self.finishResourceEntry(resource_index, false) catch {};
        self.script_error_count += roots;
        for (self.modules[0..self.module_count]) |*module| {
            if (module.state != .registered) module.state = .failed;
        }
    }

    fn finishResourceEntry(self: *WebRuntime, resource_index: usize, success: bool) Error!void {
        if (resource_index >= self.resources.count or self.resources.entries[resource_index].state != .running) return;
        const entry = self.resources.entries[resource_index];
        try self.resources.finish(resource_index, success);
        self.reportResourceTransition(resource_index, if (success) .ready else .failed, if (success) .none else .consumer, null);
        self.dispatchResourceTerminalEvent(resource_index, success);
        if (entry.request_id != web_resources.no_request) {
            if (self.findRequest(entry.request_id)) |request| request.state = if (success) .free else .failed;
        }
    }

    fn findModuleLoad(self: *const WebRuntime, name: []const u8) ?usize {
        for (self.modules[0..self.module_count], 0..) |module, index| {
            if (module.generation == self.generation and std.mem.eql(u8, module.url.bytes(), name)) return index;
        }
        return null;
    }

    pub fn pump(self: *WebRuntime, now_ms: f64, maximum_jobs: usize) Error!usize {
        if (self.document == null) return error.NotInitialized;
        self.queueDiscoveredResources() catch |err| if (err != error.RequestLimit) return err;
        self.timing.now_ms = now_ms;
        if (!self.javascriptRealmActive()) return 0;
        for (&self.abort_deadlines) |*deadline| {
            if (!deadline.occupied or deadline.generation != self.generation or deadline.due_ms > now_ms) continue;
            deadline.occupied = false;
            try self.abortSignal(self.runtime, deadline.signal, try self.makeNamedError(self.runtime, "TimeoutError", "The operation timed out"));
        }
        const fallback = if (self.program_count > 0) self.programs[self.program_count - 1] orelse return error.NotInitialized else self.platform_program orelse return 0;
        var jobs = try self.runtime.drainJobs(fallback, maximum_jobs);
        const timer_capacity = maximum_jobs - jobs;
        var timers_queued: usize = 0;
        var timers_visited: usize = 0;
        const timer_scan_start = self.timer_pump_cursor;
        while (timers_queued < timer_capacity and timers_visited < self.timers.len) : (timers_visited += 1) {
            const timer_index = (timer_scan_start + timers_visited) % self.timers.len;
            const timer = &self.timers[timer_index];
            if (!timer.occupied or timer.generation != self.generation or timer.due_ms > now_ms) continue;
            try self.runtime.enqueueTask(timer.callback, .undefined);
            if (timer.interval_ms > 0) {
                timer.due_ms = now_ms + timer.interval_ms;
            } else {
                timer.occupied = false;
            }
            timers_queued += 1;
            self.timer_pump_cursor = (timer_index + 1) % self.timers.len;
        }
        if (timers_queued > 0) jobs += try self.runtime.drainJobs(fallback, timer_capacity);
        self.queueDiscoveredResources() catch |err| if (err != error.RequestLimit) return err;
        return jobs;
    }

    fn releasePrograms(self: *WebRuntime) void {
        var index: usize = 0;
        while (index < self.program_count) : (index += 1) {
            const program = self.programs[index] orelse continue;
            self.program_allocator.destroy(self.program_allocator.context, program);
            self.programs[index] = null;
        }
        self.program_count = 0;
        if (self.platform_program) |program| {
            self.program_allocator.destroy(self.program_allocator.context, program);
            self.platform_program = null;
        }
    }

    fn releaseJavascriptRealm(self: *WebRuntime) void {
        self.releasePrograms();
        const memory = self.runtime_memory orelse return;
        self.runtime.deinit();
        self.program_allocator.free(
            self.program_allocator.context,
            memory,
            @sizeOf(javascript.Runtime),
            @alignOf(javascript.Runtime),
        );
        self.runtime_memory = null;
        self.runtime = undefined;
    }

    pub fn dispatchEvent(self: *WebRuntime, target: EventTarget, name: []const u8, now_ms: f64) Error!Dispatch {
        if (self.document == null) return error.NotInitialized;
        self.timing.now_ms = now_ms;
        const serial = self.next_event_serial;
        self.next_event_serial +%= 1;
        if (self.next_event_serial == 0) self.next_event_serial = 1;
        if (!self.javascriptRealmActive()) return .{ .queued = 0, .serial = serial };
        const bubbles = !equal(name, "load") and !equal(name, "DOMContentLoaded");
        const event = try self.makeDomEvent(name, bubbles, true, true, serial);
        const root_mark = self.runtime.hostRootMark();
        defer self.runtime.restoreHostRoots(root_mark);
        try self.runtime.hostRoot(event);
        var queued: usize = 0;
        for (&self.listeners) |*listener| {
            if (!listener.occupied or listener.generation != self.generation or !equal(listener.event_name.bytes(), name) or !self.nativeListenerReceives(target, listener, bubbles)) continue;
            queued += 1;
        }
        _ = try self.dispatchDomEvent(eventTargetToken(target), try self.eventTargetValue(target), event);
        return .{ .queued = queued, .serial = serial };
    }

    pub fn eventCancelled(self: *const WebRuntime, serial: u32) bool {
        return serial != 0 and self.cancelled_event_serial == serial;
    }

    /// Re-authorizes every concrete transport target, including intermediate
    /// redirect hops, against the policy of the request's document generation.
    pub fn authorizeRequestTarget(
        self: *WebRuntime,
        generation: u32,
        kind: RequestKind,
        mode: security.RequestMode,
        url: []const u8,
    ) bool {
        if (generation != self.generation) return false;
        const decision = self.security_context.authorize(generation, url, securityKind(kind), mode);
        if (!decision.allowed) self.last_block_reason = decision.reason;
        return decision.allowed;
    }

    pub fn takeRequest(self: *WebRuntime) ?*PendingRequest {
        for (&self.requests) |*request| {
            if (request.state != .queued or request.generation != self.generation) continue;
            request.state = .in_flight;
            if (request.resource_index != std.math.maxInt(u8)) {
                const resource_index = self.resources.beginFetch(request.id, request.generation) catch {
                    request.state = .aborted;
                    continue;
                };
                self.reportResourceTransition(resource_index, .fetching, .none, null);
            }
            if (request.module_index != std.math.maxInt(u8)) {
                if (request.module_index >= self.module_count or self.modules[request.module_index].state != .queued) {
                    request.state = .aborted;
                    continue;
                }
                self.modules[request.module_index].state = .fetching;
            }
            return request;
        }
        return null;
    }

    pub fn completeRequest(self: *WebRuntime, id: u32, generation: u32, meta: ResponseMeta, body: []const u8) Error!void {
        const request = self.findRequest(id) orelse return error.RequestNotFound;
        if (generation != self.generation or request.generation != generation) {
            request.state = .aborted;
            return error.StaleGeneration;
        }
        if (request.state != .in_flight) return error.RequestState;
        if (meta.final_url.len > 0) {
            const resource_kind = securityKind(request.kind);
            const decision = self.security_context.authorize(self.generation, meta.final_url, resource_kind, request.mode);
            if (!decision.allowed) {
                request.state = .failed;
                self.last_block_reason = decision.reason;
                if (request.promise != .undefined) try self.runtime.rejectPromise(request.promise, try self.makeTypeError(self.runtime, blockText(decision.reason)));
                try self.finishXhr(request, false);
                self.failScheduledResource(request, .policy);
                self.failModuleRequest(request);
                return error.SecurityBlocked;
            }
        }
        const response_origin = if (meta.final_url.len > 0)
            security.Origin.parse(meta.final_url, self.generation) catch request.target_origin
        else
            request.target_origin;
        if (!self.security_context.acceptsCors(
            &response_origin,
            request.mode,
            request.credentials,
            meta.access_control_allow_origin,
            meta.access_control_allow_credentials,
        )) {
            request.state = .failed;
            self.last_block_reason = .cors;
            if (request.promise != .undefined) try self.runtime.rejectPromise(request.promise, try self.makeTypeError(self.runtime, "CORS blocked"));
            try self.finishXhr(request, false);
            self.failScheduledResource(request, .policy);
            self.failModuleRequest(request);
            return error.CorsBlocked;
        }
        const response_url = if (meta.final_url.len > 0) meta.final_url else request.url.bytes();
        const font_response = request.kind == .font;
        if ((!font_response and body.len > request.body.len) or
            (font_response and body.len > max_font_response_body_bytes) or
            response_url.len > request.response_url.len or
            meta.content_type.len > request.response_content_type.len or
            meta.headers.len > request.response_headers.len or
            meta.content_security_policy.len > request.response_csp.len)
        {
            self.failRequestWithFailure(id, generation, "Response too large", .response_limit) catch {};
            return error.ResponseTooLarge;
        }
        if (!font_response and body.len > 0) @memcpy(request.body[0..body.len], body);
        request.body_len = if (font_response) 0 else body.len;
        request.response_byte_count = body.len;
        request.status = meta.status;
        request.secure = meta.secure;
        request.redirected = meta.redirected;
        request.manual_redirect = meta.manual_redirect;
        @memcpy(request.response_url[0..response_url.len], response_url);
        request.response_url_len = response_url.len;
        @memcpy(request.response_content_type[0..meta.content_type.len], meta.content_type);
        request.response_content_type_len = meta.content_type.len;
        if (meta.headers.len > 0) @memcpy(request.response_headers[0..meta.headers.len], meta.headers);
        request.response_headers_len = meta.headers.len;
        if (meta.content_security_policy.len > 0) @memcpy(request.response_csp[0..meta.content_security_policy.len], meta.content_security_policy);
        request.response_csp_len = meta.content_security_policy.len;
        request.state = .complete;
        if (!meta.cookies_processed and meta.set_cookie_count > 0 and request.credentials != .omit) {
            const browser_storage = self.storage orelse return error.NotInitialized;
            var cookie_index: usize = 0;
            while (cookie_index < meta.set_cookie_count and cookie_index < meta.set_cookies.len) : (cookie_index += 1) {
                const set_cookie = meta.set_cookies[cookie_index] orelse continue;
                browser_storage.cookies.setFromHeader(&response_origin, urlPath(response_url), set_cookie) catch {};
            }
        }
        if (request.resource_index != std.math.maxInt(u8)) {
            const resource_index: usize = request.resource_index;
            self.reportResourceTransition(resource_index, .response, .none, null);
            if (request.status < 200 or request.status >= 300) {
                request.state = .failed;
                self.failScheduledResource(request, .http_status);
                return;
            }
            if (request.kind == .font and !self.consumeFontResponse(request, resource_index, body)) {
                request.state = .failed;
                _ = self.resources.failFetch(request.id, request.generation) catch {};
                self.reportResourceTransition(resource_index, .failed, .consumer, null);
                self.dispatchResourceTerminalEvent(resource_index, false);
                self.finishFontResource(resource_index, false);
                _ = self.runReadyResources() catch 0;
                self.queueDiscoveredResources() catch {};
                return;
            }
            _ = try self.resources.completeFetch(request.id, request.generation);
            _ = try self.runReadyResources();
            try self.queueDiscoveredResources();
            return;
        }
        if (request.module_index != std.math.maxInt(u8)) {
            try self.completeModuleRequest(request);
            return;
        }
        if (request.promise != .undefined) {
            const response = try self.makeResponse(request);
            try self.runtime.resolvePromise(request.promise, response);
        }
        try self.finishXhr(request, true);
    }

    pub fn failRequest(self: *WebRuntime, id: u32, generation: u32, reason: []const u8) Error!void {
        return self.failRequestWithFailure(id, generation, reason, .fetch);
    }

    pub fn failRequestPolicy(self: *WebRuntime, id: u32, generation: u32, reason: []const u8) Error!void {
        return self.failRequestWithFailure(id, generation, reason, .policy);
    }

    fn failRequestWithFailure(self: *WebRuntime, id: u32, generation: u32, reason: []const u8, failure: ResourceFailure) Error!void {
        const request = self.findRequest(id) orelse return error.RequestNotFound;
        if (generation != self.generation or request.generation != generation) {
            request.state = .aborted;
            return error.StaleGeneration;
        }
        request.state = .failed;
        if (request.resource_index != std.math.maxInt(u8)) {
            _ = self.resources.failFetch(request.id, request.generation) catch {};
            self.reportResourceTransition(request.resource_index, .failed, failure, null);
            self.dispatchResourceTerminalEvent(request.resource_index, false);
            self.finishFontResource(request.resource_index, false);
            _ = self.runReadyResources() catch 0;
            self.queueDiscoveredResources() catch {};
        }
        if (request.module_index != std.math.maxInt(u8)) self.failModuleRequest(request);
        if (request.promise != .undefined) try self.runtime.rejectPromise(request.promise, try self.makeTypeError(self.runtime, reason));
        try self.finishXhr(request, false);
    }

    pub fn takeAction(self: *WebRuntime) ?Action {
        if (self.action_count == 0) return null;
        const action = self.actions[0];
        var index: usize = 1;
        while (index < self.action_count) : (index += 1) self.actions[index - 1] = self.actions[index];
        self.action_count -= 1;
        if (action.kind == .dom_changed) self.dom_action_pending = false;
        return action;
    }

    pub fn needsReflow(self: *WebRuntime) bool {
        const result = self.dom_dirty;
        self.dom_dirty = false;
        return result;
    }

    pub fn markResponseStart(self: *WebRuntime, now_ms: f64) void {
        self.timing.response_start_ms = now_ms;
        self.timing.response_end_ms = now_ms;
        self.timing.now_ms = now_ms;
        self.refreshTimingBindings();
    }

    pub fn markDomContentLoadedStart(self: *WebRuntime, now_ms: f64) void {
        self.timing.dom_content_loaded_start_ms = now_ms;
        self.timing.now_ms = now_ms;
        self.refreshTimingBindings();
    }

    pub fn markDomContentLoadedEnd(self: *WebRuntime, now_ms: f64) void {
        self.timing.dom_content_loaded_end_ms = now_ms;
        self.timing.now_ms = now_ms;
        self.refreshTimingBindings();
    }

    pub fn markLoadStart(self: *WebRuntime, now_ms: f64) void {
        self.document_ready_state = .complete;
        self.timing.dom_complete_ms = now_ms;
        self.timing.load_event_start_ms = now_ms;
        self.timing.now_ms = now_ms;
        self.refreshTimingBindings();
    }

    pub fn markLoadComplete(self: *WebRuntime, now_ms: f64) void {
        self.document_ready_state = .complete;
        if (self.timing.dom_complete_ms == 0) self.timing.dom_complete_ms = now_ms;
        if (self.timing.load_event_start_ms == 0) self.timing.load_event_start_ms = now_ms;
        self.timing.load_event_end_ms = now_ms;
        self.timing.now_ms = now_ms;
        self.refreshTimingBindings();
    }

    fn installBindings(self: *WebRuntime) Error!void {
        const window = self.runtime.global("globalThis") orelse try self.runtime.createObject();
        const document_object = try self.runtime.createObject();
        const location = try self.runtime.createObject();
        const history = try self.runtime.createObject();
        const navigation_object = try self.runtime.createObject();
        const navigator = try self.runtime.createObject();
        const screen = try self.runtime.createObject();
        const crypto = try self.runtime.createObject();
        const subtle_crypto = try self.runtime.createObject();
        const performance = try self.runtime.createObject();
        const local_storage = try self.makeStorageObject(false);
        const session_storage = try self.makeStorageObject(true);

        try self.bind(window, "addEventListener", .add_event_listener);
        try self.bind(window, "removeEventListener", .remove_event_listener);
        try self.bind(window, "dispatchEvent", .dispatch_event);
        try self.runtime.set(window, "window", window);
        try self.runtime.set(window, "self", window);
        try self.runtime.set(window, "document", document_object);
        try self.runtime.set(window, "location", location);
        try self.runtime.set(window, "history", history);
        try self.runtime.set(window, "navigation", navigation_object);
        try self.runtime.set(window, "navigator", navigator);
        try self.runtime.set(window, "screen", screen);
        try self.runtime.set(window, "crypto", crypto);
        try self.runtime.set(window, "performance", performance);
        try self.runtime.set(window, "localStorage", local_storage);
        try self.runtime.set(window, "sessionStorage", session_storage);
        try self.runtime.set(window, "isSecureContext", .{ .boolean = self.security_context.secure_context });
        try self.runtime.set(window, "_event_target", .{ .number = @floatFromInt(eventTargetToken(.window)) });
        try self.runtime.setHostPropertyHooks(window, host_object_window, self, hostPropertyGet, hostPropertySet);

        try self.bind(document_object, "getElementById", .document_get_element_by_id);
        try self.bind(document_object, "querySelector", .document_query_selector);
        try self.bind(document_object, "querySelectorAll", .document_query_selector_all);
        try self.bind(document_object, "getElementsByTagName", .document_get_elements_by_tag_name);
        try self.bind(document_object, "getElementsByClassName", .document_get_elements_by_class_name);
        try self.bind(document_object, "createElement", .document_create_element);
        try self.bind(document_object, "createTextNode", .document_create_text_node);
        try self.bind(document_object, "addEventListener", .add_event_listener);
        try self.bind(document_object, "removeEventListener", .remove_event_listener);
        try self.bind(document_object, "dispatchEvent", .dispatch_event);
        try self.bind(document_object, "getCookie", .document_get_cookie);
        try self.bind(document_object, "setCookie", .document_set_cookie);
        try self.runtime.set(document_object, "readyState", try self.runtime.makeString("loading"));
        try self.runtime.set(document_object, "hidden", .{ .boolean = false });
        try self.runtime.set(document_object, "visibilityState", try self.runtime.makeString("visible"));
        try self.runtime.set(document_object, "URL", try self.runtime.makeString(self.document_url.bytes()));
        try self.runtime.set(document_object, "origin", try self.originString());
        try self.runtime.set(document_object, "_event_target", .{ .number = @floatFromInt(eventTargetToken(.document)) });
        try self.runtime.setHostPropertyHooks(document_object, host_object_document, self, hostPropertyGet, hostPropertySet);

        try self.runtime.set(location, "href", try self.runtime.makeString(self.document_url.bytes()));
        try self.runtime.set(location, "origin", try self.originString());
        try self.bind(location, "assign", .location_assign);
        try self.bind(location, "replace", .location_replace);
        try self.bind(location, "reload", .location_reload);
        try self.bind(location, "toString", .location_to_string);
        try self.runtime.setHostPropertyHooks(location, host_object_location, self, hostPropertyGet, hostPropertySet);

        try self.bind(history, "back", .history_back);
        try self.bind(history, "forward", .history_forward);
        try self.bind(history, "go", .history_go);
        try self.bind(history, "pushState", .history_push_state);
        try self.bind(history, "replaceState", .history_replace_state);
        try self.runtime.setHostPropertyHooks(history, host_object_history, self, hostPropertyGet, hostPropertySet);

        try self.bind(navigation_object, "entries", .navigation_entries);
        try self.bind(navigation_object, "navigate", .navigation_navigate);
        try self.bind(navigation_object, "reload", .navigation_reload);
        try self.bind(navigation_object, "back", .navigation_back);
        try self.bind(navigation_object, "forward", .navigation_forward);
        try self.bind(navigation_object, "traverseTo", .navigation_traverse_to);
        try self.bind(navigation_object, "updateCurrentEntry", .navigation_update_current_entry);
        try self.bind(navigation_object, "addEventListener", .add_event_listener);
        try self.bind(navigation_object, "removeEventListener", .remove_event_listener);
        try self.bind(navigation_object, "dispatchEvent", .dispatch_event);
        try self.runtime.set(navigation_object, "_event_target", .{ .number = @floatFromInt(eventTargetToken(.navigation)) });
        try self.runtime.setHostPropertyHooks(navigation_object, host_object_navigation, self, hostPropertyGet, hostPropertySet);

        try self.runtime.set(navigator, "userAgent", try self.runtime.makeString(self.environment.user_agent));
        try self.runtime.set(navigator, "platform", try self.runtime.makeString(self.environment.platform));
        try self.runtime.set(navigator, "language", try self.runtime.makeString(self.environment.language));
        try self.runtime.set(navigator, "languages", try self.runtime.createArray(&.{try self.runtime.makeString(self.environment.language)}));
        try self.runtime.set(navigator, "onLine", .{ .boolean = self.environment.online });
        try self.runtime.set(navigator, "maxTouchPoints", .{ .number = 0 });
        try self.runtime.set(navigator, "cookieEnabled", .{ .boolean = true });
        try self.runtime.set(navigator, "webdriver", .{ .boolean = false });
        if (self.environment.hardware_concurrency > 0) try self.runtime.set(navigator, "hardwareConcurrency", .{ .number = @floatFromInt(self.environment.hardware_concurrency) });
        try self.bind(navigator, "supports", .feature_supported);
        try self.bind(navigator, "sendBeacon", .navigator_send_beacon);

        try self.bind(crypto, "getRandomValues", .crypto_get_random_values);
        try self.bind(crypto, "randomUUID", .crypto_random_uuid);
        try self.bind(subtle_crypto, "digest", .subtle_digest);
        try self.runtime.set(crypto, "subtle", subtle_crypto);

        const screen_width = self.environment.screen_width;
        const screen_height = self.environment.screen_height;
        try self.runtime.set(screen, "width", .{ .number = @floatFromInt(screen_width) });
        try self.runtime.set(screen, "height", .{ .number = @floatFromInt(screen_height) });
        try self.runtime.set(screen, "availWidth", .{ .number = @floatFromInt(screen_width) });
        try self.runtime.set(screen, "availHeight", .{ .number = @floatFromInt(screen_height) });
        try self.runtime.set(screen, "colorDepth", .{ .number = @floatFromInt(self.environment.color_depth) });
        try self.runtime.set(screen, "pixelDepth", .{ .number = @floatFromInt(self.environment.color_depth) });
        try self.runtime.set(screen, "orientation", .null_value);
        try self.runtime.set(window, "innerWidth", .{ .number = @floatFromInt(self.environment.viewport_width) });
        try self.runtime.set(window, "innerHeight", .{ .number = @floatFromInt(self.environment.viewport_height) });
        try self.runtime.set(window, "outerWidth", .{ .number = @floatFromInt(self.environment.viewport_width) });
        try self.runtime.set(window, "outerHeight", .{ .number = @floatFromInt(self.environment.viewport_height) });
        try self.runtime.set(window, "devicePixelRatio", .{ .number = 1 });

        try self.bind(performance, "now", .performance_now);
        try self.bind(performance, "getEntries", .performance_get_entries);
        try self.bind(performance, "getEntriesByType", .performance_entries_by_type);
        try self.bind(performance, "getEntriesByName", .performance_entries_by_name);
        try self.runtime.set(performance, "timeOrigin", .{ .number = self.wallTime(self.timing.time_origin_ms) });
        const timing = try self.runtime.createObject();
        try self.runtime.set(timing, "navigationStart", .{ .number = self.timing.navigation_start_ms });
        try self.runtime.set(performance, "timing", timing);
        const legacy_navigation = try self.runtime.createObject();
        try self.runtime.set(legacy_navigation, "TYPE_NAVIGATE", .{ .number = 0 });
        try self.runtime.set(legacy_navigation, "TYPE_RELOAD", .{ .number = 1 });
        try self.runtime.set(legacy_navigation, "TYPE_BACK_FORWARD", .{ .number = 2 });
        try self.runtime.set(legacy_navigation, "TYPE_RESERVED", .{ .number = 255 });
        try self.runtime.set(legacy_navigation, "type", .{ .number = 0 });
        try self.runtime.set(legacy_navigation, "redirectCount", .{ .number = 0 });
        try self.runtime.set(performance, "navigation", legacy_navigation);

        try self.runtime.defineGlobal("window", window, true);
        try self.runtime.defineGlobal("self", window, true);
        try self.runtime.defineGlobal("this", window, true);
        try self.runtime.defineGlobal("document", document_object, true);
        try self.runtime.defineGlobal("location", location, true);
        try self.runtime.defineGlobal("history", history, true);
        try self.runtime.defineGlobal("navigation", navigation_object, true);
        try self.runtime.defineGlobal("navigator", navigator, true);
        try self.runtime.defineGlobal("screen", screen, true);
        try self.runtime.defineGlobal("crypto", crypto, true);
        try self.runtime.defineGlobal("performance", performance, true);
        try self.runtime.defineGlobal("localStorage", local_storage, true);
        try self.runtime.defineGlobal("sessionStorage", session_storage, true);
        try self.runtime.defineGlobal("fetch", try self.host(.fetch), true);
        try self.runtime.defineGlobal("XMLHttpRequest", try self.host(.xhr_constructor), true);
        const url_constructor = try self.host(.url_constructor);
        try self.runtime.setFunctionMetadata(url_constructor, "URL", 1);
        try self.bindWebMethod(url_constructor, "canParse", .url_can_parse, 1);
        try self.bindWebMethod(url_constructor, "parse", .url_parse, 1);
        const url_prototype = try self.runtime.get(url_constructor, "prototype");
        try self.bindWebMethod(url_prototype, "toString", .url_to_string, 0);
        try self.bindWebMethod(url_prototype, "toJSON", .url_to_string, 0);
        try self.bindWebAccessor(url_prototype, "href", .url_get_href, .url_set_href);
        try self.bindWebAccessor(url_prototype, "origin", .url_get_origin, null);
        try self.bindWebAccessor(url_prototype, "protocol", .url_get_protocol, .url_set_protocol);
        try self.bindWebAccessor(url_prototype, "username", .url_get_username, .url_set_username);
        try self.bindWebAccessor(url_prototype, "password", .url_get_password, .url_set_password);
        try self.bindWebAccessor(url_prototype, "host", .url_get_host, .url_set_host);
        try self.bindWebAccessor(url_prototype, "hostname", .url_get_hostname, .url_set_hostname);
        try self.bindWebAccessor(url_prototype, "port", .url_get_port, .url_set_port);
        try self.bindWebAccessor(url_prototype, "pathname", .url_get_pathname, .url_set_pathname);
        try self.bindWebAccessor(url_prototype, "search", .url_get_search, .url_set_search);
        try self.bindWebAccessor(url_prototype, "searchParams", .url_get_search_params, null);
        try self.bindWebAccessor(url_prototype, "hash", .url_get_hash, .url_set_hash);
        try self.runtime.defineGlobal("URL", url_constructor, true);
        const url_search_params_constructor = try self.host(.url_search_params_constructor);
        try self.runtime.setFunctionMetadata(url_search_params_constructor, "URLSearchParams", 0);
        const url_search_params_prototype = try self.runtime.get(url_search_params_constructor, "prototype");
        try self.bindWebMethod(url_search_params_prototype, "append", .url_search_params_append, 2);
        try self.bindWebMethod(url_search_params_prototype, "delete", .url_search_params_delete, 1);
        try self.bindWebMethod(url_search_params_prototype, "get", .url_search_params_get, 1);
        try self.bindWebMethod(url_search_params_prototype, "getAll", .url_search_params_get_all, 1);
        try self.bindWebMethod(url_search_params_prototype, "has", .url_search_params_has, 1);
        try self.bindWebMethod(url_search_params_prototype, "set", .url_search_params_set, 2);
        try self.bindWebMethod(url_search_params_prototype, "sort", .url_search_params_sort, 0);
        try self.bindWebMethod(url_search_params_prototype, "toString", .url_search_params_to_string, 0);
        try self.bindWebMethod(url_search_params_prototype, "keys", .url_search_params_keys, 0);
        try self.bindWebMethod(url_search_params_prototype, "values", .url_search_params_values, 0);
        try self.bindWebMethod(url_search_params_prototype, "entries", .url_search_params_entries, 0);
        try self.bindWebMethod(url_search_params_prototype, "forEach", .url_search_params_for_each, 1);
        try self.bindWebAccessor(url_search_params_prototype, "size", .url_search_params_get_size, null);
        const symbol = self.runtime.global("Symbol") orelse return error.TypeError;
        const iterator_key = try self.runtime.get(symbol, "iterator");
        const tag_key = try self.runtime.get(symbol, "toStringTag");
        const performance_navigation_timing_constructor = try self.runtime.createHostConstructor(@intFromEnum(HostOp.performance_navigation_timing_constructor), self, hostDispatch);
        try self.runtime.setFunctionMetadata(performance_navigation_timing_constructor, "PerformanceNavigationTiming", 0);
        const performance_navigation_timing_prototype = try self.runtime.get(performance_navigation_timing_constructor, "prototype");
        try self.bindWebMethod(performance_navigation_timing_prototype, "toJSON", .performance_entry_to_json, 0);
        try self.runtime.setKey(performance_navigation_timing_prototype, tag_key, try self.runtime.makeString("PerformanceNavigationTiming"));
        try self.runtime.defineGlobal("PerformanceNavigationTiming", performance_navigation_timing_constructor, true);
        try self.runtime.setKey(url_search_params_prototype, iterator_key, try self.runtime.get(url_search_params_prototype, "entries"));
        try self.runtime.setKey(url_prototype, tag_key, try self.runtime.makeString("URL"));
        try self.runtime.setKey(url_search_params_prototype, tag_key, try self.runtime.makeString("URLSearchParams"));
        try self.runtime.defineGlobal("URLSearchParams", url_search_params_constructor, true);
        const text_encoder_constructor = try self.host(.text_encoder_constructor);
        try self.runtime.setFunctionMetadata(text_encoder_constructor, "TextEncoder", 0);
        const text_encoder_prototype = try self.runtime.get(text_encoder_constructor, "prototype");
        try self.bindWebAccessor(text_encoder_prototype, "encoding", .text_encoder_get_encoding, null);
        try self.bindWebMethod(text_encoder_prototype, "encode", .text_encoder_encode, 0);
        try self.bindWebMethod(text_encoder_prototype, "encodeInto", .text_encoder_encode_into, 2);
        try self.runtime.setKey(text_encoder_prototype, tag_key, try self.runtime.makeString("TextEncoder"));
        try self.runtime.defineGlobal("TextEncoder", text_encoder_constructor, true);
        const text_decoder_constructor = try self.host(.text_decoder_constructor);
        try self.runtime.setFunctionMetadata(text_decoder_constructor, "TextDecoder", 0);
        const text_decoder_prototype = try self.runtime.get(text_decoder_constructor, "prototype");
        try self.bindWebAccessor(text_decoder_prototype, "encoding", .text_decoder_get_encoding, null);
        try self.bindWebAccessor(text_decoder_prototype, "fatal", .text_decoder_get_fatal, null);
        try self.bindWebAccessor(text_decoder_prototype, "ignoreBOM", .text_decoder_get_ignore_bom, null);
        try self.bindWebMethod(text_decoder_prototype, "decode", .text_decoder_decode, 0);
        try self.runtime.setKey(text_decoder_prototype, tag_key, try self.runtime.makeString("TextDecoder"));
        try self.runtime.defineGlobal("TextDecoder", text_decoder_constructor, true);
        const headers_constructor = try self.host(.headers_constructor);
        try self.runtime.setFunctionMetadata(headers_constructor, "Headers", 0);
        const headers_prototype = try self.runtime.get(headers_constructor, "prototype");
        try self.bindWebMethod(headers_prototype, "append", .headers_append, 2);
        try self.bindWebMethod(headers_prototype, "delete", .headers_delete, 1);
        try self.bindWebMethod(headers_prototype, "get", .headers_get, 1);
        try self.bindWebMethod(headers_prototype, "getSetCookie", .headers_get_set_cookie, 0);
        try self.bindWebMethod(headers_prototype, "has", .headers_has, 1);
        try self.bindWebMethod(headers_prototype, "set", .headers_set, 2);
        try self.bindWebMethod(headers_prototype, "forEach", .headers_for_each, 1);
        try self.bindWebMethod(headers_prototype, "keys", .headers_keys, 0);
        try self.bindWebMethod(headers_prototype, "values", .headers_values, 0);
        try self.bindWebMethod(headers_prototype, "entries", .headers_entries, 0);
        try self.runtime.setKey(headers_prototype, iterator_key, try self.runtime.get(headers_prototype, "entries"));
        try self.runtime.setKey(headers_prototype, tag_key, try self.runtime.makeString("Headers"));
        try self.runtime.defineGlobal("Headers", headers_constructor, true);
        const response_constructor = try self.host(.response_constructor);
        try self.runtime.setFunctionMetadata(response_constructor, "Response", 0);
        try self.bindWebMethod(response_constructor, "error", .response_error, 0);
        try self.bindWebMethod(response_constructor, "redirect", .response_redirect, 1);
        try self.bindWebMethod(response_constructor, "json", .response_json_static, 1);
        const response_prototype = try self.runtime.get(response_constructor, "prototype");
        try self.bindWebMethod(response_prototype, "clone", .response_clone, 0);
        try self.bindWebMethod(response_prototype, "text", .response_text, 0);
        try self.bindWebMethod(response_prototype, "json", .response_json, 0);
        try self.bindWebMethod(response_prototype, "bytes", .response_bytes, 0);
        try self.bindWebMethod(response_prototype, "arrayBuffer", .response_array_buffer, 0);
        try self.bindWebAccessor(response_prototype, "type", .response_get_type, null);
        try self.bindWebAccessor(response_prototype, "url", .response_get_url, null);
        try self.bindWebAccessor(response_prototype, "redirected", .response_get_redirected, null);
        try self.bindWebAccessor(response_prototype, "status", .response_get_status, null);
        try self.bindWebAccessor(response_prototype, "ok", .response_get_ok, null);
        try self.bindWebAccessor(response_prototype, "statusText", .response_get_status_text, null);
        try self.bindWebAccessor(response_prototype, "headers", .response_get_headers, null);
        try self.bindWebAccessor(response_prototype, "body", .response_get_body, null);
        try self.bindWebAccessor(response_prototype, "bodyUsed", .response_get_body_used, null);
        try self.runtime.setKey(response_prototype, tag_key, try self.runtime.makeString("Response"));
        try self.runtime.defineGlobal("Response", response_constructor, true);
        const abort_signal_constructor = try self.runtime.createHostConstructor(@intFromEnum(HostOp.abort_signal_throw_if_aborted), self, hostDispatch);
        try self.runtime.setFunctionMetadata(abort_signal_constructor, "AbortSignal", 0);
        try self.bindWebMethod(abort_signal_constructor, "abort", .abort_signal_abort_static, 0);
        try self.bindWebMethod(abort_signal_constructor, "timeout", .abort_signal_timeout_static, 1);
        try self.bindWebMethod(abort_signal_constructor, "any", .abort_signal_any_static, 1);
        const abort_signal_prototype = try self.runtime.get(abort_signal_constructor, "prototype");
        try self.bindWebMethod(abort_signal_prototype, "throwIfAborted", .abort_signal_throw_if_aborted, 0);
        try self.bindWebMethod(abort_signal_prototype, "addEventListener", .abort_signal_add_event_listener, 2);
        try self.bindWebMethod(abort_signal_prototype, "removeEventListener", .abort_signal_remove_event_listener, 2);
        try self.bindWebAccessor(abort_signal_prototype, "aborted", .abort_signal_get_aborted, null);
        try self.bindWebAccessor(abort_signal_prototype, "reason", .abort_signal_get_reason, null);
        try self.bindWebAccessor(abort_signal_prototype, "onabort", .abort_signal_get_onabort, .abort_signal_set_onabort);
        try self.runtime.setKey(abort_signal_prototype, tag_key, try self.runtime.makeString("AbortSignal"));
        try self.runtime.defineGlobal("AbortSignal", abort_signal_constructor, true);
        const abort_controller_constructor = try self.host(.abort_controller_constructor);
        try self.runtime.setFunctionMetadata(abort_controller_constructor, "AbortController", 0);
        const abort_controller_prototype = try self.runtime.get(abort_controller_constructor, "prototype");
        try self.bindWebMethod(abort_controller_prototype, "abort", .abort_controller_abort, 0);
        try self.bindWebAccessor(abort_controller_prototype, "signal", .abort_controller_get_signal, null);
        try self.runtime.setKey(abort_controller_prototype, tag_key, try self.runtime.makeString("AbortController"));
        try self.runtime.defineGlobal("AbortController", abort_controller_constructor, true);
        const request_constructor = try self.host(.request_constructor);
        try self.runtime.setFunctionMetadata(request_constructor, "Request", 1);
        const request_prototype = try self.runtime.get(request_constructor, "prototype");
        try self.bindWebMethod(request_prototype, "clone", .request_clone, 0);
        try self.bindWebMethod(request_prototype, "text", .request_text, 0);
        try self.bindWebMethod(request_prototype, "json", .request_json, 0);
        try self.bindWebMethod(request_prototype, "bytes", .request_bytes, 0);
        try self.bindWebMethod(request_prototype, "arrayBuffer", .request_array_buffer, 0);
        try self.bindWebAccessor(request_prototype, "method", .request_get_method, null);
        try self.bindWebAccessor(request_prototype, "url", .request_get_url, null);
        try self.bindWebAccessor(request_prototype, "headers", .request_get_headers, null);
        try self.bindWebAccessor(request_prototype, "destination", .request_get_destination, null);
        try self.bindWebAccessor(request_prototype, "referrer", .request_get_referrer, null);
        try self.bindWebAccessor(request_prototype, "referrerPolicy", .request_get_referrer_policy, null);
        try self.bindWebAccessor(request_prototype, "mode", .request_get_mode, null);
        try self.bindWebAccessor(request_prototype, "credentials", .request_get_credentials, null);
        try self.bindWebAccessor(request_prototype, "cache", .request_get_cache, null);
        try self.bindWebAccessor(request_prototype, "redirect", .request_get_redirect, null);
        try self.bindWebAccessor(request_prototype, "integrity", .request_get_integrity, null);
        try self.bindWebAccessor(request_prototype, "keepalive", .request_get_keepalive, null);
        try self.bindWebAccessor(request_prototype, "signal", .request_get_signal, null);
        try self.bindWebAccessor(request_prototype, "duplex", .request_get_duplex, null);
        try self.bindWebAccessor(request_prototype, "body", .request_get_body, null);
        try self.bindWebAccessor(request_prototype, "bodyUsed", .request_get_body_used, null);
        try self.runtime.setKey(request_prototype, tag_key, try self.runtime.makeString("Request"));
        try self.runtime.defineGlobal("Request", request_constructor, true);
        const count_strategy_constructor = try self.host(.count_queuing_strategy_constructor);
        try self.runtime.setFunctionMetadata(count_strategy_constructor, "CountQueuingStrategy", 1);
        const count_strategy_prototype = try self.runtime.get(count_strategy_constructor, "prototype");
        try self.bindWebAccessor(count_strategy_prototype, "highWaterMark", .queuing_strategy_get_high_water_mark, null);
        try self.bindWebAccessor(count_strategy_prototype, "size", .count_queuing_strategy_get_size, null);
        try self.runtime.setKey(count_strategy_prototype, tag_key, try self.runtime.makeString("CountQueuingStrategy"));
        try self.runtime.defineGlobal("CountQueuingStrategy", count_strategy_constructor, true);
        const byte_strategy_constructor = try self.host(.byte_length_queuing_strategy_constructor);
        try self.runtime.setFunctionMetadata(byte_strategy_constructor, "ByteLengthQueuingStrategy", 1);
        const byte_strategy_prototype = try self.runtime.get(byte_strategy_constructor, "prototype");
        try self.bindWebAccessor(byte_strategy_prototype, "highWaterMark", .queuing_strategy_get_high_water_mark, null);
        try self.bindWebAccessor(byte_strategy_prototype, "size", .byte_length_queuing_strategy_get_size, null);
        try self.runtime.setKey(byte_strategy_prototype, tag_key, try self.runtime.makeString("ByteLengthQueuingStrategy"));
        try self.runtime.defineGlobal("ByteLengthQueuingStrategy", byte_strategy_constructor, true);
        const mutation_observer_constructor = try self.host(.mutation_observer_constructor);
        try self.runtime.setFunctionMetadata(mutation_observer_constructor, "MutationObserver", 1);
        const mutation_observer_prototype = try self.runtime.get(mutation_observer_constructor, "prototype");
        try self.bindWebMethod(mutation_observer_prototype, "observe", .mutation_observer_observe, 2);
        try self.bindWebMethod(mutation_observer_prototype, "disconnect", .mutation_observer_disconnect, 0);
        try self.bindWebMethod(mutation_observer_prototype, "takeRecords", .mutation_observer_take_records, 0);
        try self.runtime.setKey(mutation_observer_prototype, tag_key, try self.runtime.makeString("MutationObserver"));
        try self.runtime.defineGlobal("MutationObserver", mutation_observer_constructor, true);
        const event_constructor = try self.host(.event_constructor);
        try self.runtime.setFunctionMetadata(event_constructor, "Event", 1);
        const event_prototype = try self.runtime.get(event_constructor, "prototype");
        try self.bindWebMethod(event_prototype, "preventDefault", .event_prevent_default, 0);
        try self.bindWebMethod(event_prototype, "stopPropagation", .event_stop_propagation, 0);
        try self.bindWebMethod(event_prototype, "stopImmediatePropagation", .event_stop_immediate_propagation, 0);
        try self.runtime.setKey(event_prototype, tag_key, try self.runtime.makeString("Event"));
        try self.runtime.defineGlobal("Event", event_constructor, true);
        try self.runtime.defineGlobal("setTimeout", try self.host(.set_timeout), true);
        try self.runtime.defineGlobal("clearTimeout", try self.host(.clear_timeout), true);
        try self.runtime.defineGlobal("setInterval", try self.host(.set_interval), true);
        try self.runtime.defineGlobal("clearInterval", try self.host(.clear_interval), true);
        try self.runtime.defineGlobal("addEventListener", try self.host(.add_event_listener), true);
        try self.runtime.defineGlobal("removeEventListener", try self.host(.remove_event_listener), true);
        try self.runtime.defineGlobal("dispatchEvent", try self.host(.dispatch_event), true);
        try self.runtime.defineGlobal("isSecureContext", .{ .boolean = self.security_context.secure_context }, true);
        const window_globals = [_][]const u8{
            "Object",        "Function",        "Boolean",        "Symbol",               "Error",                     "EvalError",         "RangeError",    "ReferenceError",              "SyntaxError", "TypeError",    "URIError",          "AggregateError",
            "Number",        "BigInt",          "Math",           "Date",                 "String",                    "RegExp",            "Array",         "Map",                         "Set",         "WeakMap",      "WeakSet",           "Iterator",
            "Promise",       "Proxy",           "Reflect",        "JSON",                 "ArrayBuffer",               "SharedArrayBuffer", "Atomics",       "DataView",                    "Int8Array",   "Uint8Array",   "Uint8ClampedArray", "Int16Array",
            "Uint16Array",   "Int32Array",      "Uint32Array",    "Float16Array",         "Float32Array",              "Float64Array",      "BigInt64Array", "BigUint64Array",              "parseFloat",  "parseInt",     "isNaN",             "eval",
            "atob",          "btoa",            "queueMicrotask", "queueTask",            "fetch",                     "XMLHttpRequest",    "URL",           "URLSearchParams",             "TextEncoder", "TextDecoder",  "Headers",           "Response",
            "Request",       "AbortController", "AbortSignal",    "CountQueuingStrategy", "ByteLengthQueuingStrategy", "MutationObserver",  "Event",         "PerformanceNavigationTiming", "setTimeout",  "clearTimeout", "setInterval",       "clearInterval",
            "dispatchEvent",
        };
        for (window_globals) |name| {
            if (self.runtime.global(name)) |value| try self.runtime.set(window, name, value);
        }
        self.refreshTimingBindings();
    }

    fn makeStorageObject(self: *WebRuntime, session: bool) Error!javascript.Value {
        const object = try self.runtime.createObject();
        try self.runtime.set(object, "_session", .{ .boolean = session });
        try self.bind(object, "getItem", .storage_get);
        try self.bind(object, "setItem", .storage_set);
        try self.bind(object, "removeItem", .storage_remove);
        try self.bind(object, "clear", .storage_clear);
        try self.bind(object, "key", .storage_key);
        const browser_storage = self.storage orelse return error.NotInitialized;
        const area = if (session)
            try browser_storage.session.area(&self.security_context.document_origin)
        else
            try browser_storage.local.area(&self.security_context.document_origin);
        try self.runtime.set(object, "length", .{ .number = @floatFromInt(area.count()) });
        try self.runtime.setHostPropertyHooks(
            object,
            if (session) host_object_session_storage else host_object_local_storage,
            self,
            hostPropertyGet,
            hostPropertySet,
        );
        return object;
    }

    fn makeNode(self: *WebRuntime, node: u16) Error!javascript.Value {
        const document = self.document orelse return error.NotInitialized;
        if (node >= document.node_count) return error.InvalidNode;
        if (node == 0) return self.runtime.global("document") orelse error.NotInitialized;
        if (self.node_objects[node] != .undefined) return self.node_objects[node];
        const object = try self.runtime.createObject();
        self.node_objects[node] = object;
        errdefer self.node_objects[node] = .undefined;
        try self.runtime.set(object, "_node", .{ .number = @floatFromInt(node) });
        try self.runtime.set(object, "nodeName", try self.runtime.makeString(document.nodeName(node)));
        try self.runtime.set(object, "id", try self.runtime.makeString(document.attribute(node, "id") orelse ""));
        var text_buffer: [2048]u8 = undefined;
        const text_content = document.textContent(node, text_buffer[0..]) catch "";
        try self.runtime.set(object, "textContent", try self.runtime.makeString(text_content));
        try self.bind(object, "getAttribute", .node_get_attribute);
        try self.bind(object, "setAttribute", .node_set_attribute);
        try self.bind(object, "hasAttribute", .node_has_attribute);
        try self.bind(object, "removeAttribute", .node_remove_attribute);
        try self.bind(object, "toggleAttribute", .node_toggle_attribute);
        try self.bind(object, "appendChild", .node_append_child);
        try self.bind(object, "insertBefore", .node_insert_before);
        try self.bind(object, "removeChild", .node_remove_child);
        try self.bind(object, "replaceChild", .node_replace_child);
        try self.bind(object, "remove", .node_remove);
        try self.bind(object, "cloneNode", .node_clone_node);
        try self.bind(object, "contains", .node_contains);
        try self.bind(object, "hasChildNodes", .node_has_child_nodes);
        try self.bind(object, "querySelector", .node_query_selector);
        try self.bind(object, "querySelectorAll", .node_query_selector_all);
        try self.bind(object, "matches", .node_matches);
        try self.bind(object, "closest", .node_closest);
        try self.bind(object, "replaceText", .node_replace_text);
        try self.bind(object, "addEventListener", .node_add_event_listener);
        try self.bind(object, "removeEventListener", .remove_event_listener);
        try self.bind(object, "dispatchEvent", .dispatch_event);
        try self.bind(object, "submit", .form_submit);
        if (document.nodes[node].kind == .element and std.ascii.eqlIgnoreCase(document.nodeName(node), "canvas")) {
            try self.bind(object, "getContext", .canvas_get_context);
        }
        try self.runtime.set(object, "_event_target", .{ .number = @floatFromInt(eventTargetToken(.{ .node = node })) });
        try self.runtime.setHostPropertyHooks(object, host_object_node_base + node, self, hostPropertyGet, hostPropertySet);
        return object;
    }

    fn canvasForNode(self: *WebRuntime, node: u16) Error!*web_canvas.Surface {
        const document = self.document orelse return error.NotInitialized;
        if (node >= document.node_count or !std.ascii.eqlIgnoreCase(document.nodeName(node), "canvas")) return error.TypeError;
        const width = canvasDimension(document.attribute(node, "width"), 300);
        const height = canvasDimension(document.attribute(node, "height"), 150);
        return self.canvases.ensure(node, width, height);
    }

    fn makeCanvasContext(self: *WebRuntime, node: u16) Error!javascript.Value {
        _ = try self.canvasForNode(node);
        var surface_index: usize = 0;
        while (surface_index < self.canvases.surfaces.len and self.canvases.surfaces[surface_index].node != node) : (surface_index += 1) {}
        if (surface_index >= self.canvas_contexts.len) return error.SurfaceLimit;
        if (self.canvas_contexts[surface_index] != .undefined) return self.canvas_contexts[surface_index];
        const object = try self.runtime.createObject();
        self.canvas_contexts[surface_index] = object;
        errdefer self.canvas_contexts[surface_index] = .undefined;
        try self.runtime.setHostPropertyHooks(object, host_object_canvas_context_base + @as(u16, @intCast(surface_index)), self, hostPropertyGet, hostPropertySet);
        try self.runtime.setHostState(object, host_object_canvas_context_base + @as(u16, @intCast(surface_index)), .{ .number = @floatFromInt(node) }, .undefined);
        try self.bind(object, "fillRect", .canvas_fill_rect);
        try self.bind(object, "clearRect", .canvas_clear_rect);
        try self.bind(object, "beginPath", .canvas_begin_path);
        try self.bind(object, "moveTo", .canvas_move_to);
        try self.bind(object, "lineTo", .canvas_line_to);
        try self.bind(object, "stroke", .canvas_stroke);
        try self.bind(object, "fillText", .canvas_fill_text);
        try self.bind(object, "translate", .canvas_translate);
        try self.bind(object, "scale", .canvas_scale);
        try self.bind(object, "rotate", .canvas_rotate);
        try self.bind(object, "save", .canvas_save);
        try self.bind(object, "restore", .canvas_restore);
        try self.bind(object, "setTransform", .canvas_set_transform);
        try self.bind(object, "getImageData", .canvas_get_image_data);
        try self.bind(object, "putImageData", .canvas_put_image_data);
        return object;
    }

    fn receiverCanvas(self: *WebRuntime, runtime: *javascript.Runtime, receiver: javascript.Value) Error!*web_canvas.Surface {
        var index: usize = 0;
        while (index < self.canvas_contexts.len) : (index += 1) {
            if (!runtime.sameValue(self.canvas_contexts[index], receiver)) continue;
            return self.canvasForNode(self.canvases.surfaces[index].node);
        }
        return error.TypeError;
    }

    fn canvasImageData(self: *WebRuntime, surface: *web_canvas.Surface, x: i32, y: i32, width: u32, height: u32) Error!javascript.Value {
        if (width == 0 or height == 0 or width > web_canvas.max_dimension or height > web_canvas.max_dimension) return error.SizeLimit;
        const byte_count = @as(usize, width) * height * 4;
        const memory = self.program_allocator.allocate(self.program_allocator.context, byte_count, 1) orelse return error.ScriptAllocation;
        defer self.program_allocator.free(self.program_allocator.context, memory, byte_count, 1);
        @memset(memory[0..byte_count], 0);
        const view = self.canvases.view(surface.node) orelse return error.InvalidSurface;
        var row: u32 = 0;
        while (row < height) : (row += 1) {
            var column: u32 = 0;
            while (column < width) : (column += 1) {
                const source_x = x + @as(i32, @intCast(column));
                const source_y = y + @as(i32, @intCast(row));
                if (source_x < 0 or source_y < 0 or source_x >= view.width or source_y >= view.height) continue;
                const pixel = view.pixels[@as(usize, @intCast(source_y)) * view.width + @as(usize, @intCast(source_x))];
                const target = (@as(usize, row) * width + column) * 4;
                memory[target] = @truncate(pixel >> 16);
                memory[target + 1] = @truncate(pixel >> 8);
                memory[target + 2] = @truncate(pixel);
                memory[target + 3] = 255;
            }
        }
        const object = try self.runtime.createObject();
        try self.runtime.set(object, "width", .{ .number = @floatFromInt(width) });
        try self.runtime.set(object, "height", .{ .number = @floatFromInt(height) });
        try self.runtime.set(object, "data", try self.runtime.createUint8Array(memory[0..byte_count]));
        return object;
    }

    fn putCanvasImageData(self: *WebRuntime, surface: *web_canvas.Surface, value: javascript.Value, x: i32, y: i32) Error!void {
        const data = try self.runtime.get(value, "data");
        const width_value = try self.runtime.valueNumber(try self.runtime.get(value, "width"));
        const height_value = try self.runtime.valueNumber(try self.runtime.get(value, "height"));
        if (width_value <= 0 or height_value <= 0 or width_value > web_canvas.max_dimension or height_value > web_canvas.max_dimension) return error.SizeLimit;
        const width: u32 = @intFromFloat(width_value);
        const height: u32 = @intFromFloat(height_value);
        const byte_count = @as(usize, width) * height * 4;
        const memory = self.program_allocator.allocate(self.program_allocator.context, byte_count, 1) orelse return error.ScriptAllocation;
        defer self.program_allocator.free(self.program_allocator.context, memory, byte_count, 1);
        const source = try self.runtime.copyBufferSource(data, memory[0..byte_count]);
        if (source.len != byte_count) return error.TypeError;
        var row: u32 = 0;
        while (row < height) : (row += 1) {
            var column: u32 = 0;
            while (column < width) : (column += 1) {
                const target_x = x + @as(i32, @intCast(column));
                const target_y = y + @as(i32, @intCast(row));
                if (target_x < 0 or target_y < 0) continue;
                const source_offset = (@as(usize, row) * width + column) * 4;
                const pixel = (@as(u32, memory[source_offset]) << 16) | (@as(u32, memory[source_offset + 1]) << 8) | memory[source_offset + 2];
                self.canvases.setPixel(surface, @intCast(target_x), @intCast(target_y), pixel);
            }
        }
    }

    fn frameInfo(self: *WebRuntime, node: u16) ?FrameInfo {
        const inspect = self.frame_lookup.inspect orelse return null;
        return inspect(self.frame_lookup.context, self.security_context.document_origin, self.generation, node);
    }

    fn makeFrameDocument(self: *WebRuntime, node: u16, info: FrameInfo) Error!javascript.Value {
        if (!info.same_origin) return .null_value;
        if (self.frame_document_objects[node] != .undefined) {
            const document = self.frame_document_objects[node];
            try self.runtime.set(document, "URL", try self.runtime.makeString(info.url.bytes()));
            try self.runtime.set(document, "readyState", try self.runtime.makeString(if (info.complete) "complete" else "loading"));
            return document;
        }
        const document = try self.runtime.createObject();
        const root_mark = self.runtime.hostRootMark();
        defer self.runtime.restoreHostRoots(root_mark);
        try self.runtime.hostRoot(document);
        try self.bind(document, "getElementById", .frame_document_get_element_by_id);
        try self.bind(document, "querySelector", .frame_document_query_selector);
        try self.runtime.setHostPropertyHooks(document, host_object_frame_document, self, hostPropertyGet, null);
        try self.runtime.setHostState(document, host_object_frame_document, .{ .number = @floatFromInt(node) }, .undefined);
        try self.runtime.set(document, "URL", try self.runtime.makeString(info.url.bytes()));
        try self.runtime.set(document, "readyState", try self.runtime.makeString(if (info.complete) "complete" else "loading"));
        try self.runtime.set(document, "nodeType", .{ .number = 9 });
        self.frame_document_objects[node] = document;
        return document;
    }

    fn makeFrameWindow(self: *WebRuntime, node: u16, info: FrameInfo) Error!javascript.Value {
        if (self.frame_window_objects[node] != .undefined) {
            const window = self.frame_window_objects[node];
            const document = try self.makeFrameDocument(node, info);
            try self.runtime.setHostState(window, host_object_frame_window, .{ .boolean = info.same_origin }, document);
            return window;
        }
        const window = try self.runtime.createObject();
        const root_mark = self.runtime.hostRootMark();
        defer self.runtime.restoreHostRoots(root_mark);
        try self.runtime.hostRoot(window);
        const document = try self.makeFrameDocument(node, info);
        try self.runtime.hostRoot(document);
        try self.runtime.setHostPropertyHooks(window, host_object_frame_window, self, hostPropertyGet, null);
        try self.runtime.setHostState(window, host_object_frame_window, .{ .boolean = info.same_origin }, document);
        try self.runtime.set(window, "closed", .{ .boolean = false });
        try self.runtime.set(window, "self", window);
        self.frame_window_objects[node] = window;
        return window;
    }

    fn makeFrameNode(self: *WebRuntime, iframe_node: u16, child_node: u16) Error!javascript.Value {
        const info = self.frameInfo(iframe_node) orelse return .null_value;
        const document = info.document orelse return .null_value;
        if (!info.same_origin or child_node >= document.node_count) return .null_value;
        for (&self.frame_node_objects) |*entry| {
            if (entry.object != .undefined and entry.iframe_node == iframe_node and entry.child_node == child_node) return entry.object;
        }
        var free: ?*FrameNodeCache = null;
        for (&self.frame_node_objects) |*entry| {
            if (entry.object == .undefined) {
                free = entry;
                break;
            }
        }
        const entry = free orelse return error.ScriptLimit;
        const object = try self.runtime.createObject();
        const root_mark = self.runtime.hostRootMark();
        defer self.runtime.restoreHostRoots(root_mark);
        try self.runtime.hostRoot(object);
        try self.bind(object, "getAttribute", .frame_node_get_attribute);
        try self.bind(object, "setAttribute", .frame_node_set_attribute);
        try self.runtime.setHostPropertyHooks(object, host_object_frame_node, self, hostPropertyGet, hostPropertySet);
        try self.runtime.setHostState(object, host_object_frame_node, .{ .number = @floatFromInt(iframe_node) }, .{ .number = @floatFromInt(child_node) });
        entry.* = .{ .iframe_node = iframe_node, .child_node = child_node, .object = object };
        return object;
    }

    fn frameNodes(self: *WebRuntime, runtime: *javascript.Runtime, object: javascript.Value, expected_tag: u16) Error!struct { iframe: u16, child: u16, document: *html.Document, child_runtime: ?*WebRuntime } {
        const state = try runtime.hostState(object, expected_tag);
        const iframe_number = try runtime.valueNumber(state[0]);
        const child_number = try runtime.valueNumber(state[1]);
        if (iframe_number < 0 or iframe_number >= html.max_nodes or child_number < 0 or child_number >= html.max_nodes) return error.InvalidNode;
        const iframe: u16 = @intFromFloat(iframe_number);
        const child: u16 = @intFromFloat(child_number);
        const info = self.frameInfo(iframe) orelse return error.StaleGeneration;
        if (!info.same_origin) return error.SecurityBlocked;
        const document = info.document orelse return error.StaleGeneration;
        if (child >= document.node_count) return error.InvalidNode;
        return .{ .iframe = iframe, .child = child, .document = document, .child_runtime = info.runtime };
    }

    fn domQueryMatches(document: *const html.Document, node: u16, query: DomQuery) bool {
        if (node >= document.node_count or document.nodes[node].kind != .element) return false;
        return switch (query) {
            .selector => |selector| css.matchesSelector(document, node, selector),
            .tag => |tag| equal(tag, "*") or std.ascii.eqlIgnoreCase(document.nodeName(node), tag),
            .class => |wanted| blk: {
                const actual = document.attribute(node, "class") orelse break :blk false;
                var tokens = std.mem.tokenizeAny(u8, wanted, " \t\r\n\x0c");
                var any = false;
                while (tokens.next()) |token| {
                    any = true;
                    var classes = std.mem.tokenizeAny(u8, actual, " \t\r\n\x0c");
                    var found = false;
                    while (classes.next()) |class_name| if (equal(class_name, token)) {
                        found = true;
                        break;
                    };
                    if (!found) break :blk false;
                }
                break :blk any;
            },
        };
    }

    fn collectDomNodes(self: *WebRuntime, document: *const html.Document, parent: u16, query: DomQuery, values: *[html.max_nodes]javascript.Value, count: *usize, depth: usize) Error!void {
        if (depth > html.max_depth or parent >= document.node_count) return error.InvalidNode;
        var child = document.nodes[parent].first_child;
        while (child != html.none) {
            if (child >= document.node_count) return error.InvalidNode;
            const next = document.nodes[child].next_sibling;
            if (domQueryMatches(document, child, query)) {
                values[count.*] = try self.makeNode(child);
                count.* += 1;
            }
            try self.collectDomNodes(document, child, query, values, count, depth + 1);
            child = next;
        }
    }

    fn makeDomNodeList(self: *WebRuntime, root: u16, query: DomQuery) Error!javascript.Value {
        const document = self.document orelse return error.NotInitialized;
        var values: [html.max_nodes]javascript.Value = undefined;
        var count: usize = 0;
        try self.collectDomNodes(document, root, query, &values, &count, 0);
        return self.runtime.createArray(values[0..count]);
    }

    fn makeChildNodeList(self: *WebRuntime, parent: u16, elements_only: bool) Error!javascript.Value {
        const document = self.document orelse return error.NotInitialized;
        if (parent >= document.node_count) return error.InvalidNode;
        var values: [html.max_nodes]javascript.Value = undefined;
        var count: usize = 0;
        var child = document.nodes[parent].first_child;
        while (child != html.none) : (child = document.nodes[child].next_sibling) {
            if (child >= document.node_count) return error.InvalidNode;
            if (!elements_only or document.nodes[child].kind == .element) {
                values[count] = try self.makeNode(child);
                count += 1;
            }
        }
        return self.runtime.createArray(values[0..count]);
    }

    fn adjacentElement(document: *const html.Document, node: u16, previous: bool) ?u16 {
        var cursor = if (previous) document.previousSibling(node) else if (node < document.node_count and document.nodes[node].next_sibling != html.none) document.nodes[node].next_sibling else null;
        while (cursor) |candidate| {
            if (candidate >= document.node_count) return null;
            if (document.nodes[candidate].kind == .element) return candidate;
            cursor = if (previous) document.previousSibling(candidate) else if (document.nodes[candidate].next_sibling != html.none) document.nodes[candidate].next_sibling else null;
        }
        return null;
    }

    fn edgeElementChild(document: *const html.Document, parent: u16, last: bool) ?u16 {
        if (parent >= document.node_count) return null;
        var child = document.nodes[parent].first_child;
        var result: ?u16 = null;
        while (child != html.none and child < document.node_count) : (child = document.nodes[child].next_sibling) {
            if (document.nodes[child].kind == .element) {
                if (!last) return child;
                result = child;
            }
        }
        return result;
    }

    fn domNodeName(document: *const html.Document, node: u16) []const u8 {
        if (node >= document.node_count) return "";
        return switch (document.nodes[node].kind) {
            .document => "#document",
            .doctype => document.nodeName(node),
            .element => document.nodeName(node),
            .text => "#text",
            .comment => "#comment",
        };
    }

    fn domNodeType(document: *const html.Document, node: u16) u8 {
        if (node >= document.node_count) return 0;
        return switch (document.nodes[node].kind) {
            .element => 1,
            .text => 3,
            .comment => 8,
            .document => 9,
            .doctype => 10,
        };
    }

    fn firstDomNode(self: *WebRuntime, root: u16, query: DomQuery) Error!?u16 {
        const document = self.document orelse return error.NotInitialized;
        var cursors: [html.max_depth]u16 = undefined;
        var depth: usize = 0;
        cursors[0] = document.nodes[root].first_child;
        while (true) {
            const child = cursors[depth];
            if (child == html.none) {
                if (depth == 0) return null;
                depth -= 1;
                continue;
            }
            if (child >= document.node_count) return error.InvalidNode;
            cursors[depth] = document.nodes[child].next_sibling;
            if (domQueryMatches(document, child, query)) return child;
            if (document.nodes[child].first_child != html.none) {
                if (depth + 1 >= cursors.len) return error.InvalidNode;
                depth += 1;
                cursors[depth] = document.nodes[child].first_child;
            }
        }
    }

    fn markDomChanged(self: *WebRuntime, node: u16) Error!void {
        self.dom_dirty = true;
        if (self.dom_action_pending) return;
        try self.enqueueAction(.dom_changed, null, node);
        self.dom_action_pending = true;
    }

    fn scheduleDynamicResources(self: *WebRuntime, root: u16, depth: usize) Error!void {
        if (!self.resources.parsing_complete or depth > html.max_depth) return;
        const document = self.document orelse return error.NotInitialized;
        if (!self.resources.containsNode(root)) {
            if (web_resources.resourceKind(document, root)) |kind| {
                if (kind != .script or executableScript(document, root)) {
                    const external = switch (kind) {
                        .script => document.attribute(root, "src") != null,
                        .image => if (imageSelection(document, root, self.environment)) |selection| !isDataReference(selection.url) else false,
                        .stylesheet => document.attribute(root, "href") != null,
                        .subdocument => document.attribute(root, "src") != null,
                        .font => false,
                    };
                    const script_mode = if (kind == .script) web_resources.classifyScript(document, root, true) else .none;
                    const resource_index = try self.resources.discover(root, kind, script_mode, external);
                    if (kind == .image) self.initializeImageResource(resource_index, if (imageSelection(document, root, self.environment)) |selection| selection.url else "");
                    if (!external) {
                        self.reportResourceTransition(resource_index, .selected, .none, self.document_url);
                        if (kind == .script and !self.security_context.allowsInlineScript(document.attribute(root, "nonce") orelse "")) {
                            self.last_block_reason = .content_security_policy;
                            self.script_error_count += 1;
                            try self.resources.reject(resource_index);
                            self.reportResourceTransition(resource_index, .failed, .policy, self.document_url);
                        } else try self.resources.markReady(resource_index);
                    }
                }
            }
        }
        try self.refreshImageSelectionForMutation(root, "");
        var child = document.nodes[root].first_child;
        while (child != html.none) {
            try self.scheduleDynamicResources(child, depth + 1);
            child = document.nodes[child].next_sibling;
        }
        try self.queueDiscoveredResources();
    }

    fn observerIndex(self: *WebRuntime, runtime: *javascript.Runtime, receiver: javascript.Value) Error!usize {
        _ = self;
        const state = try runtime.hostState(receiver, host_object_mutation_observer);
        const number = try runtime.valueNumber(state[0]);
        if (number < 0 or number >= max_mutation_observers) return error.TypeError;
        return @intFromFloat(number);
    }

    fn mutationTarget(self: *WebRuntime, runtime: *javascript.Runtime, value: javascript.Value) Error!u16 {
        if (runtime.global("document")) |document_object| if (runtime.sameValue(value, document_object)) return 0;
        return self.receiverNode(value);
    }

    fn mutationOption(runtime: *javascript.Runtime, options: javascript.Value, name: []const u8) Error!bool {
        const value = try runtime.get(options, name);
        return value != .undefined and runtime.valueBoolean(value);
    }

    fn parseMutationRegistration(self: *WebRuntime, runtime: *javascript.Runtime, target: u16, options: javascript.Value) Error!MutationRegistration {
        _ = self;
        if (options != .cell) return error.TypeError;
        var registration = MutationRegistration{ .target = target };
        registration.child_list = try mutationOption(runtime, options, "childList");
        const attributes_value = try runtime.get(options, "attributes");
        const attributes_present = attributes_value != .undefined;
        registration.attributes = attributes_present and runtime.valueBoolean(attributes_value);
        const character_data_value = try runtime.get(options, "characterData");
        const character_data_present = character_data_value != .undefined;
        registration.character_data = character_data_present and runtime.valueBoolean(character_data_value);
        registration.subtree = try mutationOption(runtime, options, "subtree");
        registration.attribute_old_value = try mutationOption(runtime, options, "attributeOldValue");
        registration.character_data_old_value = try mutationOption(runtime, options, "characterDataOldValue");

        const filter = try runtime.get(options, "attributeFilter");
        if (filter != .undefined) {
            if (filter != .cell) return error.TypeError;
            registration.attribute_filter_present = true;
            const length_number = try runtime.valueNumber(try runtime.get(filter, "length"));
            if (length_number < 0 or length_number > max_attribute_filter_names or @floor(length_number) != length_number) return error.TypeError;
            registration.attribute_filter_count = @intFromFloat(length_number);
            for (0..registration.attribute_filter_count) |index| {
                var key_buffer: [24]u8 = undefined;
                const key = std.fmt.bufPrint(key_buffer[0..], "{d}", .{index}) catch return error.TypeError;
                const source = try coercedText(runtime, try runtime.get(filter, key));
                var lower: [64]u8 = undefined;
                if (source.len > lower.len) return error.TypeError;
                for (source, 0..) |character, offset| lower[offset] = std.ascii.toLower(character);
                try registration.attribute_filter[index].set(lower[0..source.len]);
            }
        }
        if (attributes_present and !registration.attributes and (registration.attribute_old_value or registration.attribute_filter_present)) return error.TypeError;
        if (!attributes_present and (registration.attribute_old_value or registration.attribute_filter_present)) registration.attributes = true;
        if (character_data_present and !registration.character_data and registration.character_data_old_value) return error.TypeError;
        if (!character_data_present and registration.character_data_old_value) registration.character_data = true;
        if (!registration.child_list and !registration.attributes and !registration.character_data) return error.TypeError;
        return registration;
    }

    fn registrationAccepts(document: *const html.Document, registration: *const MutationRegistration, transient_match: bool, kind: MutationKind, target: u16, attribute_name: ?[]const u8) bool {
        if (registration.target != target and !(registration.subtree and (document.contains(registration.target, target) or transient_match))) return false;
        switch (kind) {
            .child_list => if (!registration.child_list) return false,
            .attributes => {
                if (!registration.attributes) return false;
                if (registration.attribute_filter_present) {
                    const wanted = attribute_name orelse return false;
                    var included = false;
                    for (registration.attribute_filter[0..registration.attribute_filter_count]) |filter| if (std.ascii.eqlIgnoreCase(filter.bytes(), wanted)) {
                        included = true;
                        break;
                    };
                    if (!included) return false;
                }
            },
            .character_data => if (!registration.character_data) return false,
        }
        return true;
    }

    fn transientMutationMatch(document: *const html.Document, observer: *const MutationObserverState, registration_index: usize, target: u16) bool {
        for (observer.transient_roots[0..observer.transient_root_count]) |transient| {
            if (transient.registration == registration_index and document.contains(transient.root, target)) return true;
        }
        return false;
    }

    fn makeMutationRecord(
        self: *WebRuntime,
        kind: MutationKind,
        target: u16,
        added: []const u16,
        removed: []const u16,
        previous: ?u16,
        next: ?u16,
        attribute_name: ?[]const u8,
        old_value: ?[]const u8,
    ) Error!javascript.Value {
        const root_mark = self.runtime.hostRootMark();
        defer self.runtime.restoreHostRoots(root_mark);
        const record = try self.runtime.createObject();
        try self.runtime.hostRoot(record);
        try self.runtime.set(record, "type", try self.runtime.makeString(switch (kind) {
            .attributes => "attributes",
            .character_data => "characterData",
            .child_list => "childList",
        }));
        try self.runtime.set(record, "target", try self.makeNode(target));
        if (added.len > html.max_nodes or removed.len > html.max_nodes) return error.MutationLimit;
        var added_values: [html.max_nodes]javascript.Value = undefined;
        for (added, 0..) |node, index| added_values[index] = try self.makeNode(node);
        const added_nodes = try self.runtime.createArray(added_values[0..added.len]);
        try self.runtime.hostRoot(added_nodes);
        try self.runtime.set(record, "addedNodes", added_nodes);
        var removed_values: [html.max_nodes]javascript.Value = undefined;
        for (removed, 0..) |node, index| removed_values[index] = try self.makeNode(node);
        const removed_nodes = try self.runtime.createArray(removed_values[0..removed.len]);
        try self.runtime.hostRoot(removed_nodes);
        try self.runtime.set(record, "removedNodes", removed_nodes);
        try self.runtime.set(record, "previousSibling", if (previous) |node| try self.makeNode(node) else .null_value);
        try self.runtime.set(record, "nextSibling", if (next) |node| try self.makeNode(node) else .null_value);
        try self.runtime.set(record, "attributeName", if (attribute_name) |value| try self.runtime.makeString(value) else .null_value);
        try self.runtime.set(record, "attributeNamespace", .null_value);
        try self.runtime.set(record, "oldValue", if (old_value) |value| try self.runtime.makeString(value) else .null_value);
        return record;
    }

    fn queueMutation(
        self: *WebRuntime,
        kind: MutationKind,
        target: u16,
        added: []const u16,
        removed: []const u16,
        previous: ?u16,
        next: ?u16,
        attribute_name: ?[]const u8,
        old_value: ?[]const u8,
    ) Error!void {
        const document = self.document orelse return error.NotInitialized;
        for (&self.mutation_observers, 0..) |*observer, observer_index| {
            if (!observer.occupied) continue;
            var matched = false;
            var include_old_value = false;
            var transient_registrations: [max_mutation_registrations]bool = [_]bool{false} ** max_mutation_registrations;
            for (observer.registrations[0..observer.registration_count], 0..) |*registration, registration_index| {
                if (registrationAccepts(document, registration, transientMutationMatch(document, observer, registration_index, target), kind, target, attribute_name)) {
                    matched = true;
                    include_old_value = include_old_value or switch (kind) {
                        .attributes => registration.attribute_old_value,
                        .character_data => registration.character_data_old_value,
                        .child_list => false,
                    };
                    transient_registrations[registration_index] = kind == .child_list and registration.subtree;
                }
            }
            if (!matched) continue;
            if (observer.record_count >= observer.records.len) return error.MutationLimit;
            observer.records[observer.record_count] = try self.makeMutationRecord(kind, target, added, removed, previous, next, attribute_name, if (include_old_value) old_value else null);
            observer.record_count += 1;
            if (kind == .child_list) for (transient_registrations, 0..) |transient, registration_index| if (transient) for (removed) |removed_node| {
                if (observer.transient_root_count >= observer.transient_roots.len) return error.MutationLimit;
                observer.transient_roots[observer.transient_root_count] = .{ .root = removed_node, .registration = registration_index };
                observer.transient_root_count += 1;
            };
            if (!observer.delivery_queued) {
                observer.delivery_queued = true;
                try self.runtime.enqueueMicrotask(observer.delivery, .{ .number = @floatFromInt(observer_index) });
            }
        }
    }

    fn takeMutationRecords(self: *WebRuntime, observer: *MutationObserverState) Error!javascript.Value {
        const records = try self.runtime.createArray(observer.records[0..observer.record_count]);
        for (observer.records[0..observer.record_count]) |*record| record.* = .undefined;
        observer.record_count = 0;
        return records;
    }

    fn mutateTextContent(self: *WebRuntime, node: u16, value: []const u8) Error!void {
        const document = self.document orelse return error.NotInitialized;
        if (node >= document.node_count) return error.InvalidNode;
        if (document.nodes[node].kind == .text or document.nodes[node].kind == .comment) {
            const old_value = document.nodeValue(node);
            try document.setTextContent(node, value);
            try self.queueMutation(.character_data, node, &.{}, &.{}, null, null, null, old_value);
            return;
        }
        var removed: [html.max_nodes]u16 = undefined;
        var removed_count: usize = 0;
        var child = document.nodes[node].first_child;
        while (child != html.none) : (child = document.nodes[child].next_sibling) {
            if (child >= document.node_count) return error.InvalidNode;
            removed[removed_count] = child;
            removed_count += 1;
        }
        try document.setTextContent(node, value);
        var added: [1]u16 = undefined;
        const added_nodes = if (document.nodes[node].first_child != html.none) blk: {
            added[0] = document.nodes[node].first_child;
            break :blk added[0..1];
        } else added[0..0];
        try self.queueMutation(.child_list, node, added_nodes, removed[0..removed_count], null, null, null, null);
    }

    fn makeStyleObject(self: *WebRuntime, node: u16) Error!javascript.Value {
        const document = self.document orelse return error.NotInitialized;
        if (node >= document.node_count) return error.InvalidNode;
        const object = try self.runtime.createObject();
        const source = document.attribute(node, "style") orelse "";
        try self.runtime.set(object, "cssText", try self.runtime.makeString(source));
        var declarations = std.mem.splitScalar(u8, source, ';');
        while (declarations.next()) |raw_declaration| {
            const declaration = std.mem.trim(u8, raw_declaration, " \t\r\n");
            const colon = std.mem.indexOfScalar(u8, declaration, ':') orelse continue;
            const raw_name = std.mem.trim(u8, declaration[0..colon], " \t\r\n");
            const value = std.mem.trim(u8, declaration[colon + 1 ..], " \t\r\n");
            if (raw_name.len == 0) continue;
            try self.runtime.set(object, raw_name, try self.runtime.makeString(value));
            var camel_name: [96]u8 = undefined;
            var camel_len: usize = 0;
            var uppercase_next = false;
            for (raw_name) |character| {
                if (character == '-') {
                    uppercase_next = camel_len > 0;
                    continue;
                }
                if (camel_len >= camel_name.len) break;
                camel_name[camel_len] = if (uppercase_next) std.ascii.toUpper(character) else character;
                camel_len += 1;
                uppercase_next = false;
            }
            if (camel_len > 0 and !std.mem.eql(u8, camel_name[0..camel_len], raw_name)) {
                try self.runtime.set(object, camel_name[0..camel_len], try self.runtime.makeString(value));
            }
        }
        return object;
    }

    fn makeUrlObject(self: *WebRuntime, url: navigation.Url) Error!javascript.Value {
        const object = try self.runtime.createObject();
        if (self.runtime.global("URL")) |constructor| try self.runtime.setPrototype(object, try self.runtime.get(constructor, "prototype"));
        try self.runtime.setHostPropertyHooks(object, host_object_url, self, hostPropertyGet, hostPropertySet);
        const href = try self.runtime.makeString(url.bytes());
        try self.runtime.setHostState(object, host_object_url, href, .undefined);
        const parsed = try web_url.parts(url.bytes());
        const search_params = try self.makeUrlSearchParams(parsed.search, object);
        try self.runtime.setHostState(object, host_object_url, href, search_params);
        return object;
    }

    fn navigationEntryKey(self: *const WebRuntime, index: usize, out: []u8) Error![]const u8 {
        if (index >= self.history_count) return error.InvalidValue;
        return std.fmt.bufPrint(out, "r4-{d}", .{self.history_ids[index]}) catch return error.StringLimit;
    }

    fn makeNavigationEntry(self: *WebRuntime, index: usize) Error!javascript.Value {
        if (index >= self.history_count) return error.InvalidValue;
        if (self.navigation_entry_objects[index] != .undefined) return self.navigation_entry_objects[index];
        const entry = try self.makeNavigationEntryValue(self.history_urls[index], self.history_states[index], self.history_ids[index], index, self.history_same_document[index]);
        self.navigation_entry_objects[index] = entry;
        return entry;
    }

    fn makeNavigationEntryValue(self: *WebRuntime, url: navigation.Url, state: javascript.Value, entry_id: u64, index: usize, same_document: bool) Error!javascript.Value {
        const entry = try self.runtime.createObject();
        const root_mark = self.runtime.hostRootMark();
        defer self.runtime.restoreHostRoots(root_mark);
        try self.runtime.hostRoot(entry);
        var key_buffer: [48]u8 = undefined;
        const key = std.fmt.bufPrint(key_buffer[0..], "r4-{d}", .{entry_id}) catch return error.StringLimit;
        try self.runtime.set(entry, "url", try self.runtime.makeString(url.bytes()));
        try self.runtime.set(entry, "key", try self.runtime.makeString(key));
        try self.runtime.set(entry, "id", try self.runtime.makeString(key));
        try self.runtime.set(entry, "index", .{ .number = @floatFromInt(index) });
        try self.runtime.set(entry, "sameDocument", .{ .boolean = same_document });
        try self.runtime.setHostPropertyHooks(entry, host_object_navigation_entry, self, null, null);
        try self.runtime.setHostState(entry, host_object_navigation_entry, state, .{ .number = @floatFromInt(index) });
        try self.bind(entry, "getState", .navigation_entry_get_state);
        return entry;
    }

    fn dispatchNavigationEvent(self: *WebRuntime, name: []const u8, target: navigation.Url, destination_index: ?usize, navigation_type: []const u8, cancelable: bool) Error!bool {
        const navigation_object = self.runtime.global("navigation") orelse return true;
        const event = try self.makeDomEvent(name, false, cancelable, false, 0);
        const root_mark = self.runtime.hostRootMark();
        defer self.runtime.restoreHostRoots(root_mark);
        try self.runtime.hostRoot(event);
        try self.runtime.set(event, "navigationType", try self.runtime.makeString(navigation_type));
        const destination = if (destination_index) |index|
            try self.makeNavigationEntry(index)
        else
            try self.makeNavigationEntryValue(target, .null_value, self.next_history_id, self.history_index, std.mem.eql(u8, target.bytes(), self.document_url.bytes()));
        try self.runtime.hostRoot(destination);
        try self.runtime.set(event, "destination", destination);
        try self.runtime.set(event, "canIntercept", .{ .boolean = false });
        try self.runtime.set(event, "downloadRequest", .null_value);
        try self.runtime.set(event, "info", .undefined);
        return self.dispatchDomEvent(eventTargetToken(.navigation), navigation_object, event);
    }

    fn makePerformanceNavigationEntry(self: *WebRuntime) Error!javascript.Value {
        const root_mark = self.runtime.hostRootMark();
        defer self.runtime.restoreHostRoots(root_mark);
        const entry = if (self.performance_navigation_entry == .undefined)
            try self.runtime.createObject()
        else
            self.performance_navigation_entry;
        try self.runtime.hostRoot(entry);
        if (self.performance_navigation_entry == .undefined) {
            if (self.runtime.global("PerformanceNavigationTiming")) |constructor| try self.runtime.setPrototype(entry, try self.runtime.get(constructor, "prototype"));
            try self.runtime.setHostPropertyHooks(entry, host_object_performance_navigation_timing, self, null, null);
        }
        const relative = struct {
            fn at(origin: f64, value: f64) f64 {
                return if (value == 0) 0 else @max(0, value - origin);
            }
        }.at;
        try self.runtime.set(entry, "name", try self.runtime.makeString(self.document_url.bytes()));
        try self.runtime.set(entry, "entryType", try self.runtime.makeString("navigation"));
        try self.runtime.set(entry, "startTime", .{ .number = 0 });
        try self.runtime.set(entry, "duration", .{ .number = relative(self.timing.navigation_start_ms, self.timing.load_event_end_ms) });
        try self.runtime.set(entry, "initiatorType", try self.runtime.makeString("navigation"));
        try self.runtime.set(entry, "nextHopProtocol", try self.runtime.makeString(if (self.document_url.scheme == .https) "http/1.1" else if (self.document_url.scheme == .http) "http/1.1" else ""));
        try self.runtime.set(entry, "workerStart", .{ .number = 0 });
        try self.runtime.set(entry, "redirectStart", .{ .number = 0 });
        try self.runtime.set(entry, "redirectEnd", .{ .number = 0 });
        try self.runtime.set(entry, "fetchStart", .{ .number = relative(self.timing.navigation_start_ms, self.timing.fetch_start_ms) });
        try self.runtime.set(entry, "domainLookupStart", .{ .number = 0 });
        try self.runtime.set(entry, "domainLookupEnd", .{ .number = 0 });
        try self.runtime.set(entry, "connectStart", .{ .number = 0 });
        try self.runtime.set(entry, "secureConnectionStart", .{ .number = 0 });
        try self.runtime.set(entry, "connectEnd", .{ .number = 0 });
        try self.runtime.set(entry, "requestStart", .{ .number = relative(self.timing.navigation_start_ms, self.timing.request_start_ms) });
        try self.runtime.set(entry, "responseStart", .{ .number = relative(self.timing.navigation_start_ms, self.timing.response_start_ms) });
        try self.runtime.set(entry, "responseEnd", .{ .number = relative(self.timing.navigation_start_ms, self.timing.response_end_ms) });
        try self.runtime.set(entry, "transferSize", .{ .number = 0 });
        try self.runtime.set(entry, "encodedBodySize", .{ .number = 0 });
        try self.runtime.set(entry, "decodedBodySize", .{ .number = 0 });
        try self.runtime.set(entry, "unloadEventStart", .{ .number = 0 });
        try self.runtime.set(entry, "unloadEventEnd", .{ .number = 0 });
        try self.runtime.set(entry, "domInteractive", .{ .number = relative(self.timing.navigation_start_ms, self.timing.dom_interactive_ms) });
        try self.runtime.set(entry, "domContentLoadedEventStart", .{ .number = relative(self.timing.navigation_start_ms, self.timing.dom_content_loaded_start_ms) });
        try self.runtime.set(entry, "domContentLoadedEventEnd", .{ .number = relative(self.timing.navigation_start_ms, self.timing.dom_content_loaded_end_ms) });
        try self.runtime.set(entry, "domComplete", .{ .number = relative(self.timing.navigation_start_ms, self.timing.dom_complete_ms) });
        try self.runtime.set(entry, "loadEventStart", .{ .number = relative(self.timing.navigation_start_ms, self.timing.load_event_start_ms) });
        try self.runtime.set(entry, "loadEventEnd", .{ .number = relative(self.timing.navigation_start_ms, self.timing.load_event_end_ms) });
        try self.runtime.set(entry, "type", try self.runtime.makeString("navigate"));
        try self.runtime.set(entry, "redirectCount", .{ .number = 0 });
        try self.runtime.set(entry, "criticalCHRestart", .{ .number = 0 });
        try self.runtime.set(entry, "notRestoredReasons", .null_value);
        self.performance_navigation_entry = entry;
        return entry;
    }

    fn makeSingleValueArray(self: *WebRuntime, value: javascript.Value) Error!javascript.Value {
        const root_mark = self.runtime.hostRootMark();
        defer self.runtime.restoreHostRoots(root_mark);
        try self.runtime.hostRoot(value);
        return self.runtime.createArray(&.{value});
    }

    fn makeNavigationResult(self: *WebRuntime, entry: javascript.Value) Error!javascript.Value {
        const root_mark = self.runtime.hostRootMark();
        defer self.runtime.restoreHostRoots(root_mark);
        try self.runtime.hostRoot(entry);
        const committed = try self.runtime.createPromise();
        try self.runtime.hostRoot(committed);
        const finished = try self.runtime.createPromise();
        try self.runtime.hostRoot(finished);
        try self.runtime.resolvePromise(committed, entry);
        try self.runtime.resolvePromise(finished, entry);
        const result = try self.runtime.createObject();
        try self.runtime.hostRoot(result);
        try self.runtime.set(result, "committed", committed);
        try self.runtime.set(result, "finished", finished);
        return result;
    }

    fn makeFailedNavigationResult(self: *WebRuntime, message: []const u8) Error!javascript.Value {
        const root_mark = self.runtime.hostRootMark();
        defer self.runtime.restoreHostRoots(root_mark);
        const reason = try self.makeNamedError(self.runtime, "AbortError", message);
        try self.runtime.hostRoot(reason);
        const committed = try self.runtime.createPromise();
        try self.runtime.hostRoot(committed);
        const finished = try self.runtime.createPromise();
        try self.runtime.hostRoot(finished);
        try self.runtime.rejectPromise(committed, reason);
        try self.runtime.rejectPromise(finished, reason);
        const result = try self.runtime.createObject();
        try self.runtime.hostRoot(result);
        try self.runtime.set(result, "committed", committed);
        try self.runtime.set(result, "finished", finished);
        return result;
    }

    fn updateSameDocumentHistory(self: *WebRuntime, replace: bool, target: navigation.Url, state: javascript.Value) Error!void {
        if (replace) {
            self.history_urls[self.history_index] = target;
            self.history_states[self.history_index] = state;
            self.history_same_document[self.history_index] = true;
            if (self.navigation_entry_objects[self.history_index] != .undefined) {
                const entry = self.navigation_entry_objects[self.history_index];
                try self.runtime.set(entry, "url", try self.runtime.makeString(target.bytes()));
                try self.runtime.set(entry, "sameDocument", .{ .boolean = true });
                try self.runtime.setHostState(entry, host_object_navigation_entry, state, .{ .number = @floatFromInt(self.history_index) });
            }
        } else {
            if (self.history_index + 1 < self.history_count) self.history_count = self.history_index + 1;
            if (self.history_count < self.history_urls.len) {
                self.history_index = self.history_count;
                self.history_count += 1;
            } else {
                var index: usize = 1;
                while (index < self.history_urls.len) : (index += 1) {
                    self.history_urls[index - 1] = self.history_urls[index];
                    self.history_states[index - 1] = self.history_states[index];
                    self.history_same_document[index - 1] = self.history_same_document[index];
                    self.history_ids[index - 1] = self.history_ids[index];
                    self.navigation_entry_objects[index - 1] = self.navigation_entry_objects[index];
                    if (self.navigation_entry_objects[index - 1] != .undefined) {
                        try self.runtime.set(self.navigation_entry_objects[index - 1], "index", .{ .number = @floatFromInt(index - 1) });
                        try self.runtime.setHostState(self.navigation_entry_objects[index - 1], host_object_navigation_entry, self.history_states[index - 1], .{ .number = @floatFromInt(index - 1) });
                    }
                }
                self.history_index = self.history_urls.len - 1;
            }
            self.history_urls[self.history_index] = target;
            self.history_states[self.history_index] = state;
            self.history_same_document[self.history_index] = true;
            self.history_ids[self.history_index] = self.next_history_id;
            self.next_history_id +%= 1;
            self.navigation_entry_objects[self.history_index] = .undefined;
        }
        self.document_url = target;
    }

    fn makeUrlSearchParams(self: *WebRuntime, query: []const u8, owner: javascript.Value) Error!javascript.Value {
        var params = try web_url.SearchParams.init(query);
        var serialized: [web_url.max_query_bytes]u8 = undefined;
        const object = try self.runtime.createObject();
        if (self.runtime.global("URLSearchParams")) |constructor| try self.runtime.setPrototype(object, try self.runtime.get(constructor, "prototype"));
        try self.runtime.setHostPropertyHooks(object, host_object_url_search_params, self, hostPropertyGet, hostPropertySet);
        try self.runtime.setHostState(object, host_object_url_search_params, try self.runtime.makeString(try params.serialize(serialized[0..])), owner);
        return object;
    }

    fn constructorUrl(self: *WebRuntime, arguments: []const javascript.Value) Error!navigation.Url {
        if (arguments.len == 0) return error.TypeError;
        const input = try coercedText(self.runtime, arguments[0]);
        if (arguments.len < 2 or arguments[1] == .undefined) return navigation.parse(input);
        const base = try navigation.parse(try coercedText(self.runtime, arguments[1]));
        return navigation.resolve(&base, input);
    }

    fn searchParamsFromInit(self: *WebRuntime, runtime: *javascript.Runtime, init: javascript.Value) Error!web_url.SearchParams {
        _ = self;
        if (init == .undefined) return web_url.SearchParams.init("");
        if (init != .cell) return web_url.SearchParams.init(try coercedText(runtime, init));
        const existing = runtime.hostState(init, host_object_url_search_params) catch null;
        if (existing) |state| {
            if (state[0] != .string) return error.TypeError;
            return web_url.SearchParams.init(runtime.valueString(state[0]));
        }

        var params = try web_url.SearchParams.init("");
        const program = runtime.activeProgram() orelse return error.TypeError;
        const symbol = runtime.global("Symbol") orelse return error.TypeError;
        const iterator_key = try runtime.get(symbol, "iterator");
        const iterator = runtime.getKey(init, iterator_key) catch .undefined;
        if (iterator != .undefined and iterator != .null_value) {
            const array_constructor = runtime.global("Array") orelse return error.TypeError;
            const array_from = try runtime.get(array_constructor, "from");
            const sequence = try runtime.callValue(program, array_from, array_constructor, &.{init});
            const length_number = try runtime.valueNumber(try runtime.get(sequence, "length"));
            if (length_number < 0 or length_number > web_url.max_pairs) return error.TypeError;
            const length: usize = @intFromFloat(length_number);
            for (0..length) |index| {
                var key_buffer: [24]u8 = undefined;
                const key = std.fmt.bufPrint(key_buffer[0..], "{d}", .{index}) catch return error.TypeError;
                const pair_init = try runtime.get(sequence, key);
                if (pair_init != .cell) return error.TypeError;
                const pair = try runtime.callValue(program, array_from, array_constructor, &.{pair_init});
                if (pair != .cell) return error.TypeError;
                const pair_length = try runtime.valueNumber(try runtime.get(pair, "length"));
                if (pair_length != 2) return error.TypeError;
                const name = try runtime.get(pair, "0");
                const value = try runtime.get(pair, "1");
                try params.append(try coercedText(runtime, name), try coercedText(runtime, value));
            }
            return params;
        }

        const object_constructor = runtime.global("Object") orelse return error.TypeError;
        const keys_function = try runtime.get(object_constructor, "keys");
        const keys = try runtime.callValue(program, keys_function, object_constructor, &.{init});
        const count_value = try runtime.get(keys, "length");
        const count: usize = @intFromFloat(try runtime.valueNumber(count_value));
        if (count > web_url.max_pairs) return error.TypeError;
        for (0..count) |index| {
            var key_buffer: [24]u8 = undefined;
            const index_key = std.fmt.bufPrint(key_buffer[0..], "{d}", .{index}) catch return error.TypeError;
            const key_value = try runtime.get(keys, index_key);
            const key = try coercedText(runtime, key_value);
            try params.append(key, try coercedText(runtime, try runtime.get(init, key)));
        }
        return params;
    }

    fn urlSearchParams(self: *WebRuntime, runtime: *javascript.Runtime, receiver: javascript.Value) Error!web_url.SearchParams {
        _ = self;
        const state = try runtime.hostState(receiver, host_object_url_search_params);
        const query = state[0];
        if (query != .string) return error.TypeError;
        return web_url.SearchParams.init(runtime.valueString(query));
    }

    fn updateUrlSearchParams(self: *WebRuntime, runtime: *javascript.Runtime, receiver: javascript.Value, params: *const web_url.SearchParams) Error!void {
        _ = self;
        var serialized: [web_url.max_query_bytes]u8 = undefined;
        const query = try params.serialize(serialized[0..]);
        const state = try runtime.hostState(receiver, host_object_url_search_params);
        const query_value = try runtime.makeString(query);
        const owner = state[1];
        try runtime.setHostState(receiver, host_object_url_search_params, query_value, owner);
        if (owner != .cell) return;
        const owner_state = runtime.hostState(owner, host_object_url) catch return;
        const href_value = owner_state[0];
        if (href_value != .string) return;
        var candidate: [navigation.url_capacity + 1]u8 = undefined;
        const replaced = try web_url.replaceComponent(runtime.valueString(href_value), .search, query, candidate[0..]);
        const normalized = try navigation.parse(replaced);
        try runtime.setHostState(owner, host_object_url, try runtime.makeString(normalized.bytes()), owner_state[1]);
    }

    fn syncUrlParamsFromHref(self: *WebRuntime, runtime: *javascript.Runtime, object: javascript.Value, href: []const u8) Error!void {
        _ = self;
        const state = try runtime.hostState(object, host_object_url);
        const params_object = state[1];
        if (params_object != .cell) return;
        const parsed = try web_url.parts(href);
        var params = try web_url.SearchParams.init(parsed.search);
        var serialized: [web_url.max_query_bytes]u8 = undefined;
        const params_state = try runtime.hostState(params_object, host_object_url_search_params);
        try runtime.setHostState(params_object, host_object_url_search_params, try runtime.makeString(try params.serialize(serialized[0..])), params_state[1]);
    }

    fn makeUrlSearchParamsIterator(self: *WebRuntime, params: javascript.Value, operation: HostOp) Error!javascript.Value {
        const tag: u16 = switch (operation) {
            .url_search_params_keys => host_object_url_search_params_keys,
            .url_search_params_values => host_object_url_search_params_values,
            .url_search_params_entries => host_object_url_search_params_entries,
            else => return error.TypeError,
        };
        const object = try self.runtime.createObject();
        if (self.runtime.global("Iterator")) |constructor| try self.runtime.setPrototype(object, try self.runtime.get(constructor, "prototype"));
        try self.runtime.setHostPropertyHooks(object, tag, self, null, null);
        try self.runtime.setHostState(object, tag, params, .{ .number = 0 });
        try self.bindWebMethod(object, "next", .url_search_params_iterator_next, 0);
        const symbol = self.runtime.global("Symbol") orelse return error.TypeError;
        try self.runtime.setKey(object, try self.runtime.get(symbol, "toStringTag"), try self.runtime.makeString("URLSearchParams Iterator"));
        return object;
    }

    fn makeTextEncoder(self: *WebRuntime) Error!javascript.Value {
        const object = try self.runtime.createObject();
        if (self.runtime.global("TextEncoder")) |constructor| try self.runtime.setPrototype(object, try self.runtime.get(constructor, "prototype"));
        try self.runtime.setHostPropertyHooks(object, host_object_text_encoder, self, null, null);
        return object;
    }

    fn makeTextDecoder(self: *WebRuntime, encoding: web_encoding.Encoding, fatal: bool, ignore_bom: bool) Error!javascript.Value {
        const object = try self.runtime.createObject();
        if (self.runtime.global("TextDecoder")) |constructor| try self.runtime.setPrototype(object, try self.runtime.get(constructor, "prototype"));
        try self.runtime.setHostPropertyHooks(object, host_object_text_decoder, self, null, null);
        const decoder = web_encoding.Decoder.init(encoding, fatal, ignore_bom);
        try self.runtime.setHostState(object, host_object_text_decoder, .{ .number = @floatFromInt(decoder.packState()) }, .{ .number = @floatFromInt(self.generation) });
        return object;
    }

    fn textDecoder(self: *WebRuntime, runtime: *javascript.Runtime, receiver: javascript.Value) Error!web_encoding.Decoder {
        const state = try runtime.hostState(receiver, host_object_text_decoder);
        const packed_number = try runtime.valueNumber(state[0]);
        const generation_number = try runtime.valueNumber(state[1]);
        if (packed_number < 0 or generation_number != @as(f64, @floatFromInt(self.generation))) return error.TypeError;
        return web_encoding.Decoder.fromPackedState(@intFromFloat(packed_number));
    }

    fn storeTextDecoder(self: *WebRuntime, runtime: *javascript.Runtime, receiver: javascript.Value, decoder: *const web_encoding.Decoder) Error!void {
        try runtime.setHostState(receiver, host_object_text_decoder, .{ .number = @floatFromInt(decoder.packState()) }, .{ .number = @floatFromInt(self.generation) });
    }

    fn makeHeaders(self: *WebRuntime, serialized: []const u8) Error!javascript.Value {
        const root_mark = self.runtime.hostRootMark();
        defer self.runtime.restoreHostRoots(root_mark);
        const object = try self.runtime.createObject();
        try self.runtime.hostRoot(object);
        if (self.runtime.global("Headers")) |constructor| try self.runtime.setPrototype(object, try self.runtime.get(constructor, "prototype"));
        try self.runtime.setHostPropertyHooks(object, host_object_headers, self, null, null);
        const state = try self.runtime.makeString(serialized);
        try self.runtime.hostRoot(state);
        try self.runtime.setHostState(object, host_object_headers, state, .undefined);
        return object;
    }

    fn headers(self: *WebRuntime, runtime: *javascript.Runtime, receiver: javascript.Value) Error!web_fetch.Headers {
        _ = self;
        const state = try runtime.hostState(receiver, host_object_headers);
        if (state[0] != .string) return error.TypeError;
        return web_fetch.Headers.init(runtime.valueString(state[0]));
    }

    fn storeHeaders(self: *WebRuntime, runtime: *javascript.Runtime, receiver: javascript.Value, headers_value: *const web_fetch.Headers) Error!void {
        _ = self;
        var serialized: [web_fetch.max_serialized_bytes]u8 = undefined;
        const state = try runtime.hostState(receiver, host_object_headers);
        try runtime.setHostState(receiver, host_object_headers, try runtime.makeString(try headers_value.serialize(serialized[0..])), state[1]);
    }

    fn headersFromInit(self: *WebRuntime, runtime: *javascript.Runtime, init: javascript.Value) Error!web_fetch.Headers {
        _ = self;
        if (init == .undefined) return web_fetch.Headers.init("");
        if (init == .cell) {
            if (runtime.hostState(init, host_object_headers) catch null) |state| {
                if (state[0] != .string) return error.TypeError;
                return web_fetch.Headers.init(runtime.valueString(state[0]));
            }
        }
        if (init != .cell) return error.TypeError;
        var headers_value = try web_fetch.Headers.init("");
        const program = runtime.activeProgram() orelse return error.TypeError;
        const symbol = runtime.global("Symbol") orelse return error.TypeError;
        const iterator = runtime.getKey(init, try runtime.get(symbol, "iterator")) catch .undefined;
        if (iterator != .undefined and iterator != .null_value) {
            const array_constructor = runtime.global("Array") orelse return error.TypeError;
            const array_from = try runtime.get(array_constructor, "from");
            const sequence = try runtime.callValue(program, array_from, array_constructor, &.{init});
            const length_number = try runtime.valueNumber(try runtime.get(sequence, "length"));
            if (length_number < 0 or length_number > web_fetch.max_headers) return error.TypeError;
            const length: usize = @intFromFloat(length_number);
            for (0..length) |index| {
                var key_buffer: [24]u8 = undefined;
                const key = std.fmt.bufPrint(key_buffer[0..], "{d}", .{index}) catch return error.TypeError;
                const pair = try runtime.callValue(program, array_from, array_constructor, &.{try runtime.get(sequence, key)});
                if (try runtime.valueNumber(try runtime.get(pair, "length")) != 2) return error.TypeError;
                try headers_value.append(try coercedText(runtime, try runtime.get(pair, "0")), try coercedText(runtime, try runtime.get(pair, "1")));
            }
            return headers_value;
        }
        const object_constructor = runtime.global("Object") orelse return error.TypeError;
        const keys = try runtime.callValue(program, try runtime.get(object_constructor, "keys"), object_constructor, &.{init});
        const count: usize = @intFromFloat(try runtime.valueNumber(try runtime.get(keys, "length")));
        if (count > web_fetch.max_headers) return error.TypeError;
        for (0..count) |index| {
            var index_buffer: [24]u8 = undefined;
            const index_key = std.fmt.bufPrint(index_buffer[0..], "{d}", .{index}) catch return error.TypeError;
            const name_value = try runtime.get(keys, index_key);
            const name = try coercedText(runtime, name_value);
            try headers_value.append(name, try coercedText(runtime, try runtime.get(init, name)));
        }
        return headers_value;
    }

    fn makeHeadersIterator(self: *WebRuntime, headers_object: javascript.Value, operation: HostOp) Error!javascript.Value {
        const root_mark = self.runtime.hostRootMark();
        defer self.runtime.restoreHostRoots(root_mark);
        try self.runtime.hostRoot(headers_object);
        const tag: u16 = switch (operation) {
            .headers_keys => host_object_headers_keys,
            .headers_values => host_object_headers_values,
            .headers_entries => host_object_headers_entries,
            else => return error.TypeError,
        };
        const object = try self.runtime.createObject();
        try self.runtime.hostRoot(object);
        if (self.runtime.global("Iterator")) |constructor| try self.runtime.setPrototype(object, try self.runtime.get(constructor, "prototype"));
        try self.runtime.setHostPropertyHooks(object, tag, self, null, null);
        try self.runtime.setHostState(object, tag, headers_object, .{ .number = 0 });
        try self.bindWebMethod(object, "next", .headers_iterator_next, 0);
        const symbol = self.runtime.global("Symbol") orelse return error.TypeError;
        try self.runtime.setKey(object, try self.runtime.get(symbol, "toStringTag"), try self.runtime.makeString("Headers Iterator"));
        return object;
    }

    fn makeBodyStream(self: *WebRuntime, bytes: []const u8, signal: javascript.Value) Error!javascript.Value {
        const root_mark = self.runtime.hostRootMark();
        defer self.runtime.restoreHostRoots(root_mark);
        try self.runtime.hostRoot(signal);
        const stream = try self.runtime.createObject();
        try self.runtime.hostRoot(stream);
        if (self.runtime.global("ReadableStream")) |constructor| try self.runtime.setPrototype(stream, try self.runtime.get(constructor, "prototype"));
        try self.runtime.setHostPropertyHooks(stream, host_object_body_stream, self, null, null);
        const data = try self.runtime.createUint8Array(bytes);
        try self.runtime.hostRoot(data);
        const state = try self.runtime.createArray(&.{ .{ .number = 0 }, signal });
        try self.runtime.hostRoot(state);
        try self.runtime.setHostState(stream, host_object_body_stream, data, state);
        try self.bindWebMethod(stream, "getReader", .stream_get_reader, 0);
        try self.bindWebMethod(stream, "cancel", .stream_cancel, 1);
        try self.bindWebAccessor(stream, "locked", .stream_get_locked, null);
        return stream;
    }

    fn makeResponseObject(
        self: *WebRuntime,
        body_bytes: ?[]const u8,
        status: u16,
        status_text: []const u8,
        headers_object: javascript.Value,
        url: []const u8,
        redirected: bool,
        response_type: []const u8,
        body_signal: javascript.Value,
    ) Error!javascript.Value {
        const root_mark = self.runtime.hostRootMark();
        defer self.runtime.restoreHostRoots(root_mark);
        try self.runtime.hostRoot(headers_object);
        try self.runtime.hostRoot(body_signal);
        const object = try self.runtime.createObject();
        try self.runtime.hostRoot(object);
        if (self.runtime.global("Response")) |constructor| try self.runtime.setPrototype(object, try self.runtime.get(constructor, "prototype"));
        const record = try self.runtime.createObject();
        try self.runtime.hostRoot(record);
        try self.runtime.set(record, "status", .{ .number = @floatFromInt(status) });
        try self.runtime.set(record, "statusText", try self.runtime.makeString(status_text));
        try self.runtime.set(record, "headers", headers_object);
        try self.runtime.set(record, "url", try self.runtime.makeString(url));
        try self.runtime.set(record, "redirected", .{ .boolean = redirected });
        try self.runtime.set(record, "type", try self.runtime.makeString(response_type));
        const body = if (body_bytes) |bytes| try self.makeBodyStream(bytes, body_signal) else javascript.Value.null_value;
        try self.runtime.hostRoot(body);
        try self.runtime.setHostPropertyHooks(object, host_object_response, self, null, null);
        try self.runtime.setHostState(object, host_object_response, record, body);
        return object;
    }

    fn responseState(self: *WebRuntime, runtime: *javascript.Runtime, receiver: javascript.Value) Error![2]javascript.Value {
        _ = self;
        const state = try runtime.hostState(receiver, host_object_response);
        if (state[0] != .cell) return error.TypeError;
        return state;
    }

    fn bodyBytes(self: *WebRuntime, runtime: *javascript.Runtime, body: javascript.Value) Error![]const u8 {
        if (body == .null_value) return self.encoding_input[0..0];
        const state = try runtime.hostState(body, host_object_body_stream);
        return runtime.copyBufferSource(state[0], self.encoding_input[0..]);
    }

    fn bodyFlags(self: *WebRuntime, runtime: *javascript.Runtime, body: javascript.Value) Error!u64 {
        _ = self;
        if (body == .null_value) return 0;
        const state = try runtime.hostState(body, host_object_body_stream);
        const number = try runtime.valueNumber(try runtime.getKey(state[1], .{ .number = 0 }));
        if (number < 0) return error.TypeError;
        return @intFromFloat(number);
    }

    fn setBodyFlags(self: *WebRuntime, runtime: *javascript.Runtime, body: javascript.Value, flags: u64) Error!void {
        _ = self;
        if (body == .null_value) return;
        const state = try runtime.hostState(body, host_object_body_stream);
        try runtime.setKey(state[1], .{ .number = 0 }, .{ .number = @floatFromInt(flags) });
    }

    fn bodySignal(self: *WebRuntime, runtime: *javascript.Runtime, body: javascript.Value) Error!javascript.Value {
        _ = self;
        if (body == .null_value) return .undefined;
        const state = try runtime.hostState(body, host_object_body_stream);
        return runtime.getKey(state[1], .{ .number = 1 });
    }

    fn bodyAbortReason(self: *WebRuntime, runtime: *javascript.Runtime, body: javascript.Value) Error!?javascript.Value {
        const signal = try self.bodySignal(runtime, body);
        if (signal == .undefined) return null;
        const record = try self.abortSignalRecord(runtime, signal);
        return if (runtime.valueBoolean(try self.abortField(runtime, record, abort_aborted))) try self.abortField(runtime, record, abort_reason) else null;
    }

    fn makeResponse(self: *WebRuntime, request: *PendingRequest) Error!javascript.Value {
        if (request.manual_redirect) return self.makeResponseObject(null, 0, "", try self.makeHeaders(""), "", false, "opaqueredirect", request.signal);
        const response_origin = security.Origin.parse(request.response_url[0..request.response_url_len], self.generation) catch request.target_origin;
        const same_origin = self.security_context.document_origin.same(&response_origin);
        if (request.mode == .no_cors and !same_origin) return self.makeResponseObject(null, 0, "", try self.makeHeaders(""), "", false, "opaque", request.signal);
        const response_type = if (same_origin) "basic" else "cors";
        return self.makeResponseObject(request.bodyBytes(), request.status, statusText(request.status), try self.makeFilteredResponseHeaders(request, same_origin), request.response_url[0..request.response_url_len], request.redirected, response_type, request.signal);
    }

    fn makeFilteredResponseHeaders(self: *WebRuntime, request: *const PendingRequest, same_origin: bool) Error!javascript.Value {
        var headers_value = try web_fetch.Headers.init("");
        var lines = std.mem.splitSequence(u8, request.response_headers[0..request.response_headers_len], "\r\n");
        while (lines.next()) |line| {
            if (line.len == 0) continue;
            const colon = std.mem.indexOfScalar(u8, line, ':') orelse return error.InvalidSerialized;
            const name = std.mem.trim(u8, line[0..colon], " \t");
            const value = std.mem.trim(u8, line[colon + 1 ..], " \t");
            if (std.ascii.eqlIgnoreCase(name, "set-cookie") or std.ascii.eqlIgnoreCase(name, "set-cookie2")) continue;
            if (!same_origin and !corsResponseHeaderVisible(request, name)) continue;
            try headers_value.append(name, value);
        }
        if (request.response_content_type_len > 0 and !(try headers_value.has("content-type"))) try headers_value.append("content-type", request.response_content_type[0..request.response_content_type_len]);
        var serialized: [web_fetch.max_serialized_bytes]u8 = undefined;
        return self.makeHeaders(try headers_value.serialize(serialized[0..]));
    }

    fn makeAbortSignal(self: *WebRuntime, aborted: bool, reason: javascript.Value) Error!javascript.Value {
        const root_mark = self.runtime.hostRootMark();
        defer self.runtime.restoreHostRoots(root_mark);
        try self.runtime.hostRoot(reason);
        const signal = try self.runtime.createObject();
        try self.runtime.hostRoot(signal);
        if (self.runtime.global("AbortSignal")) |constructor| try self.runtime.setPrototype(signal, try self.runtime.get(constructor, "prototype"));
        const record = try self.runtime.createArray(&.{ .{ .boolean = aborted }, reason, .null_value, .{ .number = 0 } });
        try self.runtime.hostRoot(record);
        try self.runtime.setHostPropertyHooks(signal, host_object_abort_signal, self, null, null);
        try self.runtime.setHostState(signal, host_object_abort_signal, record, .undefined);
        return signal;
    }

    fn abortSignalRecord(self: *WebRuntime, runtime: *javascript.Runtime, signal: javascript.Value) Error!javascript.Value {
        _ = self;
        return (try runtime.hostState(signal, host_object_abort_signal))[0];
    }

    fn abortField(self: *WebRuntime, runtime: *javascript.Runtime, record: javascript.Value, index: usize) Error!javascript.Value {
        _ = self;
        return runtime.getKey(record, .{ .number = @floatFromInt(index) });
    }

    fn setAbortField(self: *WebRuntime, runtime: *javascript.Runtime, record: javascript.Value, index: usize, value: javascript.Value) Error!void {
        _ = self;
        try runtime.setKey(record, .{ .number = @floatFromInt(index) }, value);
    }

    fn makeNamedError(self: *WebRuntime, runtime: *javascript.Runtime, name: []const u8, message: []const u8) Error!javascript.Value {
        const root_mark = runtime.hostRootMark();
        defer runtime.restoreHostRoots(root_mark);
        const program = runtime.activeProgram() orelse if (self.program_count > 0) self.programs[self.program_count - 1] orelse return error.TypeError else return error.TypeError;
        const constructor = runtime.global("Error") orelse return error.TypeError;
        const result = try runtime.callValue(program, constructor, .undefined, &.{try runtime.makeString(message)});
        try runtime.hostRoot(result);
        try runtime.set(result, "name", try runtime.makeString(name));
        return result;
    }

    fn makeTypeError(self: *WebRuntime, runtime: *javascript.Runtime, message: []const u8) Error!javascript.Value {
        const root_mark = runtime.hostRootMark();
        defer runtime.restoreHostRoots(root_mark);
        const program = runtime.activeProgram() orelse if (self.program_count > 0) self.programs[self.program_count - 1] orelse return error.TypeError else return error.TypeError;
        const constructor = runtime.global("TypeError") orelse return error.TypeError;
        const message_value = try runtime.makeString(message);
        try runtime.hostRoot(message_value);
        return runtime.callValue(program, constructor, .undefined, &.{message_value});
    }

    fn abortSignal(self: *WebRuntime, runtime: *javascript.Runtime, signal: javascript.Value, reason: javascript.Value) Error!void {
        const root_mark = runtime.hostRootMark();
        defer runtime.restoreHostRoots(root_mark);
        try runtime.hostRoot(signal);
        try runtime.hostRoot(reason);
        const record = try self.abortSignalRecord(runtime, signal);
        if (runtime.valueBoolean(try self.abortField(runtime, record, abort_aborted))) return;
        try self.setAbortField(runtime, record, abort_aborted, .{ .boolean = true });
        try self.setAbortField(runtime, record, abort_reason, reason);
        for (&self.requests) |*request| {
            if (!runtime.sameValue(request.signal, signal) or (request.state != .queued and request.state != .in_flight)) continue;
            request.state = .aborted;
            if (request.promise != .undefined) try runtime.rejectPromise(request.promise, reason);
        }
        const program = runtime.activeProgram() orelse if (self.program_count > 0) self.programs[self.program_count - 1] orelse return error.TypeError else return error.TypeError;
        const event = try runtime.createObject();
        try runtime.hostRoot(event);
        try runtime.set(event, "type", try runtime.makeString("abort"));
        try runtime.set(event, "target", signal);
        const onabort = try self.abortField(runtime, record, abort_onabort);
        if (onabort != .null_value and onabort != .undefined) _ = try runtime.callValue(program, onabort, signal, &.{event});
        const count: usize = @intFromFloat(try runtime.valueNumber(try self.abortField(runtime, record, abort_listener_count)));
        var index: usize = 0;
        while (index < count) : (index += 1) {
            const callback = try self.abortField(runtime, record, abort_listener_base + index);
            if (callback == .undefined) continue;
            if (runtime.valueCallable(callback)) {
                _ = try runtime.callValue(program, callback, signal, &.{event});
            } else {
                const handle = runtime.get(callback, "handleEvent") catch continue;
                if (runtime.valueCallable(handle)) _ = try runtime.callValue(program, handle, callback, &.{event});
            }
            if (runtime.valueBoolean(try self.abortField(runtime, record, abort_listener_once_base + index))) try self.setAbortField(runtime, record, abort_listener_base + index, .undefined);
        }
        for (&self.abort_followers) |*follower| {
            if (follower.occupied and follower.generation == self.generation and runtime.sameValue(follower.target, signal)) follower.occupied = false;
        }
        for (&self.abort_followers) |*follower| {
            if (!follower.occupied or follower.generation != self.generation or !runtime.sameValue(follower.source, signal)) continue;
            follower.occupied = false;
            try self.abortSignal(runtime, follower.target, reason);
        }
    }

    fn makeRequestObject(
        self: *WebRuntime,
        body_bytes: ?[]const u8,
        method: []const u8,
        url: []const u8,
        headers_object: javascript.Value,
        mode: []const u8,
        credentials: []const u8,
        cache: []const u8,
        redirect: []const u8,
        referrer: []const u8,
        referrer_policy: []const u8,
        integrity: []const u8,
        keepalive: bool,
        signal: javascript.Value,
    ) Error!javascript.Value {
        const root_mark = self.runtime.hostRootMark();
        defer self.runtime.restoreHostRoots(root_mark);
        try self.runtime.hostRoot(headers_object);
        try self.runtime.hostRoot(signal);
        const object = try self.runtime.createObject();
        try self.runtime.hostRoot(object);
        if (self.runtime.global("Request")) |constructor| try self.runtime.setPrototype(object, try self.runtime.get(constructor, "prototype"));
        const record = try self.runtime.createArray(&.{
            try self.runtime.makeString(method),
            try self.runtime.makeString(url),
            headers_object,
            try self.runtime.makeString(""),
            try self.runtime.makeString(referrer),
            try self.runtime.makeString(referrer_policy),
            try self.runtime.makeString(mode),
            try self.runtime.makeString(credentials),
            try self.runtime.makeString(cache),
            try self.runtime.makeString(redirect),
            try self.runtime.makeString(integrity),
            .{ .boolean = keepalive },
            signal,
            try self.runtime.makeString("half"),
        });
        try self.runtime.hostRoot(record);
        const body = if (body_bytes) |bytes| try self.makeBodyStream(bytes, .undefined) else javascript.Value.null_value;
        try self.runtime.hostRoot(body);
        try self.runtime.setHostPropertyHooks(object, host_object_request, self, null, null);
        try self.runtime.setHostState(object, host_object_request, record, body);
        return object;
    }

    fn requestState(self: *WebRuntime, runtime: *javascript.Runtime, receiver: javascript.Value) Error![2]javascript.Value {
        _ = self;
        const state = try runtime.hostState(receiver, host_object_request);
        if (state[0] != .cell) return error.TypeError;
        return state;
    }

    fn requestField(self: *WebRuntime, runtime: *javascript.Runtime, record: javascript.Value, field: RequestField) Error!javascript.Value {
        _ = self;
        return runtime.getKey(record, .{ .number = @floatFromInt(@intFromEnum(field)) });
    }

    fn bind(self: *WebRuntime, object: javascript.Value, name: []const u8, operation: HostOp) Error!void {
        try self.runtime.set(object, name, try self.host(operation));
    }

    fn bindWebMethod(self: *WebRuntime, object: javascript.Value, name: []const u8, operation: HostOp, length: usize) Error!void {
        try self.runtime.installHostMethod(object, name, try self.host(operation), length);
    }

    fn bindWebAccessor(self: *WebRuntime, object: javascript.Value, name: []const u8, getter: HostOp, setter: ?HostOp) Error!void {
        const getter_function = try self.host(getter);
        const setter_function = if (setter) |operation| try self.host(operation) else null;
        try self.runtime.installHostAccessor(object, name, getter_function, setter_function);
    }

    fn host(self: *WebRuntime, operation: HostOp) Error!javascript.Value {
        return switch (operation) {
            .xhr_constructor, .url_constructor, .url_search_params_constructor, .text_encoder_constructor, .text_decoder_constructor, .headers_constructor, .response_constructor, .request_constructor, .abort_controller_constructor, .count_queuing_strategy_constructor, .byte_length_queuing_strategy_constructor, .mutation_observer_constructor, .event_constructor, .performance_navigation_timing_constructor => self.runtime.createHostConstructor(@intFromEnum(operation), self, hostDispatch),
            else => self.runtime.createHostFunction(@intFromEnum(operation), self, hostDispatch),
        };
    }

    fn runtimeClockNow(context: ?*anyopaque) f64 {
        const self: *WebRuntime = @ptrCast(@alignCast(context orelse return 0));
        return self.clock_utc_origin_ms + (self.currentMonotonicMilliseconds() - self.clock_monotonic_origin_ms);
    }

    fn runtimeClockOffset(context: ?*anyopaque, _: f64) i32 {
        const self: *WebRuntime = @ptrCast(@alignCast(context orelse return 0));
        return self.clock_offset_minutes;
    }

    pub fn canvasView(self: *const WebRuntime, node: u16) ?web_canvas.SurfaceView {
        return self.canvases.view(node);
    }

    fn canvasAllocate(context: *anyopaque, length: usize, alignment: usize) ?[*]u8 {
        const self: *WebRuntime = @ptrCast(@alignCast(context));
        return self.program_allocator.allocate(self.program_allocator.context, length, alignment);
    }

    fn canvasFree(context: *anyopaque, memory: [*]u8, length: usize, alignment: usize) void {
        const self: *WebRuntime = @ptrCast(@alignCast(context));
        self.program_allocator.free(self.program_allocator.context, memory, length, alignment);
    }

    fn markRuntimeRoots(runtime: *javascript.Runtime, context: ?*anyopaque) void {
        const self: *WebRuntime = @ptrCast(@alignCast(context orelse return));
        for (&self.listeners) |*listener| if (listener.occupied) runtime.markExternal(listener.callback);
        for (&self.timers) |*timer| if (timer.occupied) runtime.markExternal(timer.callback);
        for (&self.abort_deadlines) |*deadline| if (deadline.occupied) runtime.markExternal(deadline.signal);
        for (&self.abort_followers) |*follower| if (follower.occupied) {
            runtime.markExternal(follower.source);
            runtime.markExternal(follower.target);
        };
        for (&self.requests) |*request| if (request.state != .free) {
            runtime.markExternal(request.promise);
            runtime.markExternal(request.xhr);
            runtime.markExternal(request.signal);
        };
        for (&self.xhrs) |*xhr| if (xhr.occupied) runtime.markExternal(xhr.object);
        for (&self.mutation_observers) |*observer| if (observer.occupied) {
            runtime.markExternal(observer.object);
            runtime.markExternal(observer.callback);
            runtime.markExternal(observer.delivery);
            for (observer.records[0..observer.record_count]) |record| runtime.markExternal(record);
        };
        for (self.history_states[0..self.history_count]) |state| runtime.markExternal(state);
        for (self.navigation_entry_objects[0..self.history_count]) |entry| runtime.markExternal(entry);
        runtime.markExternal(self.performance_navigation_entry);
        if (self.document) |document| {
            for (self.node_objects[0..document.node_count]) |node_object| runtime.markExternal(node_object);
            for (self.frame_document_objects[0..document.node_count]) |frame_document| runtime.markExternal(frame_document);
            for (self.frame_window_objects[0..document.node_count]) |frame_window| runtime.markExternal(frame_window);
        }
        for (self.frame_node_objects) |entry| runtime.markExternal(entry.object);
        for (self.canvas_contexts) |context_value| runtime.markExternal(context_value);
    }

    fn queueRequest(
        self: *WebRuntime,
        url: navigation.Url,
        kind: RequestKind,
        promise: javascript.Value,
        xhr: javascript.Value,
        options: RequestQueueOptions,
    ) Error!u32 {
        const resource_kind = securityKind(kind);
        const decision = self.security_context.authorize(self.generation, url.bytes(), resource_kind, options.mode);
        if (!decision.allowed) {
            self.last_block_reason = decision.reason;
            return error.SecurityBlocked;
        }
        for (&self.requests) |*request| {
            if (request.state != .free and request.state != .complete and request.state != .failed and request.state != .aborted) continue;
            const id = self.next_request_id;
            self.next_request_id +%= 1;
            if (options.headers.len > request.request_headers.len or options.body.len > request.body.len) return error.ResponseTooLarge;
            request.* = .{
                .state = .queued,
                .id = id,
                .generation = self.generation,
                .kind = kind,
                .mode = options.mode,
                .credentials = options.credentials,
                .method = options.method,
                .redirect = options.redirect,
                .signal = options.signal,
                .url = url,
                .target_origin = decision.target,
                .promise = promise,
                .xhr = xhr,
                .resource_index = options.resource_index,
                .module_index = options.module_index,
            };
            if (options.headers.len > 0) @memcpy(request.request_headers[0..options.headers.len], options.headers);
            request.request_headers_len = options.headers.len;
            if (options.body.len > 0) @memcpy(request.body[0..options.body.len], options.body);
            request.body_len = options.body.len;
            return id;
        }
        return error.RequestLimit;
    }

    fn consumeFontResponse(
        self: *WebRuntime,
        request: *PendingRequest,
        resource_index: usize,
        body: []const u8,
    ) bool {
        if (resource_index >= self.resources.count or resource_index >= self.font_resources.len) return false;
        const entry = self.resources.entries[resource_index];
        const font_resource = &self.font_resources[resource_index];
        if (entry.kind != .font or font_resource.resource_id != entry.id or font_resource.source_origin != .network) return false;
        font_resource.consumer_complete = true;
        font_resource.response_byte_count = body.len;
        const complete = self.resource_handler.complete orelse return false;
        const target = if (request.response_url_len > 0)
            navigation.parse(request.response_url[0..request.response_url_len]) catch request.url
        else
            request.url;
        return complete(self.resource_handler.context, .{
            .generation = self.generation,
            .resource_id = entry.id,
            .node = entry.node,
            .kind = .font,
            .requested_url = request.url,
            .final_url = target,
            .url = target,
            .status = request.status,
            .redirected = request.redirected,
            .content_type = request.response_content_type[0..request.response_content_type_len],
            .content_security_policy = request.response_csp[0..request.response_csp_len],
            .body = body,
            .byte_count = body.len,
            .font_face_index = font_resource.face_index,
            .font_source_index = font_resource.source_index,
            .font_format = font_resource.format,
            .font_source_origin = .network,
            .request_origin = self.security_context.document_origin,
        });
    }

    fn consumeCachedFontResource(self: *WebRuntime, resource_index: usize) bool {
        if (resource_index >= self.resources.count or resource_index >= self.font_resources.len) return false;
        const entry = self.resources.entries[resource_index];
        const font_resource = self.font_resources[resource_index];
        if (entry.kind != .font or font_resource.resource_id != entry.id or
            font_resource.source_origin != .cache or font_resource.requested_url.len == 0 or
            font_resource.cached_final_url.len == 0)
        {
            return false;
        }
        const complete = self.resource_handler.complete orelse return false;
        return complete(self.resource_handler.context, .{
            .generation = self.generation,
            .resource_id = entry.id,
            .node = entry.node,
            .kind = .font,
            .requested_url = font_resource.requested_url,
            .final_url = font_resource.cached_final_url,
            .url = font_resource.cached_final_url,
            .status = 0,
            .redirected = !std.mem.eql(u8, font_resource.requested_url.bytes(), font_resource.cached_final_url.bytes()),
            .content_type = "",
            .content_security_policy = "",
            .body = "",
            .byte_count = 0,
            .font_face_index = font_resource.face_index,
            .font_source_index = font_resource.source_index,
            .font_format = font_resource.format,
            .font_source_origin = .cache,
            .request_origin = self.security_context.document_origin,
        });
    }

    fn finishXhr(self: *WebRuntime, request: *PendingRequest, success: bool) Error!void {
        if (request.kind != .xhr or request.xhr == .undefined) return;
        try self.runtime.set(request.xhr, "readyState", .{ .number = 4 });
        try self.runtime.set(request.xhr, "status", .{ .number = if (success) @floatFromInt(request.status) else 0 });
        try self.runtime.set(request.xhr, "responseText", if (success) try self.runtime.makeString(request.bodyBytes()) else try self.runtime.makeString(""));
        const xhr_index = try self.xhrIndex(request.xhr);
        _ = try self.dispatchEvent(.{ .xhr = xhr_index }, if (success) "load" else "error", self.timing.now_ms);
    }

    fn findRequest(self: *WebRuntime, id: u32) ?*PendingRequest {
        for (&self.requests) |*request| if (request.id == id and request.state != .free) return request;
        return null;
    }

    fn failScheduledResource(self: *WebRuntime, request: *PendingRequest, failure: ResourceFailure) void {
        if (request.resource_index == std.math.maxInt(u8)) return;
        _ = self.resources.failFetch(request.id, request.generation) catch {};
        self.reportResourceTransition(request.resource_index, .failed, failure, null);
        self.dispatchResourceTerminalEvent(request.resource_index, false);
        self.finishFontResource(request.resource_index, false);
        _ = self.runReadyResources() catch 0;
        self.queueDiscoveredResources() catch {};
    }

    fn failModuleRequest(self: *WebRuntime, request: *PendingRequest) void {
        if (request.module_index == std.math.maxInt(u8) or request.module_index >= self.module_count) return;
        self.modules[request.module_index].state = .failed;
        self.failModuleGraph();
    }

    fn enqueueAction(self: *WebRuntime, kind: ActionKind, url: ?navigation.Url, node: u16) Error!void {
        if (self.action_count >= self.actions.len) return error.ActionLimit;
        self.actions[self.action_count] = .{
            .kind = kind,
            .generation = self.generation,
            .node = node,
            .url = url orelse .{},
        };
        self.action_count += 1;
    }

    fn enqueueTraversal(self: *WebRuntime, delta: i32) Error!void {
        if (delta == 0) return self.enqueueAction(.reload, null, html.none);
        if (self.action_count >= self.actions.len) return error.ActionLimit;
        self.actions[self.action_count] = .{
            .kind = .traverse,
            .generation = self.generation,
            .delta = delta,
        };
        self.action_count += 1;
    }

    fn addListener(self: *WebRuntime, target: u32, name: []const u8, callback: javascript.Value, once: bool, capture: bool) Error!void {
        for (&self.listeners) |*listener| if (listener.occupied and listener.target == target and listener.capture == capture and equal(listener.event_name.bytes(), name) and self.runtime.sameValue(listener.callback, callback)) return;
        for (&self.listeners) |*listener| {
            if (listener.occupied) continue;
            listener.* = .{
                .occupied = true,
                .generation = self.generation,
                .target = target,
                .callback = callback,
                .once = once,
                .capture = capture,
            };
            try listener.event_name.set(name);
            return;
        }
        return error.ListenerLimit;
    }

    fn removeListener(self: *WebRuntime, target: u32, name: []const u8, callback: javascript.Value, capture: bool) void {
        for (&self.listeners) |*listener| {
            if (listener.occupied and listener.target == target and listener.capture == capture and equal(listener.event_name.bytes(), name) and self.runtime.sameValue(listener.callback, callback)) {
                listener.occupied = false;
            }
        }
    }

    fn listenerOption(runtime: *javascript.Runtime, options: javascript.Value, name: []const u8) Error!bool {
        if (options == .undefined or options == .null_value) return false;
        if (options == .boolean) return equal(name, "capture") and runtime.valueBoolean(options);
        return runtime.valueBoolean(try runtime.get(options, name));
    }

    fn invokeEventListeners(self: *WebRuntime, token: u32, current_target: javascript.Value, event: javascript.Value, event_name: []const u8, capture: bool, phase: u8) Error!void {
        try self.runtime.set(event, "currentTarget", current_target);
        try self.runtime.set(event, "eventPhase", .{ .number = @floatFromInt(phase) });
        for (&self.listeners) |*listener| {
            if (!listener.occupied or listener.generation != self.generation or listener.target != token or listener.capture != capture or !equal(listener.event_name.bytes(), event_name)) continue;
            if (self.runtime.valueBoolean(try self.runtime.get(event, "_event_immediate_stopped"))) break;
            const callback = listener.callback;
            if (listener.once) listener.occupied = false;
            const program = self.runtime.activeProgram() orelse if (self.program_count > 0) self.programs[self.program_count - 1] orelse return error.TypeError else self.platform_program orelse return error.TypeError;
            if (self.runtime.valueCallable(callback)) {
                _ = try self.runtime.callValue(program, callback, current_target, &.{event});
            } else if (callback == .cell) {
                const handle = try self.runtime.get(callback, "handleEvent");
                if (self.runtime.valueCallable(handle)) _ = try self.runtime.callValue(program, handle, callback, &.{event});
            }
        }
    }

    fn makeDomEvent(self: *WebRuntime, event_type: []const u8, bubbles: bool, cancelable: bool, composed: bool, serial: u32) Error!javascript.Value {
        const root_mark = self.runtime.hostRootMark();
        defer self.runtime.restoreHostRoots(root_mark);
        const event = try self.runtime.createObject();
        try self.runtime.hostRoot(event);
        if (self.runtime.global("Event")) |constructor| try self.runtime.setPrototype(event, try self.runtime.get(constructor, "prototype"));
        try self.runtime.setHostPropertyHooks(event, host_object_event, self, null, null);
        try self.runtime.set(event, "type", try self.runtime.makeString(event_type));
        try self.runtime.set(event, "bubbles", .{ .boolean = bubbles });
        try self.runtime.set(event, "cancelable", .{ .boolean = cancelable });
        try self.runtime.set(event, "composed", .{ .boolean = composed });
        try self.runtime.set(event, "defaultPrevented", .{ .boolean = false });
        try self.runtime.set(event, "target", .null_value);
        try self.runtime.set(event, "currentTarget", .null_value);
        try self.runtime.set(event, "eventPhase", .{ .number = 0 });
        try self.runtime.set(event, "timeStamp", .{ .number = self.timing.now_ms - self.timing.time_origin_ms });
        try self.runtime.set(event, "_event_serial", .{ .number = @floatFromInt(serial) });
        try self.runtime.set(event, "_dispatching", .{ .boolean = false });
        return event;
    }

    fn nativeListenerReceives(self: *WebRuntime, target: EventTarget, listener: *const Listener, bubbles: bool) bool {
        const target_token = eventTargetToken(target);
        if (listener.target == target_token) return true;
        if (!listener.capture and !bubbles) return false;
        return switch (target) {
            .window, .navigation, .xhr => false,
            .document => listener.target == eventTargetToken(.window),
            .node => |node| blk: {
                const document = self.document orelse break :blk false;
                if (node >= document.node_count or !document.isConnected(node)) break :blk false;
                if (listener.target == eventTargetToken(.document) or listener.target == eventTargetToken(.window)) break :blk true;
                if (listener.target >= 0x10000 and listener.target < 0x20000) break :blk document.contains(@intCast(listener.target - 0x10000), node);
                break :blk false;
            },
        };
    }

    fn dispatchDomEvent(self: *WebRuntime, target_token: u32, target_value: javascript.Value, event: javascript.Value) Error!bool {
        if ((self.runtime.hostTag(event) catch 0) != host_object_event) return error.TypeError;
        if (self.runtime.valueBoolean(try self.runtime.get(event, "_dispatching"))) return error.TypeError;
        const type_value = try self.runtime.get(event, "type");
        if (type_value != .string or self.runtime.valueString(type_value).len == 0) return error.TypeError;
        const event_name = self.runtime.valueString(type_value);
        try self.runtime.set(event, "_dispatching", .{ .boolean = true });
        defer {
            self.runtime.set(event, "_dispatching", .{ .boolean = false }) catch {};
            self.runtime.set(event, "currentTarget", .null_value) catch {};
            self.runtime.set(event, "eventPhase", .{ .number = 0 }) catch {};
        }
        try self.runtime.set(event, "target", target_value);
        try self.runtime.set(event, "_event_stopped", .{ .boolean = false });
        try self.runtime.set(event, "_event_immediate_stopped", .{ .boolean = false });

        var tokens: [html.max_depth + 3]u32 = undefined;
        var values: [html.max_depth + 3]javascript.Value = undefined;
        var path_count: usize = 1;
        tokens[0] = target_token;
        values[0] = target_value;
        if (target_token >= 0x10000 and target_token < 0x20000) {
            const document = self.document orelse return error.NotInitialized;
            var node: u16 = @intCast(target_token - 0x10000);
            var reached_document = false;
            while (node < document.node_count and document.nodes[node].parent != html.none) {
                node = document.nodes[node].parent;
                if (path_count >= tokens.len) return error.InvalidNode;
                tokens[path_count] = if (node == 0) eventTargetToken(.document) else eventTargetToken(.{ .node = node });
                values[path_count] = try self.makeNode(node);
                path_count += 1;
                if (node == 0) {
                    reached_document = true;
                    break;
                }
            }
            if (reached_document) {
                tokens[path_count] = eventTargetToken(.window);
                values[path_count] = self.runtime.global("window") orelse .undefined;
                path_count += 1;
            }
        } else if (target_token == eventTargetToken(.document)) {
            tokens[path_count] = eventTargetToken(.window);
            values[path_count] = self.runtime.global("window") orelse .undefined;
            path_count += 1;
        }

        var ancestor = path_count;
        while (ancestor > 1) {
            ancestor -= 1;
            try self.invokeEventListeners(tokens[ancestor], values[ancestor], event, event_name, true, 1);
            if (self.runtime.valueBoolean(try self.runtime.get(event, "_event_stopped"))) break;
        }
        if (!self.runtime.valueBoolean(try self.runtime.get(event, "_event_stopped"))) {
            try self.invokeEventListeners(tokens[0], values[0], event, event_name, true, 2);
            if (!self.runtime.valueBoolean(try self.runtime.get(event, "_event_immediate_stopped"))) try self.invokeEventListeners(tokens[0], values[0], event, event_name, false, 2);
        }
        if (self.runtime.valueBoolean(try self.runtime.get(event, "bubbles")) and !self.runtime.valueBoolean(try self.runtime.get(event, "_event_stopped"))) {
            var index: usize = 1;
            while (index < path_count) : (index += 1) {
                try self.invokeEventListeners(tokens[index], values[index], event, event_name, false, 3);
                if (self.runtime.valueBoolean(try self.runtime.get(event, "_event_stopped"))) break;
            }
        }
        return !self.runtime.valueBoolean(try self.runtime.get(event, "defaultPrevented"));
    }

    fn createTimer(self: *WebRuntime, callback: javascript.Value, delay: f64, interval: bool) Error!u32 {
        for (&self.timers) |*timer| {
            if (timer.occupied) continue;
            const id = self.next_timer_id;
            self.next_timer_id +%= 1;
            const bounded_delay = @max(0, @min(delay, 86_400_000));
            timer.* = .{
                .occupied = true,
                .generation = self.generation,
                .id = id,
                .due_ms = self.timing.now_ms + bounded_delay,
                .interval_ms = if (interval) @max(1, bounded_delay) else 0,
                .callback = callback,
            };
            return id;
        }
        return error.TimerLimit;
    }

    fn clearTimer(self: *WebRuntime, id: u32) void {
        for (&self.timers) |*timer| if (timer.occupied and timer.id == id) {
            timer.occupied = false;
        };
    }

    fn storageArea(self: *WebRuntime, receiver: javascript.Value) Error!*security.StorageArea {
        const session = self.runtime.valueBoolean(try self.runtime.get(receiver, "_session"));
        const browser_storage = self.storage orelse return error.NotInitialized;
        return if (session)
            browser_storage.session.area(&self.security_context.document_origin)
        else
            browser_storage.local.area(&self.security_context.document_origin);
    }

    fn receiverNode(self: *WebRuntime, receiver: javascript.Value) Error!u16 {
        const number = try self.runtime.valueNumber(try self.runtime.get(receiver, "_node"));
        if (number < 0 or number > std.math.maxInt(u16)) return error.InvalidNode;
        return @intFromFloat(number);
    }

    fn xhrIndex(self: *WebRuntime, receiver: javascript.Value) Error!u16 {
        const number = try self.runtime.valueNumber(try self.runtime.get(receiver, "_xhr"));
        if (number < 0 or number >= max_xhr) return error.TypeError;
        return @intFromFloat(number);
    }

    fn receiverEventTarget(self: *WebRuntime, receiver: javascript.Value) Error!u32 {
        const number = try self.runtime.valueNumber(try self.runtime.get(receiver, "_event_target"));
        if (number < 0 or number > std.math.maxInt(u32)) return error.TypeError;
        return @intFromFloat(number);
    }

    fn eventTargetValue(self: *WebRuntime, target: EventTarget) Error!javascript.Value {
        return switch (target) {
            .window => self.runtime.global("window") orelse .undefined,
            .document => self.runtime.global("document") orelse .undefined,
            .navigation => self.runtime.global("navigation") orelse .undefined,
            .node => |node| self.makeNode(node),
            .xhr => |index| if (index < self.xhrs.len and self.xhrs[index].occupied) self.xhrs[index].object else .undefined,
        };
    }

    fn argumentString(self: *WebRuntime, arguments: []const javascript.Value, index: usize) []const u8 {
        if (index >= arguments.len) return "";
        const value = arguments[index];
        if (value == .string) return self.runtime.valueString(value);
        return "";
    }

    fn resolveArgumentUrl(self: *WebRuntime, arguments: []const javascript.Value, index: usize) Error!navigation.Url {
        const value = self.argumentString(arguments, index);
        return if (navigation.isDocumentRelativeReference(value))
            navigation.resolve(&self.document_url, value)
        else
            navigation.parse(value);
    }

    fn resolveValueUrl(self: *WebRuntime, runtime: *javascript.Runtime, value: javascript.Value) Error!navigation.Url {
        const text = try coercedText(runtime, value);
        return if (navigation.isDocumentRelativeReference(text))
            navigation.resolve(&self.document_url, text)
        else
            navigation.parse(text);
    }

    fn originString(self: *WebRuntime) Error!javascript.Value {
        var buffer: [security.max_origin_host_bytes + 24]u8 = undefined;
        return self.runtime.makeString(self.security_context.document_origin.serialize(buffer[0..]) orelse "null");
    }

    fn wallTime(self: *const WebRuntime, monotonic_ms: f64) f64 {
        return self.clock_utc_origin_ms + (monotonic_ms - self.clock_monotonic_origin_ms);
    }

    fn currentMonotonicMilliseconds(self: *const WebRuntime) f64 {
        const callback = self.monotonic_clock.now_milliseconds orelse return self.timing.now_ms;
        return callback(self.monotonic_clock.context);
    }

    fn path(self: *const WebRuntime) []const u8 {
        return urlPath(self.document_url.bytes());
    }

    fn refreshTimingBindings(self: *WebRuntime) void {
        if (!self.javascriptRealmActive()) return;
        const performance = self.runtime.global("performance") orelse return;
        const timing = self.runtime.get(performance, "timing") catch return;
        const known = struct {
            fn wall(runtime: *const WebRuntime, value: f64) f64 {
                return if (value == 0) 0 else runtime.wallTime(value);
            }
        }.wall;
        self.runtime.set(performance, "timeOrigin", .{ .number = self.wallTime(self.timing.time_origin_ms) }) catch {};
        self.runtime.set(timing, "navigationStart", .{ .number = known(self, self.timing.navigation_start_ms) }) catch {};
        self.runtime.set(timing, "unloadEventStart", .{ .number = 0 }) catch {};
        self.runtime.set(timing, "unloadEventEnd", .{ .number = 0 }) catch {};
        self.runtime.set(timing, "redirectStart", .{ .number = 0 }) catch {};
        self.runtime.set(timing, "redirectEnd", .{ .number = 0 }) catch {};
        self.runtime.set(timing, "fetchStart", .{ .number = known(self, self.timing.fetch_start_ms) }) catch {};
        self.runtime.set(timing, "domainLookupStart", .{ .number = known(self, self.timing.fetch_start_ms) }) catch {};
        self.runtime.set(timing, "domainLookupEnd", .{ .number = known(self, self.timing.fetch_start_ms) }) catch {};
        self.runtime.set(timing, "connectStart", .{ .number = known(self, self.timing.fetch_start_ms) }) catch {};
        self.runtime.set(timing, "secureConnectionStart", .{ .number = if (self.document_url.scheme == .https) known(self, self.timing.fetch_start_ms) else 0 }) catch {};
        self.runtime.set(timing, "connectEnd", .{ .number = known(self, self.timing.request_start_ms) }) catch {};
        self.runtime.set(timing, "requestStart", .{ .number = known(self, self.timing.request_start_ms) }) catch {};
        self.runtime.set(timing, "responseStart", .{ .number = known(self, self.timing.response_start_ms) }) catch {};
        self.runtime.set(timing, "responseEnd", .{ .number = known(self, self.timing.response_end_ms) }) catch {};
        self.runtime.set(timing, "domLoading", .{ .number = known(self, self.timing.response_end_ms) }) catch {};
        self.runtime.set(timing, "domInteractive", .{ .number = known(self, self.timing.dom_interactive_ms) }) catch {};
        self.runtime.set(timing, "domContentLoadedEventStart", .{ .number = known(self, self.timing.dom_content_loaded_start_ms) }) catch {};
        self.runtime.set(timing, "domContentLoadedEventEnd", .{ .number = known(self, self.timing.dom_content_loaded_end_ms) }) catch {};
        self.runtime.set(timing, "domComplete", .{ .number = known(self, self.timing.dom_complete_ms) }) catch {};
        self.runtime.set(timing, "loadEventStart", .{ .number = known(self, self.timing.load_event_start_ms) }) catch {};
        self.runtime.set(timing, "loadEventEnd", .{ .number = known(self, self.timing.load_event_end_ms) }) catch {};
    }
};

fn hostPropertyGet(
    runtime: *javascript.Runtime,
    raw_context: ?*anyopaque,
    tag: u16,
    object: javascript.Value,
    name: []const u8,
) javascript.Error!?javascript.Value {
    const self: *WebRuntime = @ptrCast(@alignCast(raw_context orelse return error.TypeError));
    return propertyGet(self, runtime, tag, object, name) catch return error.TypeError;
}

fn hostPropertySet(
    runtime: *javascript.Runtime,
    raw_context: ?*anyopaque,
    tag: u16,
    object: javascript.Value,
    name: []const u8,
    value: javascript.Value,
) javascript.Error!bool {
    const self: *WebRuntime = @ptrCast(@alignCast(raw_context orelse return error.TypeError));
    return propertySet(self, runtime, tag, object, name, value) catch return error.TypeError;
}

fn propertyGet(self: *WebRuntime, runtime: *javascript.Runtime, tag: u16, object: javascript.Value, name: []const u8) Error!?javascript.Value {
    if (tag == host_object_url) {
        if (name.len > 0 and name[0] == '_') return null;
        const state = try runtime.hostState(object, host_object_url);
        const href_value = state[0];
        if (href_value != .string) return error.TypeError;
        const href = runtime.valueString(href_value);
        const parsed = try web_url.parts(href);
        if (equal(name, "href")) return href_value;
        if (equal(name, "protocol")) return try runtime.makeString(parsed.protocol);
        if (equal(name, "username")) return try runtime.makeString(parsed.username);
        if (equal(name, "password")) return try runtime.makeString(parsed.password);
        if (equal(name, "host")) return try runtime.makeString(parsed.host);
        if (equal(name, "hostname")) return try runtime.makeString(parsed.hostname);
        if (equal(name, "port")) return try runtime.makeString(parsed.port);
        if (equal(name, "pathname")) return try runtime.makeString(parsed.pathname);
        if (equal(name, "search")) return try runtime.makeString(parsed.search);
        if (equal(name, "hash")) return try runtime.makeString(parsed.hash);
        if (equal(name, "searchParams")) return state[1];
        if (equal(name, "origin")) {
            const origin = security.Origin.parse(href, self.generation) catch return try runtime.makeString("null");
            var buffer: [security.max_origin_host_bytes + 24]u8 = undefined;
            return try runtime.makeString(origin.serialize(buffer[0..]) orelse "null");
        }
        return null;
    }
    if (tag == host_object_url_search_params) {
        if (name.len > 0 and name[0] == '_') return null;
        if (equal(name, "size")) {
            const params = try self.urlSearchParams(runtime, object);
            return .{ .number = @floatFromInt(params.count) };
        }
        return null;
    }
    if (tag == host_object_document) {
        if (equal(name, "cookie")) {
            const browser_storage = self.storage orelse return error.NotInitialized;
            var out: [1024]u8 = undefined;
            return try runtime.makeString(browser_storage.cookies.writeDocumentCookie(&self.security_context.document_origin, self.path(), out[0..]));
        }
        if (equal(name, "URL")) return try runtime.makeString(self.document_url.bytes());
        if (equal(name, "origin")) return try self.originString();
        if (equal(name, "readyState")) return try runtime.makeString(@tagName(self.document_ready_state));
        if (equal(name, "nodeType")) return .{ .number = 9 };
        if (equal(name, "nodeName")) return try runtime.makeString("#document");
        if (equal(name, "nodeValue") or equal(name, "parentNode") or equal(name, "parentElement") or equal(name, "ownerDocument")) return .null_value;
        if (equal(name, "isConnected")) return .{ .boolean = true };
        if (equal(name, "childNodes")) return try self.makeChildNodeList(0, false);
        if (equal(name, "children")) return try self.makeChildNodeList(0, true);
        if (equal(name, "documentElement")) {
            const document = self.document orelse return error.NotInitialized;
            return if (document.findFirstElement("html")) |node| try self.makeNode(node) else .null_value;
        }
        if (equal(name, "head")) {
            const document = self.document orelse return error.NotInitialized;
            return if (document.findFirstElement("head")) |node| try self.makeNode(node) else .null_value;
        }
        if (equal(name, "body")) {
            const document = self.document orelse return error.NotInitialized;
            return if (document.findFirstElement("body")) |node| try self.makeNode(node) else .null_value;
        }
        return null;
    }
    if (tag == host_object_location) {
        const parts = try web_url.parts(self.document_url.bytes());
        if (equal(name, "href")) return try runtime.makeString(self.document_url.bytes());
        if (equal(name, "origin")) return try self.originString();
        if (equal(name, "protocol")) return try runtime.makeString(parts.protocol);
        if (equal(name, "username")) return try runtime.makeString(parts.username);
        if (equal(name, "password")) return try runtime.makeString(parts.password);
        if (equal(name, "host")) return try runtime.makeString(parts.host);
        if (equal(name, "hostname")) return try runtime.makeString(parts.hostname);
        if (equal(name, "port")) return try runtime.makeString(parts.port);
        if (equal(name, "pathname")) return try runtime.makeString(parts.pathname);
        if (equal(name, "search")) return try runtime.makeString(parts.search);
        if (equal(name, "hash")) return try runtime.makeString(parts.hash);
        return null;
    }
    if (tag == host_object_history) {
        if (equal(name, "length")) return .{ .number = @floatFromInt(self.history_count) };
        if (equal(name, "state")) return self.history_states[self.history_index];
        if (equal(name, "scrollRestoration")) return try runtime.makeString(if (self.history_scroll_manual) "manual" else "auto");
        return null;
    }
    if (tag == host_object_navigation) {
        if (equal(name, "currentEntry")) return try self.makeNavigationEntry(self.history_index);
        if (equal(name, "canGoBack")) return .{ .boolean = self.history_index > 0 };
        if (equal(name, "canGoForward")) return .{ .boolean = self.history_index + 1 < self.history_count };
        if (equal(name, "transition") or equal(name, "activation")) return .null_value;
        return null;
    }
    if (tag == host_object_local_storage or tag == host_object_session_storage) {
        const browser_storage = self.storage orelse return error.NotInitialized;
        const area = if (tag == host_object_session_storage)
            try browser_storage.session.area(&self.security_context.document_origin)
        else
            try browser_storage.local.area(&self.security_context.document_origin);
        if (equal(name, "length")) return .{ .number = @floatFromInt(area.count()) };
        if (name.len > 0 and name[0] != '_') {
            if (area.get(name)) |value| return try runtime.makeString(value);
        }
        return null;
    }
    if (tag == host_object_frame_document) {
        const state = try runtime.hostState(object, host_object_frame_document);
        const iframe_number = try runtime.valueNumber(state[0]);
        if (iframe_number < 0 or iframe_number >= html.max_nodes) return error.InvalidNode;
        const iframe: u16 = @intFromFloat(iframe_number);
        const info = self.frameInfo(iframe) orelse return error.StaleGeneration;
        if (!info.same_origin) return error.SecurityBlocked;
        const document = info.document orelse return error.StaleGeneration;
        if (equal(name, "URL")) return try runtime.makeString(info.url.bytes());
        if (equal(name, "readyState")) return try runtime.makeString(if (info.complete) "complete" else "loading");
        if (equal(name, "nodeType")) return .{ .number = 9 };
        if (equal(name, "nodeName")) return try runtime.makeString("#document");
        if (equal(name, "defaultView")) return @as(?javascript.Value, try self.makeFrameWindow(iframe, info));
        if (equal(name, "documentElement")) return @as(?javascript.Value, if (document.findFirstElement("html")) |node| try self.makeFrameNode(iframe, node) else .null_value);
        if (equal(name, "head")) return @as(?javascript.Value, if (document.findFirstElement("head")) |node| try self.makeFrameNode(iframe, node) else .null_value);
        if (equal(name, "body")) return @as(?javascript.Value, if (document.findFirstElement("body")) |node| try self.makeFrameNode(iframe, node) else .null_value);
        if (equal(name, "title")) {
            const title_node = document.findFirstElement("title") orelse return try runtime.makeString("");
            return try runtime.makeString(document.textContent(title_node, self.script_scratch[0..]) catch "");
        }
        return null;
    }
    if (tag == host_object_frame_node) {
        const frame = try self.frameNodes(runtime, object, host_object_frame_node);
        const item = frame.document.nodes[frame.child];
        if (equal(name, "nodeType")) return .{ .number = @floatFromInt(WebRuntime.domNodeType(frame.document, frame.child)) };
        if (equal(name, "nodeName")) return try runtime.makeString(WebRuntime.domNodeName(frame.document, frame.child));
        if (equal(name, "nodeValue")) return switch (item.kind) {
            .text, .comment => try runtime.makeString(frame.document.nodeValue(frame.child)),
            else => .null_value,
        };
        if (equal(name, "tagName")) {
            if (item.kind != .element) return .undefined;
            const source = frame.document.nodeName(frame.child);
            var upper: [128]u8 = undefined;
            if (source.len > upper.len) return error.StringLimit;
            for (source, 0..) |character, index| upper[index] = std.ascii.toUpper(character);
            return try runtime.makeString(upper[0..source.len]);
        }
        if (equal(name, "textContent")) return try runtime.makeString(frame.document.textContent(frame.child, self.script_scratch[0..]) catch "");
        if (equal(name, "id")) return try runtime.makeString(frame.document.attribute(frame.child, "id") orelse "");
        if (equal(name, "className")) return try runtime.makeString(frame.document.attribute(frame.child, "class") orelse "");
        if (equal(name, "ownerDocument")) return @as(?javascript.Value, try self.makeFrameDocument(frame.iframe, self.frameInfo(frame.iframe).?));
        if (equal(name, "parentNode")) return @as(?javascript.Value, if (item.parent != html.none) try self.makeFrameNode(frame.iframe, item.parent) else .null_value);
        if (equal(name, "firstChild")) return @as(?javascript.Value, if (item.first_child != html.none) try self.makeFrameNode(frame.iframe, item.first_child) else .null_value);
        if (equal(name, "lastChild")) return @as(?javascript.Value, if (item.last_child != html.none) try self.makeFrameNode(frame.iframe, item.last_child) else .null_value);
        if (equal(name, "nextSibling")) return @as(?javascript.Value, if (item.next_sibling != html.none) try self.makeFrameNode(frame.iframe, item.next_sibling) else .null_value);
        return null;
    }
    if (tag == host_object_frame_window) {
        const state = try runtime.hostState(object, host_object_frame_window);
        const same_origin = runtime.valueBoolean(state[0]);
        if (equal(name, "document")) {
            if (!same_origin) return error.SecurityBlocked;
            return state[1];
        }
        if (equal(name, "location")) {
            if (!same_origin) return error.SecurityBlocked;
            if (state[1] == .null_value) return .null_value;
            return @as(?javascript.Value, try runtime.get(state[1], "URL"));
        }
        return null;
    }
    if (tag >= host_object_canvas_context_base and tag < host_object_canvas_context_base + web_canvas.max_surfaces) {
        const index: usize = tag - host_object_canvas_context_base;
        const surface = &self.canvases.surfaces[index];
        if (surface.node == html.none) return error.TypeError;
        if (equal(name, "fillStyle")) return try runtime.makeString(canvasColorString(surface.fill_style));
        if (equal(name, "strokeStyle")) return try runtime.makeString(canvasColorString(surface.stroke_style));
        if (equal(name, "lineWidth")) return .{ .number = surface.line_width };
        return null;
    }
    if (tag >= host_object_node_base) {
        const node: u16 = tag - host_object_node_base;
        const document = self.document orelse return error.NotInitialized;
        if (node >= document.node_count) return error.InvalidNode;
        const item = document.nodes[node];
        if (item.kind == .element and std.ascii.eqlIgnoreCase(document.nodeName(node), "iframe")) {
            if (equal(name, "contentDocument")) {
                const info = self.frameInfo(node) orelse return .null_value;
                const frame_document = try self.makeFrameDocument(node, info);
                if (frame_document != .null_value) try runtime.set(frame_document, "readyState", try runtime.makeString(if (info.complete) "complete" else "loading"));
                return frame_document;
            }
            if (equal(name, "contentWindow")) {
                const info = self.frameInfo(node) orelse return .null_value;
                return @as(?javascript.Value, try self.makeFrameWindow(node, info));
            }
        }
        if (equal(name, "nodeType")) return .{ .number = @floatFromInt(WebRuntime.domNodeType(document, node)) };
        if (equal(name, "nodeName")) return try runtime.makeString(WebRuntime.domNodeName(document, node));
        if (equal(name, "nodeValue")) return switch (item.kind) {
            .text, .comment => try runtime.makeString(document.nodeValue(node)),
            else => .null_value,
        };
        if (equal(name, "textContent")) {
            var out: [4096]u8 = undefined;
            return try runtime.makeString(try document.textContent(node, out[0..]));
        }
        if (equal(name, "tagName")) {
            if (item.kind != .element) return .undefined;
            const source = document.nodeName(node);
            var upper: [128]u8 = undefined;
            if (source.len > upper.len) return error.StringLimit;
            for (source, 0..) |character, index| upper[index] = std.ascii.toUpper(character);
            return try runtime.makeString(upper[0..source.len]);
        }
        if (equal(name, "ownerDocument")) return runtime.global("document") orelse .null_value;
        if (equal(name, "isConnected")) return .{ .boolean = document.isConnected(node) };
        if (equal(name, "parentNode")) return if (item.parent != html.none) try self.makeNode(item.parent) else .null_value;
        if (equal(name, "parentElement")) return if (item.parent != html.none and document.nodes[item.parent].kind == .element) try self.makeNode(item.parent) else .null_value;
        if (equal(name, "firstChild")) return if (item.first_child != html.none) try self.makeNode(item.first_child) else .null_value;
        if (equal(name, "lastChild")) return if (item.last_child != html.none) try self.makeNode(item.last_child) else .null_value;
        if (equal(name, "previousSibling")) return if (document.previousSibling(node)) |sibling| try self.makeNode(sibling) else .null_value;
        if (equal(name, "nextSibling")) return if (item.next_sibling != html.none) try self.makeNode(item.next_sibling) else .null_value;
        if (equal(name, "previousElementSibling")) return if (WebRuntime.adjacentElement(document, node, true)) |sibling| try self.makeNode(sibling) else .null_value;
        if (equal(name, "nextElementSibling")) return if (WebRuntime.adjacentElement(document, node, false)) |sibling| try self.makeNode(sibling) else .null_value;
        if (equal(name, "firstElementChild")) return if (WebRuntime.edgeElementChild(document, node, false)) |child| try self.makeNode(child) else .null_value;
        if (equal(name, "lastElementChild")) return if (WebRuntime.edgeElementChild(document, node, true)) |child| try self.makeNode(child) else .null_value;
        if (equal(name, "childNodes")) return try self.makeChildNodeList(node, false);
        if (equal(name, "children")) return try self.makeChildNodeList(node, true);
        if (equal(name, "childElementCount")) {
            var count: usize = 0;
            var child = item.first_child;
            while (child != html.none and child < document.node_count) : (child = document.nodes[child].next_sibling) if (document.nodes[child].kind == .element) {
                count += 1;
            };
            return .{ .number = @floatFromInt(count) };
        }
        if (equal(name, "id")) return try runtime.makeString(document.attribute(node, "id") orelse "");
        if (equal(name, "className")) return try runtime.makeString(document.attribute(node, "class") orelse "");
        if (item.kind == .element and std.ascii.eqlIgnoreCase(document.nodeName(node), "img")) {
            if (equal(name, "src") or equal(name, "srcset") or equal(name, "sizes")) return try runtime.makeString(document.attribute(node, name) orelse "");
            if (equal(name, "currentSrc")) {
                if (self.imageResourceIndex(node, .content)) |index| {
                    const tracked = self.image_resources[index];
                    if (tracked.requested_url.len > 0) return try runtime.makeString(tracked.requested_url.bytes());
                    return try runtime.makeString(tracked.selection.bytes());
                }
                return try runtime.makeString("");
            }
        }
        if (item.kind == .element and std.ascii.eqlIgnoreCase(document.nodeName(node), "source") and
            (equal(name, "srcset") or equal(name, "sizes") or equal(name, "media") or equal(name, "type")))
            return try runtime.makeString(document.attribute(node, name) orelse "");
        if (item.kind == .element and std.ascii.eqlIgnoreCase(document.nodeName(node), "canvas")) {
            if (equal(name, "width")) return .{ .number = @floatFromInt(canvasDimension(document.attribute(node, "width"), 300)) };
            if (equal(name, "height")) return .{ .number = @floatFromInt(canvasDimension(document.attribute(node, "height"), 150)) };
        }
        if (equal(name, "value")) return try runtime.makeString(document.attribute(node, "value") orelse "");
        if (equal(name, "style")) return try self.makeStyleObject(node);
        return null;
    }
    return null;
}

fn propertySet(self: *WebRuntime, runtime: *javascript.Runtime, tag: u16, object: javascript.Value, name: []const u8, value: javascript.Value) Error!bool {
    if (tag == host_object_url) {
        if (equal(name, "origin") or equal(name, "searchParams")) return true;
        const href_property = equal(name, "href");
        const component: ?web_url.Component = if (equal(name, "protocol"))
            .protocol
        else if (equal(name, "username"))
            .username
        else if (equal(name, "password"))
            .password
        else if (equal(name, "host"))
            .host
        else if (equal(name, "hostname"))
            .hostname
        else if (equal(name, "port"))
            .port
        else if (equal(name, "pathname"))
            .pathname
        else if (equal(name, "search"))
            .search
        else if (equal(name, "hash"))
            .hash
        else
            null;
        if (!href_property and component == null) return false;
        const replacement = try coercedText(runtime, value);
        const state = try runtime.hostState(object, host_object_url);
        const href_value = state[0];
        if (href_value != .string) return error.TypeError;
        const normalized = if (href_property)
            if (navigation.isDocumentRelativeReference(replacement))
                try navigation.resolve(&try navigation.parse(runtime.valueString(href_value)), replacement)
            else
                try navigation.parse(replacement)
        else blk: {
            var candidate: [navigation.url_capacity + 1]u8 = undefined;
            break :blk try navigation.parse(try web_url.replaceComponent(runtime.valueString(href_value), component.?, replacement, candidate[0..]));
        };
        try runtime.setHostState(object, host_object_url, try runtime.makeString(normalized.bytes()), state[1]);
        try self.syncUrlParamsFromHref(runtime, object, normalized.bytes());
        return true;
    }
    if (tag == host_object_url_search_params and equal(name, "size")) return true;
    if (tag == host_object_window and equal(name, "location")) {
        const target = try self.resolveValueUrl(runtime, value);
        try self.enqueueAction(.navigate, target, html.none);
        return true;
    }
    if (tag == host_object_document and equal(name, "cookie")) {
        const browser_storage = self.storage orelse return error.NotInitialized;
        try browser_storage.cookies.setFromDocument(&self.security_context.document_origin, self.path(), try valueText(runtime, value));
        return true;
    }
    if (tag == host_object_frame_node and (equal(name, "textContent") or equal(name, "id") or equal(name, "className"))) {
        const frame = try self.frameNodes(runtime, object, host_object_frame_node);
        const text = try coercedText(runtime, value);
        if (equal(name, "textContent")) {
            try frame.document.setTextContent(frame.child, text);
        } else {
            try frame.document.setAttribute(frame.child, if (equal(name, "id")) "id" else "class", text);
        }
        if (frame.child_runtime) |child_runtime| child_runtime.dom_dirty = true;
        return true;
    }
    if (tag == host_object_location) {
        if (equal(name, "origin")) return true;
        if (equal(name, "href")) {
            const target = try self.resolveValueUrl(runtime, value);
            try self.enqueueAction(.navigate, target, html.none);
            return true;
        }
        const component: ?web_url.Component = if (equal(name, "protocol"))
            .protocol
        else if (equal(name, "username"))
            .username
        else if (equal(name, "password"))
            .password
        else if (equal(name, "host"))
            .host
        else if (equal(name, "hostname"))
            .hostname
        else if (equal(name, "port"))
            .port
        else if (equal(name, "pathname"))
            .pathname
        else if (equal(name, "search"))
            .search
        else if (equal(name, "hash"))
            .hash
        else
            null;
        if (component) |part| {
            var candidate: [navigation.url_capacity + 1]u8 = undefined;
            const target = try navigation.parse(try web_url.replaceComponent(self.document_url.bytes(), part, try coercedText(runtime, value), candidate[0..]));
            try self.enqueueAction(.navigate, target, html.none);
            return true;
        }
        return false;
    }
    if (tag == host_object_history and equal(name, "scrollRestoration")) {
        const setting = try coercedText(runtime, value);
        if (equal(setting, "auto")) self.history_scroll_manual = false else if (equal(setting, "manual")) self.history_scroll_manual = true else return true;
        return true;
    }
    if (tag == host_object_local_storage or tag == host_object_session_storage) {
        if (name.len == 0 or name[0] == '_' or equal(name, "length")) return false;
        const browser_storage = self.storage orelse return error.NotInitialized;
        const area = if (tag == host_object_session_storage)
            try browser_storage.session.area(&self.security_context.document_origin)
        else
            try browser_storage.local.area(&self.security_context.document_origin);
        try area.set(name, try valueText(runtime, value));
        return true;
    }
    if (tag >= host_object_canvas_context_base and tag < host_object_canvas_context_base + web_canvas.max_surfaces) {
        const index: usize = tag - host_object_canvas_context_base;
        const surface = &self.canvases.surfaces[index];
        if (surface.node == html.none) return error.TypeError;
        if (equal(name, "fillStyle")) {
            surface.fill_style = try canvasColor(runtime, value);
            return true;
        }
        if (equal(name, "strokeStyle")) {
            surface.stroke_style = try canvasColor(runtime, value);
            return true;
        }
        if (equal(name, "lineWidth")) {
            surface.line_width = @max(1, try runtime.valueNumber(value));
            return true;
        }
        return false;
    }
    if (tag >= host_object_node_base) {
        const node: u16 = tag - host_object_node_base;
        const document = self.document orelse return error.NotInitialized;
        if (node >= document.node_count) return error.InvalidNode;
        const text_value = if (value == .null_value) "" else try coercedText(runtime, value);
        if (document.nodes[node].kind == .element and std.ascii.eqlIgnoreCase(document.nodeName(node), "canvas") and (equal(name, "width") or equal(name, "height"))) {
            const dimension = try runtime.valueNumber(value);
            if (dimension < 1 or dimension > web_canvas.max_dimension) return error.SizeLimit;
            var raw: [16]u8 = undefined;
            const encoded = std.fmt.bufPrint(raw[0..], "{d}", .{@as(u32, @intFromFloat(dimension))}) catch return error.TypeError;
            try document.setAttribute(node, name, encoded);
            _ = try self.canvasForNode(node);
            try self.markDomChanged(node);
            return true;
        }
        if (equal(name, "textContent")) {
            try self.mutateTextContent(node, text_value);
        } else if (equal(name, "nodeValue")) {
            if (document.nodes[node].kind != .text and document.nodes[node].kind != .comment) return true;
            try self.mutateTextContent(node, text_value);
        } else if (equal(name, "id")) {
            if (document.nodes[node].kind != .element) return false;
            const old_value = document.attribute(node, "id");
            try document.setAttribute(node, "id", text_value);
            try self.queueMutation(.attributes, node, &.{}, &.{}, null, null, "id", old_value);
        } else if (equal(name, "className")) {
            if (document.nodes[node].kind != .element) return false;
            const old_value = document.attribute(node, "class");
            try document.setAttribute(node, "class", text_value);
            try self.queueMutation(.attributes, node, &.{}, &.{}, null, null, "class", old_value);
        } else if (equal(name, "value")) {
            if (document.nodes[node].kind != .element) return false;
            const old_value = document.attribute(node, "value");
            try document.setAttribute(node, "value", text_value);
            try self.queueMutation(.attributes, node, &.{}, &.{}, null, null, "value", old_value);
        } else if (document.nodes[node].kind == .element and
            ((std.ascii.eqlIgnoreCase(document.nodeName(node), "img") and
                (equal(name, "src") or equal(name, "srcset") or equal(name, "sizes"))) or
                (std.ascii.eqlIgnoreCase(document.nodeName(node), "source") and
                    (equal(name, "srcset") or equal(name, "sizes") or equal(name, "media") or equal(name, "type")))))
        {
            const old_value = document.attribute(node, name);
            try document.setAttribute(node, name, text_value);
            try self.queueMutation(.attributes, node, &.{}, &.{}, null, null, name, old_value);
            try self.refreshImageSelectionForMutation(node, name);
        } else {
            return false;
        }
        try self.markDomChanged(node);
        return true;
    }
    return false;
}

fn hostDispatch(
    runtime: *javascript.Runtime,
    raw_context: ?*anyopaque,
    raw_tag: u16,
    receiver: javascript.Value,
    arguments: []const javascript.Value,
) javascript.Error!javascript.Value {
    const self: *WebRuntime = @ptrCast(@alignCast(raw_context orelse return error.TypeError));
    const operation: HostOp = @enumFromInt(raw_tag);
    return dispatchHost(self, runtime, operation, receiver, arguments) catch |err| switch (err) {
        error.UnknownEncoding => error.RangeError,
        error.ScriptThrown => error.ScriptThrown,
        else => error.TypeError,
    };
}

fn dispatchHost(
    self: *WebRuntime,
    runtime: *javascript.Runtime,
    operation: HostOp,
    receiver: javascript.Value,
    arguments: []const javascript.Value,
) Error!javascript.Value {
    switch (operation) {
        .add_event_listener, .node_add_event_listener => {
            if (arguments.len < 2) return error.TypeError;
            if (arguments[1] == .null_value or arguments[1] == .undefined) return .undefined;
            const target = if (operation == .node_add_event_listener)
                eventTargetToken(.{ .node = try self.receiverNode(receiver) })
            else if (receiver == .undefined)
                eventTargetToken(.window)
            else
                try self.receiverEventTarget(receiver);
            const options = if (arguments.len > 2) arguments[2] else javascript.Value.undefined;
            try self.addListener(target, try coercedText(runtime, arguments[0]), arguments[1], try WebRuntime.listenerOption(runtime, options, "once"), try WebRuntime.listenerOption(runtime, options, "capture"));
            return .undefined;
        },
        .remove_event_listener => {
            if (arguments.len < 2) return error.TypeError;
            self.removeListener(
                if (receiver == .undefined) eventTargetToken(.window) else try self.receiverEventTarget(receiver),
                try coercedText(runtime, arguments[0]),
                arguments[1],
                try WebRuntime.listenerOption(runtime, if (arguments.len > 2) arguments[2] else .undefined, "capture"),
            );
            return .undefined;
        },
        .event_constructor => {
            if (!runtime.hostCallIsConstruct() or arguments.len == 0) return error.TypeError;
            const options = if (arguments.len > 1) arguments[1] else javascript.Value.undefined;
            const bubbles = if (options == .undefined or options == .null_value) false else runtime.valueBoolean(try runtime.get(options, "bubbles"));
            const cancelable = if (options == .undefined or options == .null_value) false else runtime.valueBoolean(try runtime.get(options, "cancelable"));
            const composed = if (options == .undefined or options == .null_value) false else runtime.valueBoolean(try runtime.get(options, "composed"));
            return self.makeDomEvent(try coercedText(runtime, arguments[0]), bubbles, cancelable, composed, 0);
        },
        .dispatch_event => {
            if (arguments.len == 0) return error.TypeError;
            const target = if (receiver == .undefined) self.runtime.global("window") orelse return error.TypeError else receiver;
            return .{ .boolean = try self.dispatchDomEvent(try self.receiverEventTarget(target), target, arguments[0]) };
        },
        .document_get_element_by_id => {
            const document = self.document orelse return error.NotInitialized;
            const node = document.findElementById(try coercedText(runtime, if (arguments.len > 0) arguments[0] else .undefined)) orelse return .null_value;
            return self.makeNode(node);
        },
        .frame_document_get_element_by_id, .frame_document_query_selector => {
            const state = try runtime.hostState(receiver, host_object_frame_document);
            const iframe_number = try runtime.valueNumber(state[0]);
            if (iframe_number < 0 or iframe_number >= html.max_nodes) return error.InvalidNode;
            const iframe: u16 = @intFromFloat(iframe_number);
            const info = self.frameInfo(iframe) orelse return error.StaleGeneration;
            if (!info.same_origin) return error.SecurityBlocked;
            const document = info.document orelse return error.StaleGeneration;
            const argument = try coercedText(runtime, if (arguments.len > 0) arguments[0] else .undefined);
            const node = if (operation == .frame_document_get_element_by_id)
                document.findElementById(argument)
            else
                document.querySelector(argument);
            return if (node) |child| self.makeFrameNode(iframe, child) else .null_value;
        },
        .document_query_selector => {
            const selector = try coercedText(runtime, if (arguments.len > 0) arguments[0] else .undefined);
            const node = try self.firstDomNode(0, .{ .selector = selector }) orelse return .null_value;
            return self.makeNode(node);
        },
        .document_query_selector_all => {
            const selector = try coercedText(runtime, if (arguments.len > 0) arguments[0] else .undefined);
            return self.makeDomNodeList(0, .{ .selector = selector });
        },
        .document_get_elements_by_tag_name => {
            const tag = try coercedText(runtime, if (arguments.len > 0) arguments[0] else .undefined);
            return self.makeDomNodeList(0, .{ .tag = tag });
        },
        .document_get_elements_by_class_name => {
            const class_name = try coercedText(runtime, if (arguments.len > 0) arguments[0] else .undefined);
            return self.makeDomNodeList(0, .{ .class = class_name });
        },
        .document_create_element => {
            const document = self.document orelse return error.NotInitialized;
            const node = try document.appendElement(0, try coercedText(runtime, if (arguments.len > 0) arguments[0] else .undefined));
            try document.detach(node);
            return self.makeNode(node);
        },
        .document_create_text_node => {
            const document = self.document orelse return error.NotInitialized;
            return self.makeNode(try document.createTextNode(try coercedText(runtime, if (arguments.len > 0) arguments[0] else .undefined)));
        },
        .document_get_cookie => {
            const browser_storage = self.storage orelse return error.NotInitialized;
            var out: [1024]u8 = undefined;
            return runtime.makeString(browser_storage.cookies.writeDocumentCookie(&self.security_context.document_origin, self.path(), out[0..]));
        },
        .document_set_cookie => {
            const browser_storage = self.storage orelse return error.NotInitialized;
            try browser_storage.cookies.setFromDocument(&self.security_context.document_origin, self.path(), self.argumentString(arguments, 0));
            return .undefined;
        },
        .node_get_attribute => {
            const document = self.document orelse return error.NotInitialized;
            const value = document.attribute(try self.receiverNode(receiver), try coercedText(runtime, if (arguments.len > 0) arguments[0] else .undefined)) orelse return .null_value;
            return runtime.makeString(value);
        },
        .frame_node_get_attribute => {
            const frame = try self.frameNodes(runtime, receiver, host_object_frame_node);
            const value = frame.document.attribute(frame.child, try coercedText(runtime, if (arguments.len > 0) arguments[0] else .undefined)) orelse return .null_value;
            return runtime.makeString(value);
        },
        .node_set_attribute => {
            const document = self.document orelse return error.NotInitialized;
            const node = try self.receiverNode(receiver);
            if (arguments.len < 2) return error.TypeError;
            const name = try coercedText(runtime, arguments[0]);
            const old_value = document.attribute(node, name);
            try document.setAttribute(node, name, try coercedText(runtime, arguments[1]));
            try self.queueMutation(.attributes, node, &.{}, &.{}, null, null, name, old_value);
            try self.markDomChanged(node);
            try self.refreshImageSelectionForMutation(node, name);
            return .undefined;
        },
        .frame_node_set_attribute => {
            if (arguments.len < 2) return error.TypeError;
            const frame = try self.frameNodes(runtime, receiver, host_object_frame_node);
            try frame.document.setAttribute(frame.child, try coercedText(runtime, arguments[0]), try coercedText(runtime, arguments[1]));
            if (frame.child_runtime) |child_runtime| child_runtime.dom_dirty = true;
            return .undefined;
        },
        .node_has_attribute => {
            const document = self.document orelse return error.NotInitialized;
            return .{ .boolean = document.hasAttribute(try self.receiverNode(receiver), try coercedText(runtime, if (arguments.len > 0) arguments[0] else .undefined)) };
        },
        .node_remove_attribute => {
            const document = self.document orelse return error.NotInitialized;
            const node = try self.receiverNode(receiver);
            const name = try coercedText(runtime, if (arguments.len > 0) arguments[0] else .undefined);
            const old_value = document.attribute(node, name);
            if (try document.removeAttribute(node, name)) {
                try self.queueMutation(.attributes, node, &.{}, &.{}, null, null, name, old_value);
                try self.markDomChanged(node);
                try self.refreshImageSelectionForMutation(node, name);
            }
            return .undefined;
        },
        .node_toggle_attribute => {
            const document = self.document orelse return error.NotInitialized;
            const node = try self.receiverNode(receiver);
            const name = try coercedText(runtime, if (arguments.len > 0) arguments[0] else .undefined);
            const present = document.hasAttribute(node, name);
            const force: ?bool = if (arguments.len > 1 and arguments[1] != .undefined) runtime.valueBoolean(arguments[1]) else null;
            const wanted = force orelse !present;
            if (wanted and !present) {
                try document.setAttribute(node, name, "");
                try self.queueMutation(.attributes, node, &.{}, &.{}, null, null, name, null);
                try self.markDomChanged(node);
                try self.refreshImageSelectionForMutation(node, name);
            } else if (!wanted and present) {
                const old_value = document.attribute(node, name);
                _ = try document.removeAttribute(node, name);
                try self.queueMutation(.attributes, node, &.{}, &.{}, null, null, name, old_value);
                try self.markDomChanged(node);
                try self.refreshImageSelectionForMutation(node, name);
            }
            return .{ .boolean = wanted };
        },
        .node_append_child => {
            const document = self.document orelse return error.NotInitialized;
            const parent = try self.receiverNode(receiver);
            const child = if (arguments.len > 0) try self.receiverNode(arguments[0]) else return error.TypeError;
            const old_parent = if (document.nodes[child].parent != html.none) document.nodes[child].parent else null;
            const old_previous = document.previousSibling(child);
            const old_next = if (document.nodes[child].next_sibling != html.none) document.nodes[child].next_sibling else null;
            try document.attach(parent, child);
            if (old_parent) |source_parent| {
                try self.queueMutation(.child_list, source_parent, &.{}, &.{child}, old_previous, old_next, null, null);
                try self.refreshPictureImages(source_parent);
            }
            try self.queueMutation(.child_list, parent, &.{child}, &.{}, document.previousSibling(child), null, null, null);
            try self.markDomChanged(child);
            try self.scheduleDynamicResources(child, 0);
            return arguments[0];
        },
        .node_insert_before => {
            const document = self.document orelse return error.NotInitialized;
            if (arguments.len < 2) return error.TypeError;
            const parent = try self.receiverNode(receiver);
            const child = try self.receiverNode(arguments[0]);
            const old_parent = if (document.nodes[child].parent != html.none) document.nodes[child].parent else null;
            const old_previous = document.previousSibling(child);
            const old_next = if (document.nodes[child].next_sibling != html.none) document.nodes[child].next_sibling else null;
            if (arguments[1] == .null_value) try document.attach(parent, child) else try document.insertBefore(parent, child, try self.receiverNode(arguments[1]));
            if (old_parent) |source_parent| {
                try self.queueMutation(.child_list, source_parent, &.{}, &.{child}, old_previous, old_next, null, null);
                try self.refreshPictureImages(source_parent);
            }
            try self.queueMutation(.child_list, parent, &.{child}, &.{}, document.previousSibling(child), if (document.nodes[child].next_sibling != html.none) document.nodes[child].next_sibling else null, null, null);
            try self.markDomChanged(child);
            try self.scheduleDynamicResources(child, 0);
            return arguments[0];
        },
        .node_remove_child => {
            const document = self.document orelse return error.NotInitialized;
            if (arguments.len == 0) return error.TypeError;
            const parent = try self.receiverNode(receiver);
            const child = try self.receiverNode(arguments[0]);
            const previous = document.previousSibling(child);
            const next = if (document.nodes[child].next_sibling != html.none) document.nodes[child].next_sibling else null;
            try document.removeChild(parent, child);
            self.cancelImageResourcesInSubtree(child, 0);
            try self.queueMutation(.child_list, parent, &.{}, &.{child}, previous, next, null, null);
            try self.markDomChanged(child);
            try self.refreshPictureImages(parent);
            return arguments[0];
        },
        .node_replace_child => {
            const document = self.document orelse return error.NotInitialized;
            if (arguments.len < 2) return error.TypeError;
            const replacement = try self.receiverNode(arguments[0]);
            const replaced = try self.receiverNode(arguments[1]);
            const parent = try self.receiverNode(receiver);
            const previous = document.previousSibling(replaced);
            const next = if (document.nodes[replaced].next_sibling != html.none) document.nodes[replaced].next_sibling else null;
            const old_parent = if (document.nodes[replacement].parent != html.none) document.nodes[replacement].parent else null;
            if (old_parent) |source_parent| {
                const old_previous = document.previousSibling(replacement);
                const old_next = if (document.nodes[replacement].next_sibling != html.none) document.nodes[replacement].next_sibling else null;
                try document.replaceChild(parent, replacement, replaced);
                try self.queueMutation(.child_list, source_parent, &.{}, &.{replacement}, old_previous, old_next, null, null);
                try self.refreshPictureImages(source_parent);
            } else try document.replaceChild(parent, replacement, replaced);
            self.cancelImageResourcesInSubtree(replaced, 0);
            try self.queueMutation(.child_list, parent, &.{replacement}, &.{replaced}, previous, next, null, null);
            try self.markDomChanged(replacement);
            try self.scheduleDynamicResources(replacement, 0);
            try self.refreshPictureImages(parent);
            return arguments[1];
        },
        .node_remove => {
            const document = self.document orelse return error.NotInitialized;
            const node = try self.receiverNode(receiver);
            if (document.nodes[node].parent != html.none) {
                const parent = document.nodes[node].parent;
                const previous = document.previousSibling(node);
                const next = if (document.nodes[node].next_sibling != html.none) document.nodes[node].next_sibling else null;
                try document.detach(node);
                self.cancelImageResourcesInSubtree(node, 0);
                try self.queueMutation(.child_list, parent, &.{}, &.{node}, previous, next, null, null);
                try self.markDomChanged(node);
                try self.refreshPictureImages(parent);
            }
            return .undefined;
        },
        .node_clone_node => {
            const document = self.document orelse return error.NotInitialized;
            const deep = arguments.len > 0 and runtime.valueBoolean(arguments[0]);
            return self.makeNode(try document.cloneNode(try self.receiverNode(receiver), deep));
        },
        .node_contains => {
            const document = self.document orelse return error.NotInitialized;
            if (arguments.len == 0 or arguments[0] == .null_value) return .{ .boolean = false };
            return .{ .boolean = document.contains(try self.receiverNode(receiver), try self.receiverNode(arguments[0])) };
        },
        .node_has_child_nodes => {
            const document = self.document orelse return error.NotInitialized;
            return .{ .boolean = document.nodes[try self.receiverNode(receiver)].first_child != html.none };
        },
        .node_query_selector, .node_query_selector_all => {
            const root = try self.receiverNode(receiver);
            const selector = try coercedText(runtime, if (arguments.len > 0) arguments[0] else .undefined);
            if (operation == .node_query_selector_all) return self.makeDomNodeList(root, .{ .selector = selector });
            const node = try self.firstDomNode(root, .{ .selector = selector }) orelse return .null_value;
            return self.makeNode(node);
        },
        .node_matches => {
            const document = self.document orelse return error.NotInitialized;
            return .{ .boolean = css.matchesSelector(document, try self.receiverNode(receiver), try coercedText(runtime, if (arguments.len > 0) arguments[0] else .undefined)) };
        },
        .node_closest => {
            const document = self.document orelse return error.NotInitialized;
            const selector = try coercedText(runtime, if (arguments.len > 0) arguments[0] else .undefined);
            var node = try self.receiverNode(receiver);
            while (node != html.none and node < document.node_count) : (node = document.nodes[node].parent) {
                if (css.matchesSelector(document, node, selector)) return self.makeNode(node);
            }
            return .null_value;
        },
        .node_replace_text => {
            const node = try self.receiverNode(receiver);
            try self.mutateTextContent(node, try coercedText(runtime, if (arguments.len > 0) arguments[0] else .undefined));
            try self.markDomChanged(node);
            return .undefined;
        },
        .mutation_observer_constructor => {
            if (!runtime.hostCallIsConstruct() or arguments.len == 0 or !runtime.valueCallable(arguments[0])) return error.TypeError;
            var observer_index: ?usize = null;
            for (&self.mutation_observers, 0..) |*observer, index| if (!observer.occupied) {
                observer_index = index;
                break;
            };
            const index = observer_index orelse return error.MutationLimit;
            const root_mark = runtime.hostRootMark();
            defer runtime.restoreHostRoots(root_mark);
            const object = try runtime.createObject();
            try runtime.hostRoot(object);
            if (runtime.global("MutationObserver")) |constructor| try runtime.setPrototype(object, try runtime.get(constructor, "prototype"));
            const delivery = try runtime.createHostFunction(@intFromEnum(HostOp.mutation_observer_deliver), self, hostDispatch);
            try runtime.hostRoot(delivery);
            try runtime.setHostPropertyHooks(object, host_object_mutation_observer, self, null, null);
            try runtime.setHostState(object, host_object_mutation_observer, .{ .number = @floatFromInt(index) }, arguments[0]);
            self.mutation_observers[index] = .{
                .occupied = true,
                .object = object,
                .callback = arguments[0],
                .delivery = delivery,
            };
            return object;
        },
        .mutation_observer_observe => {
            if (arguments.len < 2) return error.TypeError;
            const index = try self.observerIndex(runtime, receiver);
            const target = try self.mutationTarget(runtime, arguments[0]);
            const registration = try self.parseMutationRegistration(runtime, target, arguments[1]);
            var observer = &self.mutation_observers[index];
            for (observer.registrations[0..observer.registration_count]) |*existing| if (existing.target == target) {
                existing.* = registration;
                return .undefined;
            };
            if (observer.registration_count >= observer.registrations.len) return error.MutationLimit;
            observer.registrations[observer.registration_count] = registration;
            observer.registration_count += 1;
            return .undefined;
        },
        .mutation_observer_disconnect => {
            const index = try self.observerIndex(runtime, receiver);
            var observer = &self.mutation_observers[index];
            observer.registration_count = 0;
            for (observer.records[0..observer.record_count]) |*record| record.* = .undefined;
            observer.record_count = 0;
            observer.transient_root_count = 0;
            observer.delivery_queued = false;
            return .undefined;
        },
        .mutation_observer_take_records => {
            const index = try self.observerIndex(runtime, receiver);
            return self.takeMutationRecords(&self.mutation_observers[index]);
        },
        .mutation_observer_deliver => {
            if (arguments.len == 0) return .undefined;
            const number = try runtime.valueNumber(arguments[0]);
            if (number < 0 or number >= self.mutation_observers.len) return .undefined;
            const index: usize = @intFromFloat(number);
            var observer = &self.mutation_observers[index];
            if (!observer.occupied) return .undefined;
            observer.delivery_queued = false;
            observer.transient_root_count = 0;
            if (observer.record_count == 0) return .undefined;
            const root_mark = runtime.hostRootMark();
            defer runtime.restoreHostRoots(root_mark);
            const records = try self.takeMutationRecords(observer);
            try runtime.hostRoot(records);
            try runtime.hostRoot(observer.object);
            try runtime.hostRoot(observer.callback);
            const program = runtime.activeProgram() orelse return error.TypeError;
            _ = try runtime.callValue(program, observer.callback, observer.object, &.{ records, observer.object });
            return .undefined;
        },
        .location_assign, .location_replace => {
            if ((runtime.hostTag(receiver) catch 0) != host_object_location) return error.TypeError;
            if (arguments.len == 0) return error.TypeError;
            const target = try self.resolveValueUrl(runtime, arguments[0]);
            try self.enqueueAction(if (operation == .location_assign) .navigate else .replace, target, html.none);
            return .undefined;
        },
        .location_to_string => {
            if ((runtime.hostTag(receiver) catch 0) != host_object_location) return error.TypeError;
            return runtime.makeString(self.document_url.bytes());
        },
        .location_reload => {
            if ((runtime.hostTag(receiver) catch 0) != host_object_location) return error.TypeError;
            try self.enqueueAction(.reload, null, html.none);
            return .undefined;
        },
        .history_back, .history_forward => {
            if ((runtime.hostTag(receiver) catch 0) != host_object_history) return error.TypeError;
            const delta: i32 = if (operation == .history_back) -1 else 1;
            const destination = @as(i64, @intCast(self.history_index)) + delta;
            if (destination < 0 or destination >= self.history_count) return .undefined;
            try self.enqueueTraversal(delta);
            return .undefined;
        },
        .history_go => {
            if ((runtime.hostTag(receiver) catch 0) != host_object_history) return error.TypeError;
            const raw_delta = if (arguments.len > 0 and arguments[0] != .undefined) try runtime.valueNumber(arguments[0]) else 0;
            const delta: i32 = if (!std.math.isFinite(raw_delta)) 0 else @intFromFloat(@max(@as(f64, std.math.minInt(i32)), @min(@as(f64, std.math.maxInt(i32)), @trunc(raw_delta))));
            if (delta != 0) {
                const destination = @as(i64, @intCast(self.history_index)) + delta;
                if (destination < 0 or destination >= self.history_count) return .undefined;
            }
            if (delta == 0) {
                try self.enqueueAction(.reload, null, html.none);
            } else {
                try self.enqueueTraversal(delta);
            }
            return .undefined;
        },
        .history_push_state, .history_replace_state => {
            if ((runtime.hostTag(receiver) catch 0) != host_object_history) return error.TypeError;
            if (arguments.len < 2) return error.TypeError;
            const target = if (arguments.len > 2 and arguments[2] != .undefined)
                try self.resolveValueUrl(runtime, arguments[2])
            else
                self.document_url;
            const decision = self.security_context.authorize(self.generation, target.bytes(), .document, .same_origin);
            if (!decision.allowed) return error.SecurityBlocked;
            const replace = operation == .history_replace_state;
            try self.updateSameDocumentHistory(replace, target, arguments[0]);
            try self.enqueueAction(if (replace) .replace_state else .push_state, target, html.none);
            _ = try self.dispatchNavigationEvent("currententrychange", target, self.history_index, if (replace) "replace" else "push", false);
            return .undefined;
        },
        .navigation_entries => {
            if ((runtime.hostTag(receiver) catch 0) != host_object_navigation) return error.TypeError;
            const root_mark = runtime.hostRootMark();
            defer runtime.restoreHostRoots(root_mark);
            var entries: [navigation.history_capacity]javascript.Value = undefined;
            for (0..self.history_count) |index| {
                entries[index] = try self.makeNavigationEntry(index);
                try runtime.hostRoot(entries[index]);
            }
            return runtime.createArray(entries[0..self.history_count]);
        },
        .navigation_navigate => {
            if ((runtime.hostTag(receiver) catch 0) != host_object_navigation) return error.TypeError;
            if (arguments.len == 0) return error.TypeError;
            const target = try self.resolveValueUrl(runtime, arguments[0]);
            const options = if (arguments.len > 1) arguments[1] else javascript.Value.undefined;
            const history_mode = if (options == .undefined or options == .null_value or (try runtime.get(options, "history")) == .undefined)
                "auto"
            else
                try coercedText(runtime, try runtime.get(options, "history"));
            if (!equal(history_mode, "auto") and !equal(history_mode, "push") and !equal(history_mode, "replace")) return error.TypeError;
            const replace = equal(history_mode, "replace");
            const accepted = try self.dispatchNavigationEvent("navigate", target, null, if (replace) "replace" else "push", true);
            if (!accepted) return self.makeFailedNavigationResult("Navigation was cancelled");
            try self.enqueueAction(if (replace) .replace else .navigate, target, html.none);
            return self.makeNavigationResult(try self.makeNavigationEntryValue(target, .null_value, self.next_history_id, self.history_index, false));
        },
        .navigation_reload => {
            if ((runtime.hostTag(receiver) catch 0) != host_object_navigation) return error.TypeError;
            const accepted = try self.dispatchNavigationEvent("navigate", self.document_url, self.history_index, "reload", true);
            if (!accepted) return self.makeFailedNavigationResult("Navigation was cancelled");
            try self.enqueueAction(.reload, null, html.none);
            return self.makeNavigationResult(try self.makeNavigationEntry(self.history_index));
        },
        .navigation_back, .navigation_forward => {
            if ((runtime.hostTag(receiver) catch 0) != host_object_navigation) return error.TypeError;
            const delta: i32 = if (operation == .navigation_back) -1 else 1;
            const destination = @as(i64, @intCast(self.history_index)) + delta;
            if (destination < 0 or destination >= self.history_count) return self.makeFailedNavigationResult("No history entry is available");
            const target_index: usize = @intCast(destination);
            const accepted = try self.dispatchNavigationEvent("navigate", self.history_urls[target_index], target_index, "traverse", true);
            if (!accepted) return self.makeFailedNavigationResult("Navigation was cancelled");
            try self.enqueueTraversal(delta);
            return self.makeNavigationResult(try self.makeNavigationEntry(target_index));
        },
        .navigation_traverse_to => {
            if ((runtime.hostTag(receiver) catch 0) != host_object_navigation) return error.TypeError;
            if (arguments.len == 0) return error.TypeError;
            const wanted = try coercedText(runtime, arguments[0]);
            var target_index: ?usize = null;
            for (0..self.history_count) |index| {
                var key_buffer: [48]u8 = undefined;
                if (equal(wanted, try self.navigationEntryKey(index, key_buffer[0..]))) {
                    target_index = index;
                    break;
                }
            }
            const index = target_index orelse return self.makeFailedNavigationResult("The history key was not found");
            const delta: i32 = @intCast(@as(i64, @intCast(index)) - @as(i64, @intCast(self.history_index)));
            if (delta != 0) {
                if (!try self.dispatchNavigationEvent("navigate", self.history_urls[index], index, "traverse", true)) return self.makeFailedNavigationResult("Navigation was cancelled");
                try self.enqueueTraversal(delta);
            }
            return self.makeNavigationResult(try self.makeNavigationEntry(index));
        },
        .navigation_update_current_entry => {
            if ((runtime.hostTag(receiver) catch 0) != host_object_navigation) return error.TypeError;
            if (arguments.len == 0 or arguments[0] != .cell) return error.TypeError;
            const state = try runtime.get(arguments[0], "state");
            if (state == .undefined) return error.TypeError;
            self.history_states[self.history_index] = state;
            if (self.navigation_entry_objects[self.history_index] != .undefined) try runtime.setHostState(self.navigation_entry_objects[self.history_index], host_object_navigation_entry, state, .{ .number = @floatFromInt(self.history_index) });
            _ = try self.dispatchNavigationEvent("currententrychange", self.document_url, self.history_index, "replace", false);
            return .undefined;
        },
        .navigation_entry_get_state => return (try runtime.hostState(receiver, host_object_navigation_entry))[0],
        .storage_get => {
            const value = (try self.storageArea(receiver)).get(self.argumentString(arguments, 0)) orelse return .null_value;
            return runtime.makeString(value);
        },
        .storage_set => {
            const area = try self.storageArea(receiver);
            try area.set(self.argumentString(arguments, 0), self.argumentString(arguments, 1));
            try runtime.set(receiver, "length", .{ .number = @floatFromInt(area.count()) });
            return .undefined;
        },
        .storage_remove => {
            const area = try self.storageArea(receiver);
            area.remove(self.argumentString(arguments, 0));
            try runtime.set(receiver, "length", .{ .number = @floatFromInt(area.count()) });
            return .undefined;
        },
        .storage_clear => {
            const area = try self.storageArea(receiver);
            area.clear();
            try runtime.set(receiver, "length", .{ .number = 0 });
            return .undefined;
        },
        .storage_key => {
            const area = try self.storageArea(receiver);
            const wanted = if (arguments.len > 0) @as(usize, @intFromFloat(@max(0, try runtime.valueNumber(arguments[0])))) else 0;
            var seen: usize = 0;
            for (area.entries) |entry| {
                if (!entry.occupied) continue;
                if (seen == wanted) return runtime.makeString(entry.key.bytes());
                seen += 1;
            }
            return .null_value;
        },
        .performance_now => return .{ .number = @max(0, self.currentMonotonicMilliseconds() - self.timing.time_origin_ms) },
        .performance_get_entries => return self.makeSingleValueArray(try self.makePerformanceNavigationEntry()),
        .performance_entries_by_type => {
            const kind = try coercedText(runtime, if (arguments.len > 0) arguments[0] else .undefined);
            return if (equal(kind, "navigation")) self.makeSingleValueArray(try self.makePerformanceNavigationEntry()) else runtime.createArray(&.{});
        },
        .performance_entries_by_name => {
            const wanted = try coercedText(runtime, if (arguments.len > 0) arguments[0] else .undefined);
            const type_filter = if (arguments.len > 1 and arguments[1] != .undefined) try coercedText(runtime, arguments[1]) else "";
            return if (equal(wanted, self.document_url.bytes()) and (type_filter.len == 0 or equal(type_filter, "navigation"))) self.makeSingleValueArray(try self.makePerformanceNavigationEntry()) else runtime.createArray(&.{});
        },
        .performance_entry_to_json => {
            if ((runtime.hostTag(receiver) catch 0) != host_object_performance_navigation_timing) return error.TypeError;
            const root_mark = runtime.hostRootMark();
            defer runtime.restoreHostRoots(root_mark);
            const copy = try runtime.createObject();
            try runtime.hostRoot(copy);
            for ([_][]const u8{ "name", "entryType", "startTime", "duration", "initiatorType", "nextHopProtocol", "workerStart", "redirectStart", "redirectEnd", "fetchStart", "domainLookupStart", "domainLookupEnd", "connectStart", "secureConnectionStart", "connectEnd", "requestStart", "responseStart", "responseEnd", "transferSize", "encodedBodySize", "decodedBodySize", "unloadEventStart", "unloadEventEnd", "domInteractive", "domContentLoadedEventStart", "domContentLoadedEventEnd", "domComplete", "loadEventStart", "loadEventEnd", "type", "redirectCount", "criticalCHRestart", "notRestoredReasons" }) |name| try runtime.set(copy, name, try runtime.get(receiver, name));
            return copy;
        },
        .performance_navigation_timing_constructor => return error.TypeError,
        .set_timeout, .set_interval => {
            if (arguments.len == 0) return error.TypeError;
            const delay = if (arguments.len > 1) try runtime.valueNumber(arguments[1]) else 0;
            return .{ .number = @floatFromInt(try self.createTimer(arguments[0], delay, operation == .set_interval)) };
        },
        .clear_timeout, .clear_interval => {
            if (arguments.len > 0) self.clearTimer(@intFromFloat(@max(0, try runtime.valueNumber(arguments[0]))));
            return .undefined;
        },
        .fetch => {
            const root_mark = runtime.hostRootMark();
            defer runtime.restoreHostRoots(root_mark);
            const promise = try runtime.createPromise();
            try runtime.hostRoot(promise);
            if (arguments.len == 0) {
                try runtime.rejectPromise(promise, try self.makeTypeError(runtime, "Fetch requires a request input"));
                return promise;
            }
            const request = if ((runtime.hostTag(arguments[0]) catch 0) == host_object_request and (arguments.len < 2 or arguments[1] == .undefined))
                arguments[0]
            else blk: {
                const program = runtime.activeProgram() orelse return error.TypeError;
                const constructor = runtime.global("Request") orelse return error.TypeError;
                break :blk try runtime.constructValue(program, constructor, arguments[0..@min(arguments.len, 2)]);
            };
            try runtime.hostRoot(request);
            const state = try self.requestState(runtime, request);
            const flags = try self.bodyFlags(runtime, state[1]);
            if ((flags & 3) != 0) {
                try runtime.rejectPromise(promise, try self.makeTypeError(runtime, "Request body has already been used or is locked"));
                return promise;
            }
            const record = state[0];
            const signal = try self.requestField(runtime, record, .signal);
            const signal_record = try self.abortSignalRecord(runtime, signal);
            if (runtime.valueBoolean(try self.abortField(runtime, signal_record, abort_aborted))) {
                try runtime.rejectPromise(promise, try self.abortField(runtime, signal_record, abort_reason));
                return promise;
            }
            const target = try navigation.parse(runtime.valueString(try self.requestField(runtime, record, .url)));
            const headers_value = try self.headersFromInit(runtime, try self.requestField(runtime, record, .headers));
            var serialized: [web_fetch.max_serialized_bytes]u8 = undefined;
            const body_bytes: []const u8 = if (state[1] == .null_value) "" else try self.bodyBytes(runtime, state[1]);
            _ = self.queueRequest(target, .fetch, promise, .undefined, .{
                .mode = try securityRequestMode(runtime.valueString(try self.requestField(runtime, record, .mode))),
                .credentials = try securityCredentialsMode(runtime.valueString(try self.requestField(runtime, record, .credentials))),
                .method = try httpMethod(runtime.valueString(try self.requestField(runtime, record, .method))),
                .redirect = try fetchRedirectMode(runtime.valueString(try self.requestField(runtime, record, .redirect))),
                .headers = try headers_value.serialize(serialized[0..]),
                .body = body_bytes,
                .signal = signal,
            }) catch |err| {
                const message = if (err == error.SecurityBlocked) blockText(self.last_block_reason) else @errorName(err);
                try runtime.rejectPromise(promise, try self.makeTypeError(runtime, message));
                return promise;
            };
            if (state[1] != .null_value) try self.setBodyFlags(runtime, state[1], flags | 1);
            return promise;
        },
        .abort_controller_constructor => {
            if (!runtime.hostCallIsConstruct()) return error.TypeError;
            const controller = try runtime.createObject();
            if (runtime.global("AbortController")) |constructor| try runtime.setPrototype(controller, try runtime.get(constructor, "prototype"));
            try runtime.setHostPropertyHooks(controller, host_object_abort_controller, self, null, null);
            try runtime.setHostState(controller, host_object_abort_controller, try self.makeAbortSignal(false, .undefined), .undefined);
            return controller;
        },
        .abort_controller_get_signal => return (try runtime.hostState(receiver, host_object_abort_controller))[0],
        .abort_controller_abort => {
            const signal = (try runtime.hostState(receiver, host_object_abort_controller))[0];
            const reason = if (arguments.len > 0 and arguments[0] != .undefined) arguments[0] else try self.makeNamedError(runtime, "AbortError", "This operation was aborted");
            try self.abortSignal(runtime, signal, reason);
            return .undefined;
        },
        .abort_signal_abort_static => {
            const reason = if (arguments.len > 0 and arguments[0] != .undefined) arguments[0] else try self.makeNamedError(runtime, "AbortError", "This operation was aborted");
            return self.makeAbortSignal(true, reason);
        },
        .abort_signal_timeout_static => {
            if (arguments.len == 0) return error.TypeError;
            const delay = try runtime.valueNumber(arguments[0]);
            if (std.math.isNan(delay) or delay < 0 or delay > 86_400_000 or @trunc(delay) != delay) return error.RangeError;
            const signal = try self.makeAbortSignal(false, .undefined);
            for (&self.abort_deadlines) |*deadline| {
                if (deadline.occupied) continue;
                deadline.* = .{ .occupied = true, .generation = self.generation, .due_ms = self.timing.now_ms + delay, .signal = signal };
                return signal;
            }
            return error.AbortLimit;
        },
        .abort_signal_any_static => {
            if (arguments.len == 0) return error.TypeError;
            const root_mark = runtime.hostRootMark();
            defer runtime.restoreHostRoots(root_mark);
            const program = runtime.activeProgram() orelse return error.TypeError;
            const array_constructor = runtime.global("Array") orelse return error.TypeError;
            const values = try runtime.callValue(program, try runtime.get(array_constructor, "from"), array_constructor, &.{arguments[0]});
            try runtime.hostRoot(values);
            const length_number = try runtime.valueNumber(try runtime.get(values, "length"));
            if (length_number < 0 or length_number > max_abort_followers) return error.AbortLimit;
            const length: usize = @intFromFloat(length_number);
            const signal = try self.makeAbortSignal(false, .undefined);
            try runtime.hostRoot(signal);
            var needed: usize = 0;
            var index: usize = 0;
            while (index < length) : (index += 1) {
                const source = try runtime.getKey(values, .{ .number = @floatFromInt(index) });
                const source_record = try self.abortSignalRecord(runtime, source);
                if (runtime.valueBoolean(try self.abortField(runtime, source_record, abort_aborted))) {
                    try self.abortSignal(runtime, signal, try self.abortField(runtime, source_record, abort_reason));
                    return signal;
                }
                needed += 1;
            }
            var free: usize = 0;
            for (self.abort_followers) |follower| if (!follower.occupied) {
                free += 1;
            };
            if (free < needed) return error.AbortLimit;
            index = 0;
            while (index < length) : (index += 1) {
                const source = try runtime.getKey(values, .{ .number = @floatFromInt(index) });
                for (&self.abort_followers) |*follower| {
                    if (follower.occupied) continue;
                    follower.* = .{ .occupied = true, .generation = self.generation, .source = source, .target = signal };
                    break;
                }
            }
            return signal;
        },
        .abort_signal_get_aborted, .abort_signal_get_reason, .abort_signal_get_onabort => {
            if (runtime.hostCallIsConstruct()) return error.TypeError;
            const record = try self.abortSignalRecord(runtime, receiver);
            return self.abortField(runtime, record, switch (operation) {
                .abort_signal_get_aborted => abort_aborted,
                .abort_signal_get_reason => abort_reason,
                .abort_signal_get_onabort => abort_onabort,
                else => unreachable,
            });
        },
        .abort_signal_set_onabort => {
            const record = try self.abortSignalRecord(runtime, receiver);
            const value = if (arguments.len == 0 or !runtime.valueCallable(arguments[0])) javascript.Value.null_value else arguments[0];
            try self.setAbortField(runtime, record, abort_onabort, value);
            return .undefined;
        },
        .abort_signal_throw_if_aborted => {
            if (runtime.hostCallIsConstruct()) return error.TypeError;
            const record = try self.abortSignalRecord(runtime, receiver);
            if (runtime.valueBoolean(try self.abortField(runtime, record, abort_aborted))) return runtime.throwValue(try self.abortField(runtime, record, abort_reason));
            return .undefined;
        },
        .abort_signal_add_event_listener => {
            const record = try self.abortSignalRecord(runtime, receiver);
            if (arguments.len < 2 or !equal(try coercedText(runtime, arguments[0]), "abort")) return .undefined;
            const callback = arguments[1];
            if (!runtime.valueCallable(callback)) {
                const handle = runtime.get(callback, "handleEvent") catch return .undefined;
                if (!runtime.valueCallable(handle)) return .undefined;
            }
            const count: usize = @intFromFloat(try runtime.valueNumber(try self.abortField(runtime, record, abort_listener_count)));
            var index: usize = 0;
            while (index < count) : (index += 1) {
                if (runtime.sameValue(try self.abortField(runtime, record, abort_listener_base + index), callback)) return .undefined;
            }
            if (count >= 16) return error.ListenerLimit;
            try self.setAbortField(runtime, record, abort_listener_base + count, callback);
            const once = if (arguments.len > 2 and arguments[2] != .undefined and arguments[2] != .null_value)
                if (arguments[2] == .boolean) runtime.valueBoolean(arguments[2]) else runtime.valueBoolean(try runtime.get(arguments[2], "once"))
            else
                false;
            try self.setAbortField(runtime, record, abort_listener_once_base + count, .{ .boolean = once });
            try self.setAbortField(runtime, record, abort_listener_count, .{ .number = @floatFromInt(count + 1) });
            return .undefined;
        },
        .abort_signal_remove_event_listener => {
            const record = try self.abortSignalRecord(runtime, receiver);
            if (arguments.len < 2 or !equal(try coercedText(runtime, arguments[0]), "abort")) return .undefined;
            const count: usize = @intFromFloat(try runtime.valueNumber(try self.abortField(runtime, record, abort_listener_count)));
            var index: usize = 0;
            while (index < count) : (index += 1) {
                if (runtime.sameValue(try self.abortField(runtime, record, abort_listener_base + index), arguments[1])) try self.setAbortField(runtime, record, abort_listener_base + index, .undefined);
            }
            return .undefined;
        },
        .request_constructor => {
            const root_mark = runtime.hostRootMark();
            defer runtime.restoreHostRoots(root_mark);
            if (!runtime.hostCallIsConstruct() or arguments.len == 0) return error.TypeError;
            const input = arguments[0];
            const source_is_request = (runtime.hostTag(input) catch 0) == host_object_request;
            var source_state: [2]javascript.Value = .{ .undefined, .null_value };
            var method: []const u8 = "GET";
            var target: navigation.Url = undefined;
            var headers_value = try web_fetch.Headers.init("");
            var body_bytes: ?[]const u8 = null;
            var mode: []const u8 = "cors";
            var credentials: []const u8 = "same-origin";
            var cache: []const u8 = "default";
            var redirect: []const u8 = "follow";
            var referrer: []const u8 = "about:client";
            var referrer_policy: []const u8 = "";
            var integrity: []const u8 = "";
            var keepalive = false;
            var signal: javascript.Value = .undefined;
            if (source_is_request) {
                source_state = try self.requestState(runtime, input);
                const flags = try self.bodyFlags(runtime, source_state[1]);
                if ((flags & 3) != 0) return error.TypeError;
                const record = source_state[0];
                method = runtime.valueString(try self.requestField(runtime, record, .method));
                target = try navigation.parse(runtime.valueString(try self.requestField(runtime, record, .url)));
                headers_value = try self.headersFromInit(runtime, try self.requestField(runtime, record, .headers));
                if (source_state[1] != .null_value) body_bytes = try self.bodyBytes(runtime, source_state[1]);
                mode = runtime.valueString(try self.requestField(runtime, record, .mode));
                credentials = runtime.valueString(try self.requestField(runtime, record, .credentials));
                cache = runtime.valueString(try self.requestField(runtime, record, .cache));
                redirect = runtime.valueString(try self.requestField(runtime, record, .redirect));
                referrer = runtime.valueString(try self.requestField(runtime, record, .referrer));
                referrer_policy = runtime.valueString(try self.requestField(runtime, record, .referrer_policy));
                integrity = runtime.valueString(try self.requestField(runtime, record, .integrity));
                keepalive = runtime.valueBoolean(try self.requestField(runtime, record, .keepalive));
                signal = try self.requestField(runtime, record, .signal);
            } else {
                const input_text = try runtime.coerceUSVString(input);
                target = try self.resolveValueUrl(runtime, input_text);
            }
            const init = if (arguments.len > 1) arguments[1] else .undefined;
            var body_overridden = false;
            if (init != .undefined and init != .null_value) {
                const value_method = try runtime.get(init, "method");
                if (value_method != .undefined) method = (try httpMethod(try coercedText(runtime, value_method))).text();
                const value_headers = try runtime.get(init, "headers");
                if (value_headers != .undefined) headers_value = try self.headersFromInit(runtime, value_headers);
                const value_body = try runtime.get(init, "body");
                if (value_body != .undefined) {
                    body_overridden = true;
                    if (value_body == .null_value) {
                        body_bytes = null;
                    } else {
                        body_bytes = runtime.copyBufferSource(value_body, self.encoding_input[0..]) catch |err| switch (err) {
                            error.TypeError => runtime.valueString(try runtime.coerceUSVString(value_body)),
                            else => return err,
                        };
                        if (!(try headers_value.has("content-type"))) try headers_value.append("content-type", "text/plain;charset=UTF-8");
                    }
                }
                const value_mode = try runtime.get(init, "mode");
                if (value_mode != .undefined) mode = try requestModeText(try coercedText(runtime, value_mode));
                const value_credentials = try runtime.get(init, "credentials");
                if (value_credentials != .undefined) credentials = try credentialsModeText(try coercedText(runtime, value_credentials));
                const value_cache = try runtime.get(init, "cache");
                if (value_cache != .undefined) cache = try requestCacheText(try coercedText(runtime, value_cache));
                const value_redirect = try runtime.get(init, "redirect");
                if (value_redirect != .undefined) redirect = try requestRedirectText(try coercedText(runtime, value_redirect));
                const value_referrer = try runtime.get(init, "referrer");
                if (value_referrer != .undefined) referrer = try coercedText(runtime, value_referrer);
                const value_referrer_policy = try runtime.get(init, "referrerPolicy");
                if (value_referrer_policy != .undefined) referrer_policy = try requestReferrerPolicyText(try coercedText(runtime, value_referrer_policy));
                const value_integrity = try runtime.get(init, "integrity");
                if (value_integrity != .undefined) integrity = try coercedText(runtime, value_integrity);
                const value_keepalive = try runtime.get(init, "keepalive");
                if (value_keepalive != .undefined) keepalive = runtime.valueBoolean(value_keepalive);
                const value_signal = try runtime.get(init, "signal");
                if (value_signal != .undefined and value_signal != .null_value) {
                    if ((runtime.hostTag(value_signal) catch 0) != host_object_abort_signal) return error.TypeError;
                    signal = value_signal;
                }
            }
            const parsed_method = try httpMethod(method);
            if ((parsed_method == .get or parsed_method == .head) and body_bytes != null) return error.TypeError;
            try validateRequestHeaders(&headers_value);
            if (equal(mode, "no-cors")) {
                if (parsed_method != .get and parsed_method != .head and parsed_method != .post) return error.TypeError;
                try validateNoCorsHeaders(&headers_value);
            }
            if (equal(cache, "only-if-cached") and !equal(mode, "same-origin")) return error.TypeError;
            if (keepalive and body_bytes != null and body_bytes.?.len > 64 * 1024) return error.TypeError;
            var normalized_referrer: navigation.Url = undefined;
            if (referrer.len > 0 and !equal(referrer, "about:client")) {
                normalized_referrer = if (navigation.isDocumentRelativeReference(referrer)) try navigation.resolve(&self.document_url, referrer) else try navigation.parse(referrer);
                const referrer_origin = security.Origin.parse(normalized_referrer.bytes(), self.generation) catch return error.TypeError;
                if (!self.security_context.document_origin.same(&referrer_origin)) return error.TypeError;
                referrer = normalized_referrer.bytes();
            }
            if (signal == .undefined) signal = try self.makeAbortSignal(false, .undefined);
            try runtime.hostRoot(signal);
            var serialized: [web_fetch.max_serialized_bytes]u8 = undefined;
            const request = try self.makeRequestObject(body_bytes, parsed_method.text(), target.bytes(), try self.makeHeaders(try headers_value.serialize(serialized[0..])), mode, credentials, cache, redirect, referrer, referrer_policy, integrity, keepalive, signal);
            if (source_is_request and !body_overridden and source_state[1] != .null_value) try self.setBodyFlags(runtime, source_state[1], (try self.bodyFlags(runtime, source_state[1])) | 1);
            return request;
        },
        .request_clone => {
            const state = try self.requestState(runtime, receiver);
            const flags = try self.bodyFlags(runtime, state[1]);
            if ((flags & 3) != 0) return error.TypeError;
            const record = state[0];
            const headers_value = try self.headersFromInit(runtime, try self.requestField(runtime, record, .headers));
            var serialized: [web_fetch.max_serialized_bytes]u8 = undefined;
            return self.makeRequestObject(
                if (state[1] == .null_value) null else try self.bodyBytes(runtime, state[1]),
                runtime.valueString(try self.requestField(runtime, record, .method)),
                runtime.valueString(try self.requestField(runtime, record, .url)),
                try self.makeHeaders(try headers_value.serialize(serialized[0..])),
                runtime.valueString(try self.requestField(runtime, record, .mode)),
                runtime.valueString(try self.requestField(runtime, record, .credentials)),
                runtime.valueString(try self.requestField(runtime, record, .cache)),
                runtime.valueString(try self.requestField(runtime, record, .redirect)),
                runtime.valueString(try self.requestField(runtime, record, .referrer)),
                runtime.valueString(try self.requestField(runtime, record, .referrer_policy)),
                runtime.valueString(try self.requestField(runtime, record, .integrity)),
                runtime.valueBoolean(try self.requestField(runtime, record, .keepalive)),
                try self.requestField(runtime, record, .signal),
            );
        },
        .request_text, .request_json, .request_bytes, .request_array_buffer => {
            const state = try self.requestState(runtime, receiver);
            const flags = try self.bodyFlags(runtime, state[1]);
            const promise = try runtime.createPromise();
            if (try self.bodyAbortReason(runtime, state[1])) |reason| {
                try runtime.rejectPromise(promise, reason);
                return promise;
            }
            if ((flags & 3) != 0) {
                const program = runtime.activeProgram() orelse return error.TypeError;
                const constructor = runtime.global("TypeError") orelse return error.TypeError;
                const reason = try runtime.callValue(program, constructor, .undefined, &.{try runtime.makeString("Body has already been used or is locked")});
                try runtime.rejectPromise(promise, reason);
                return promise;
            }
            try self.setBodyFlags(runtime, state[1], flags | 1);
            const bytes = try self.bodyBytes(runtime, state[1]);
            const value = switch (operation) {
                .request_text => blk: {
                    var decoder = web_encoding.Decoder.init(.utf8, false, false);
                    break :blk try runtime.makeString(try decoder.decode(bytes, self.encoding_output[0..], false));
                },
                .request_bytes => try runtime.createUint8Array(bytes),
                .request_array_buffer => try runtime.createArrayBufferCopy(bytes),
                .request_json => blk: {
                    var decoder = web_encoding.Decoder.init(.utf8, false, false);
                    const text_value = try runtime.makeString(try decoder.decode(bytes, self.encoding_output[0..], false));
                    const program = runtime.activeProgram() orelse return error.TypeError;
                    const json = runtime.global("JSON") orelse return error.TypeError;
                    break :blk try runtime.callValue(program, try runtime.get(json, "parse"), json, &.{text_value});
                },
                else => unreachable,
            };
            try runtime.resolvePromise(promise, value);
            return promise;
        },
        .request_get_method, .request_get_url, .request_get_headers, .request_get_destination, .request_get_referrer, .request_get_referrer_policy, .request_get_mode, .request_get_credentials, .request_get_cache, .request_get_redirect, .request_get_integrity, .request_get_keepalive, .request_get_signal, .request_get_duplex => {
            const state = try self.requestState(runtime, receiver);
            return self.requestField(runtime, state[0], switch (operation) {
                .request_get_method => .method,
                .request_get_url => .url,
                .request_get_headers => .headers,
                .request_get_destination => .destination,
                .request_get_referrer => .referrer,
                .request_get_referrer_policy => .referrer_policy,
                .request_get_mode => .mode,
                .request_get_credentials => .credentials,
                .request_get_cache => .cache,
                .request_get_redirect => .redirect,
                .request_get_integrity => .integrity,
                .request_get_keepalive => .keepalive,
                .request_get_signal => .signal,
                .request_get_duplex => .duplex,
                else => unreachable,
            });
        },
        .request_get_body => return (try self.requestState(runtime, receiver))[1],
        .request_get_body_used => return .{ .boolean = (try self.bodyFlags(runtime, (try self.requestState(runtime, receiver))[1]) & 1) != 0 },
        .response_constructor => {
            if (!runtime.hostCallIsConstruct()) return error.TypeError;
            const body_value = if (arguments.len > 0) arguments[0] else .null_value;
            const init = if (arguments.len > 1) arguments[1] else .undefined;
            var status: u16 = 200;
            var status_text: []const u8 = "";
            var headers_value = try web_fetch.Headers.init("");
            if (init != .undefined and init != .null_value) {
                const status_number = try runtime.valueNumber(try runtime.get(init, "status"));
                if (!std.math.isNan(status_number) and status_number != 0) {
                    if (status_number < 200 or status_number > 599 or @trunc(status_number) != status_number) return error.RangeError;
                    status = @intFromFloat(status_number);
                }
                const status_text_value = try runtime.get(init, "statusText");
                if (status_text_value != .undefined) status_text = try coercedText(runtime, status_text_value);
                for (status_text) |byte| if (byte == '\r' or byte == '\n') return error.TypeError;
                headers_value = try self.headersFromInit(runtime, try runtime.get(init, "headers"));
            }
            var body_bytes: ?[]const u8 = null;
            if (body_value != .undefined and body_value != .null_value) {
                body_bytes = runtime.copyBufferSource(body_value, self.encoding_input[0..]) catch |err| switch (err) {
                    error.TypeError => runtime.valueString(try runtime.coerceUSVString(body_value)),
                    else => return err,
                };
                if (!(try headers_value.has("content-type"))) try headers_value.append("content-type", "text/plain;charset=UTF-8");
            }
            var serialized: [web_fetch.max_serialized_bytes]u8 = undefined;
            return self.makeResponseObject(body_bytes, status, status_text, try self.makeHeaders(try headers_value.serialize(serialized[0..])), "", false, "default", .undefined);
        },
        .response_error => return self.makeResponseObject(null, 0, "", try self.makeHeaders(""), "", false, "error", .undefined),
        .response_redirect => {
            if (arguments.len == 0) return error.TypeError;
            const target = try self.resolveValueUrl(runtime, arguments[0]);
            const status_number = if (arguments.len > 1 and arguments[1] != .undefined) try runtime.valueNumber(arguments[1]) else 302;
            if (status_number != 301 and status_number != 302 and status_number != 303 and status_number != 307 and status_number != 308) return error.RangeError;
            var headers_value = try web_fetch.Headers.init("");
            try headers_value.append("location", target.bytes());
            var serialized: [web_fetch.max_serialized_bytes]u8 = undefined;
            return self.makeResponseObject(null, @intFromFloat(status_number), statusText(@intFromFloat(status_number)), try self.makeHeaders(try headers_value.serialize(serialized[0..])), "", false, "default", .undefined);
        },
        .response_json_static => {
            if (arguments.len == 0) return error.TypeError;
            const program = runtime.activeProgram() orelse return error.TypeError;
            const json = runtime.global("JSON") orelse return error.TypeError;
            const serialized_value = try runtime.callValue(program, try runtime.get(json, "stringify"), json, &.{arguments[0]});
            if (serialized_value != .string) return error.TypeError;
            var status: u16 = 200;
            var status_text: []const u8 = "";
            var headers_value = try web_fetch.Headers.init("");
            if (arguments.len > 1 and arguments[1] != .undefined and arguments[1] != .null_value) {
                const status_number = try runtime.valueNumber(try runtime.get(arguments[1], "status"));
                if (!std.math.isNan(status_number) and status_number != 0) {
                    if (status_number < 200 or status_number > 599 or @trunc(status_number) != status_number) return error.RangeError;
                    status = @intFromFloat(status_number);
                }
                const text_value = try runtime.get(arguments[1], "statusText");
                if (text_value != .undefined) status_text = try coercedText(runtime, text_value);
                for (status_text) |byte| if (byte == '\r' or byte == '\n') return error.TypeError;
                headers_value = try self.headersFromInit(runtime, try runtime.get(arguments[1], "headers"));
            }
            if (!(try headers_value.has("content-type"))) try headers_value.append("content-type", "application/json");
            var serialized_headers: [web_fetch.max_serialized_bytes]u8 = undefined;
            return self.makeResponseObject(runtime.valueString(serialized_value), status, status_text, try self.makeHeaders(try headers_value.serialize(serialized_headers[0..])), "", false, "default", .undefined);
        },
        .response_clone => {
            const state = try self.responseState(runtime, receiver);
            const flags = try self.bodyFlags(runtime, state[1]);
            if ((flags & 3) != 0) return error.TypeError;
            const headers_object = try runtime.get(state[0], "headers");
            const headers_value = try self.headers(runtime, headers_object);
            var serialized: [web_fetch.max_serialized_bytes]u8 = undefined;
            const body_bytes: ?[]const u8 = if (state[1] == .null_value) null else try self.bodyBytes(runtime, state[1]);
            return self.makeResponseObject(
                body_bytes,
                @intFromFloat(try runtime.valueNumber(try runtime.get(state[0], "status"))),
                runtime.valueString(try runtime.get(state[0], "statusText")),
                try self.makeHeaders(try headers_value.serialize(serialized[0..])),
                runtime.valueString(try runtime.get(state[0], "url")),
                runtime.valueBoolean(try runtime.get(state[0], "redirected")),
                runtime.valueString(try runtime.get(state[0], "type")),
                try self.bodySignal(runtime, state[1]),
            );
        },
        .response_text, .response_json, .response_bytes, .response_array_buffer => {
            const state = try self.responseState(runtime, receiver);
            const flags = try self.bodyFlags(runtime, state[1]);
            const promise = try runtime.createPromise();
            if (try self.bodyAbortReason(runtime, state[1])) |reason| {
                try runtime.rejectPromise(promise, reason);
                return promise;
            }
            if ((flags & 3) != 0) {
                const program = runtime.activeProgram() orelse return error.TypeError;
                const constructor = runtime.global("TypeError") orelse return error.TypeError;
                const reason = try runtime.callValue(program, constructor, .undefined, &.{try runtime.makeString("Body has already been used or is locked")});
                try runtime.rejectPromise(promise, reason);
                return promise;
            }
            try self.setBodyFlags(runtime, state[1], flags | 1);
            const bytes = try self.bodyBytes(runtime, state[1]);
            const value = switch (operation) {
                .response_text => blk: {
                    var decoder = web_encoding.Decoder.init(.utf8, false, false);
                    break :blk try runtime.makeString(try decoder.decode(bytes, self.encoding_output[0..], false));
                },
                .response_bytes => try runtime.createUint8Array(bytes),
                .response_array_buffer => try runtime.createArrayBufferCopy(bytes),
                .response_json => blk: {
                    var decoder = web_encoding.Decoder.init(.utf8, false, false);
                    const text_value = try runtime.makeString(try decoder.decode(bytes, self.encoding_output[0..], false));
                    const program = runtime.activeProgram() orelse return error.TypeError;
                    const json = runtime.global("JSON") orelse return error.TypeError;
                    break :blk try runtime.callValue(program, try runtime.get(json, "parse"), json, &.{text_value});
                },
                else => unreachable,
            };
            try runtime.resolvePromise(promise, value);
            return promise;
        },
        .response_get_type,
        .response_get_url,
        .response_get_redirected,
        .response_get_status,
        .response_get_status_text,
        .response_get_headers,
        => {
            const state = try self.responseState(runtime, receiver);
            const name: []const u8 = switch (operation) {
                .response_get_type => "type",
                .response_get_url => "url",
                .response_get_redirected => "redirected",
                .response_get_status => "status",
                .response_get_status_text => "statusText",
                .response_get_headers => "headers",
                else => unreachable,
            };
            return runtime.get(state[0], name);
        },
        .response_get_ok => {
            const state = try self.responseState(runtime, receiver);
            const status = try runtime.valueNumber(try runtime.get(state[0], "status"));
            return .{ .boolean = status >= 200 and status <= 299 };
        },
        .response_get_body => return (try self.responseState(runtime, receiver))[1],
        .response_get_body_used => {
            const state = try self.responseState(runtime, receiver);
            return .{ .boolean = (try self.bodyFlags(runtime, state[1]) & 1) != 0 };
        },
        .stream_get_reader => {
            const flags = try self.bodyFlags(runtime, receiver);
            if ((flags & 2) != 0) return error.TypeError;
            try self.setBodyFlags(runtime, receiver, flags | 2);
            const reader = try runtime.createObject();
            if (runtime.global("ReadableStreamDefaultReader")) |constructor| try runtime.setPrototype(reader, try runtime.get(constructor, "prototype"));
            try runtime.setHostPropertyHooks(reader, host_object_body_reader, self, null, null);
            try runtime.setHostState(reader, host_object_body_reader, receiver, .undefined);
            try self.bindWebMethod(reader, "read", .stream_read, 0);
            try self.bindWebMethod(reader, "cancel", .stream_cancel, 1);
            try self.bindWebMethod(reader, "releaseLock", .stream_release_lock, 0);
            return reader;
        },
        .stream_get_locked => return .{ .boolean = (try self.bodyFlags(runtime, receiver) & 2) != 0 },
        .stream_read => {
            const reader_state = try runtime.hostState(receiver, host_object_body_reader);
            const body = reader_state[0];
            if (try self.bodyAbortReason(runtime, body)) |reason| {
                const promise = try runtime.createPromise();
                try runtime.rejectPromise(promise, reason);
                return promise;
            }
            var flags = try self.bodyFlags(runtime, body);
            const offset: usize = @intCast(flags >> 3);
            const bytes = try self.bodyBytes(runtime, body);
            const result = try runtime.createObject();
            if ((flags & 4) != 0 or offset >= bytes.len) {
                try runtime.set(result, "done", .{ .boolean = true });
                try runtime.set(result, "value", .undefined);
            } else {
                const end = @min(bytes.len, offset + 1024);
                try runtime.set(result, "done", .{ .boolean = false });
                try runtime.set(result, "value", try runtime.createUint8Array(bytes[offset..end]));
                flags = (flags & 7) | (@as(u64, end) << 3) | 1;
                try self.setBodyFlags(runtime, body, flags);
            }
            const promise = try runtime.createPromise();
            try runtime.resolvePromise(promise, result);
            return promise;
        },
        .stream_cancel => {
            const tag = try runtime.hostTag(receiver);
            const body = if (tag == host_object_body_reader) (try runtime.hostState(receiver, host_object_body_reader))[0] else if (tag == host_object_body_stream) receiver else return error.TypeError;
            if (try self.bodyAbortReason(runtime, body)) |reason| {
                const promise = try runtime.createPromise();
                try runtime.rejectPromise(promise, reason);
                return promise;
            }
            const bytes = try self.bodyBytes(runtime, body);
            const flags = try self.bodyFlags(runtime, body);
            try self.setBodyFlags(runtime, body, (flags & 2) | 5 | (@as(u64, bytes.len) << 3));
            const promise = try runtime.createPromise();
            try runtime.resolvePromise(promise, .undefined);
            return promise;
        },
        .stream_release_lock => {
            const state = try runtime.hostState(receiver, host_object_body_reader);
            const flags = try self.bodyFlags(runtime, state[0]);
            try self.setBodyFlags(runtime, state[0], flags & ~@as(u64, 2));
            try runtime.setHostState(receiver, host_object_body_reader, .undefined, .undefined);
            return .undefined;
        },
        .xhr_constructor => {
            if (!runtime.hostCallIsConstruct()) return error.TypeError;
            for (&self.xhrs, 0..) |*xhr, index| {
                if (xhr.occupied) continue;
                const object = try runtime.createObject();
                xhr.* = .{ .occupied = true, .generation = self.generation, .object = object };
                try runtime.set(object, "_xhr", .{ .number = @floatFromInt(index) });
                try runtime.set(object, "_event_target", .{ .number = @floatFromInt(eventTargetToken(.{ .xhr = @intCast(index) })) });
                try runtime.set(object, "readyState", .{ .number = 0 });
                try runtime.set(object, "status", .{ .number = 0 });
                try runtime.set(object, "responseText", try runtime.makeString(""));
                try self.bind(object, "open", .xhr_open);
                try self.bind(object, "send", .xhr_send);
                try self.bind(object, "abort", .xhr_abort);
                try self.bind(object, "addEventListener", .add_event_listener);
                return object;
            }
            return error.XhrLimit;
        },
        .xhr_open => {
            const xhr = try xhrFor(self, runtime, receiver);
            const method = self.argumentString(arguments, 0);
            if (!std.ascii.eqlIgnoreCase(method, "GET")) return error.TypeError;
            xhr.method_len = method.len;
            @memcpy(xhr.method[0..method.len], method);
            xhr.url = try self.resolveArgumentUrl(arguments, 1);
            try runtime.set(receiver, "readyState", .{ .number = 1 });
            return .undefined;
        },
        .xhr_send => {
            const xhr = try xhrFor(self, runtime, receiver);
            _ = try self.queueRequest(xhr.url, .xhr, .undefined, receiver, .{ .mode = xhr.mode });
            try runtime.set(receiver, "readyState", .{ .number = 2 });
            return .undefined;
        },
        .xhr_abort => {
            for (&self.requests) |*request| {
                if (request.kind == .xhr and runtime.sameValue(request.xhr, receiver) and (request.state == .queued or request.state == .in_flight)) request.state = .aborted;
            }
            try runtime.set(receiver, "readyState", .{ .number = 0 });
            return .undefined;
        },
        .url_constructor => {
            if (!runtime.hostCallIsConstruct()) return error.TypeError;
            return self.makeUrlObject(try self.constructorUrl(arguments));
        },
        .url_can_parse => {
            _ = self.constructorUrl(arguments) catch return .{ .boolean = false };
            return .{ .boolean = true };
        },
        .url_parse => {
            const target = self.constructorUrl(arguments) catch return .null_value;
            return self.makeUrlObject(target);
        },
        .url_to_string => {
            const href = (try runtime.hostState(receiver, host_object_url))[0];
            if (href != .string) return error.TypeError;
            return href;
        },
        .url_search_params_constructor => {
            if (!runtime.hostCallIsConstruct()) return error.TypeError;
            const init = if (arguments.len > 0) arguments[0] else .undefined;
            const params = try self.searchParamsFromInit(runtime, init);
            var serialized: [web_url.max_query_bytes]u8 = undefined;
            return self.makeUrlSearchParams(try params.serialize(serialized[0..]), .undefined);
        },
        .url_search_params_append => {
            if (arguments.len < 2) return error.TypeError;
            var params = try self.urlSearchParams(runtime, receiver);
            try params.append(try coercedText(runtime, arguments[0]), try coercedText(runtime, arguments[1]));
            try self.updateUrlSearchParams(runtime, receiver, &params);
            return .undefined;
        },
        .url_search_params_delete => {
            if (arguments.len == 0) return error.TypeError;
            var params = try self.urlSearchParams(runtime, receiver);
            const value = if (arguments.len > 1 and arguments[1] != .undefined) try coercedText(runtime, arguments[1]) else null;
            params.delete(try coercedText(runtime, arguments[0]), value);
            try self.updateUrlSearchParams(runtime, receiver, &params);
            return .undefined;
        },
        .url_search_params_get => {
            if (arguments.len == 0) return error.TypeError;
            const params = try self.urlSearchParams(runtime, receiver);
            const value = params.get(try coercedText(runtime, arguments[0])) orelse return .null_value;
            return runtime.makeString(value);
        },
        .url_search_params_get_all => {
            if (arguments.len == 0) return error.TypeError;
            const params = try self.urlSearchParams(runtime, receiver);
            const name = try coercedText(runtime, arguments[0]);
            var values: [web_url.max_pairs]javascript.Value = undefined;
            var count: usize = 0;
            for (0..params.count) |index| {
                if (!equal(params.name(index), name)) continue;
                values[count] = try runtime.makeString(params.value(index));
                count += 1;
            }
            return runtime.createArray(values[0..count]);
        },
        .url_search_params_has => {
            if (arguments.len == 0) return error.TypeError;
            const params = try self.urlSearchParams(runtime, receiver);
            const value = if (arguments.len > 1 and arguments[1] != .undefined) try coercedText(runtime, arguments[1]) else null;
            return .{ .boolean = params.has(try coercedText(runtime, arguments[0]), value) };
        },
        .url_search_params_set => {
            if (arguments.len < 2) return error.TypeError;
            var params = try self.urlSearchParams(runtime, receiver);
            try params.set(try coercedText(runtime, arguments[0]), try coercedText(runtime, arguments[1]));
            try self.updateUrlSearchParams(runtime, receiver, &params);
            return .undefined;
        },
        .url_search_params_sort => {
            var params = try self.urlSearchParams(runtime, receiver);
            params.sort();
            try self.updateUrlSearchParams(runtime, receiver, &params);
            return .undefined;
        },
        .url_search_params_to_string => {
            const state = try runtime.hostState(receiver, host_object_url_search_params);
            if (state[0] != .string) return error.TypeError;
            return state[0];
        },
        .url_search_params_keys, .url_search_params_values, .url_search_params_entries => {
            _ = try self.urlSearchParams(runtime, receiver);
            return self.makeUrlSearchParamsIterator(receiver, operation);
        },
        .url_search_params_for_each => {
            if (arguments.len == 0) return error.TypeError;
            const program = runtime.activeProgram() orelse return error.TypeError;
            const this_arg = if (arguments.len > 1) arguments[1] else .undefined;
            var index: usize = 0;
            while (true) : (index += 1) {
                const params = try self.urlSearchParams(runtime, receiver);
                if (index >= params.count) break;
                const callback_arguments = [_]javascript.Value{ try runtime.makeString(params.value(index)), try runtime.makeString(params.name(index)), receiver };
                _ = try runtime.callValue(program, arguments[0], this_arg, callback_arguments[0..]);
            }
            return .undefined;
        },
        .url_search_params_iterator_next => {
            const tag = try runtime.hostTag(receiver);
            if (tag != host_object_url_search_params_keys and tag != host_object_url_search_params_values and tag != host_object_url_search_params_entries) return error.TypeError;
            const state = try runtime.hostState(receiver, tag);
            const params = try self.urlSearchParams(runtime, state[0]);
            const index_number = try runtime.valueNumber(state[1]);
            const index: usize = @intFromFloat(@max(0, index_number));
            const result = try runtime.createObject();
            if (index >= params.count) {
                try runtime.set(result, "value", .undefined);
                try runtime.set(result, "done", .{ .boolean = true });
                return result;
            }
            const value = if (tag == host_object_url_search_params_keys)
                try runtime.makeString(params.name(index))
            else if (tag == host_object_url_search_params_values)
                try runtime.makeString(params.value(index))
            else blk: {
                const pair = [_]javascript.Value{ try runtime.makeString(params.name(index)), try runtime.makeString(params.value(index)) };
                break :blk try runtime.createArray(pair[0..]);
            };
            try runtime.setHostState(receiver, tag, state[0], .{ .number = @floatFromInt(index + 1) });
            try runtime.set(result, "value", value);
            try runtime.set(result, "done", .{ .boolean = false });
            return result;
        },
        .url_get_href,
        .url_get_origin,
        .url_get_protocol,
        .url_get_username,
        .url_get_password,
        .url_get_host,
        .url_get_hostname,
        .url_get_port,
        .url_get_pathname,
        .url_get_search,
        .url_get_search_params,
        .url_get_hash,
        => return (try propertyGet(self, runtime, host_object_url, receiver, urlAccessorName(operation) orelse return error.TypeError)) orelse error.TypeError,
        .url_set_href,
        .url_set_protocol,
        .url_set_username,
        .url_set_password,
        .url_set_host,
        .url_set_hostname,
        .url_set_port,
        .url_set_pathname,
        .url_set_search,
        .url_set_hash,
        => {
            if (arguments.len == 0) return error.TypeError;
            if (!try propertySet(self, runtime, host_object_url, receiver, urlAccessorName(operation) orelse return error.TypeError, arguments[0])) return error.TypeError;
            return .undefined;
        },
        .url_search_params_get_size => return (try propertyGet(self, runtime, host_object_url_search_params, receiver, "size")) orelse error.TypeError,
        .text_encoder_constructor => {
            if (!runtime.hostCallIsConstruct()) return error.TypeError;
            return self.makeTextEncoder();
        },
        .text_encoder_get_encoding => {
            if (try runtime.hostTag(receiver) != host_object_text_encoder) return error.TypeError;
            return runtime.makeString("utf-8");
        },
        .text_encoder_encode => {
            if (try runtime.hostTag(receiver) != host_object_text_encoder) return error.TypeError;
            const source = if (arguments.len == 0 or arguments[0] == .undefined)
                ""
            else
                runtime.valueString(try runtime.coerceUSVString(arguments[0]));
            return runtime.createUint8Array(source);
        },
        .text_encoder_encode_into => {
            if (try runtime.hostTag(receiver) != host_object_text_encoder or arguments.len < 2) return error.TypeError;
            const source = runtime.valueString(try runtime.coerceUSVString(arguments[0]));
            const destination = try runtime.uint8ArrayBytes(arguments[1]);
            const result = web_encoding.encodeInto(source, destination);
            const object = try runtime.createObject();
            try runtime.set(object, "read", .{ .number = @floatFromInt(result.read) });
            try runtime.set(object, "written", .{ .number = @floatFromInt(result.written) });
            return object;
        },
        .text_decoder_constructor => {
            if (!runtime.hostCallIsConstruct()) return error.TypeError;
            const label = if (arguments.len == 0 or arguments[0] == .undefined)
                "utf-8"
            else
                runtime.valueString(try runtime.coerceString(arguments[0]));
            const encoding = try web_encoding.parseLabel(label);
            var fatal = false;
            var ignore_bom = false;
            if (arguments.len > 1 and arguments[1] != .undefined and arguments[1] != .null_value) {
                fatal = runtime.valueBoolean(try runtime.get(arguments[1], "fatal"));
                ignore_bom = runtime.valueBoolean(try runtime.get(arguments[1], "ignoreBOM"));
            }
            return self.makeTextDecoder(encoding, fatal, ignore_bom);
        },
        .text_decoder_get_encoding => return runtime.makeString((try self.textDecoder(runtime, receiver)).encoding.name()),
        .text_decoder_get_fatal => return .{ .boolean = (try self.textDecoder(runtime, receiver)).fatal },
        .text_decoder_get_ignore_bom => return .{ .boolean = (try self.textDecoder(runtime, receiver)).ignore_bom },
        .text_decoder_decode => {
            var decoder = try self.textDecoder(runtime, receiver);
            const input = if (arguments.len == 0 or arguments[0] == .undefined)
                self.encoding_input[0..0]
            else
                try runtime.copyBufferSource(arguments[0], self.encoding_input[0..]);
            var stream = false;
            if (arguments.len > 1 and arguments[1] != .undefined and arguments[1] != .null_value)
                stream = runtime.valueBoolean(try runtime.get(arguments[1], "stream"));
            const decoded = decoder.decode(input, self.encoding_output[0..], stream) catch |err| {
                try self.storeTextDecoder(runtime, receiver, &decoder);
                return err;
            };
            try self.storeTextDecoder(runtime, receiver, &decoder);
            return runtime.makeString(decoded);
        },
        .headers_constructor => {
            if (!runtime.hostCallIsConstruct()) return error.TypeError;
            const headers_value = try self.headersFromInit(runtime, if (arguments.len > 0) arguments[0] else .undefined);
            var serialized: [web_fetch.max_serialized_bytes]u8 = undefined;
            return self.makeHeaders(try headers_value.serialize(serialized[0..]));
        },
        .headers_append => {
            if (arguments.len < 2) return error.TypeError;
            var headers_value = try self.headers(runtime, receiver);
            try headers_value.append(try coercedText(runtime, arguments[0]), try coercedText(runtime, arguments[1]));
            try self.storeHeaders(runtime, receiver, &headers_value);
            return .undefined;
        },
        .headers_delete => {
            if (arguments.len == 0) return error.TypeError;
            var headers_value = try self.headers(runtime, receiver);
            try headers_value.delete(try coercedText(runtime, arguments[0]));
            try self.storeHeaders(runtime, receiver, &headers_value);
            return .undefined;
        },
        .headers_get => {
            if (arguments.len == 0) return error.TypeError;
            const headers_value = try self.headers(runtime, receiver);
            var value_buffer: [web_fetch.max_serialized_bytes]u8 = undefined;
            const value = try headers_value.get(try coercedText(runtime, arguments[0]), value_buffer[0..]) orelse return .null_value;
            return runtime.makeString(value);
        },
        .headers_get_set_cookie => {
            const headers_value = try self.headers(runtime, receiver);
            var cookies: [web_fetch.max_headers][]const u8 = undefined;
            const count = headers_value.getSetCookie(&cookies);
            var values: [web_fetch.max_headers]javascript.Value = undefined;
            for (0..count) |index| values[index] = try runtime.makeString(cookies[index]);
            return runtime.createArray(values[0..count]);
        },
        .headers_has => {
            if (arguments.len == 0) return error.TypeError;
            const headers_value = try self.headers(runtime, receiver);
            return .{ .boolean = try headers_value.has(try coercedText(runtime, arguments[0])) };
        },
        .headers_set => {
            if (arguments.len < 2) return error.TypeError;
            var headers_value = try self.headers(runtime, receiver);
            try headers_value.set(try coercedText(runtime, arguments[0]), try coercedText(runtime, arguments[1]));
            try self.storeHeaders(runtime, receiver, &headers_value);
            return .undefined;
        },
        .headers_for_each => {
            _ = try self.headers(runtime, receiver);
            if (arguments.len == 0) return error.TypeError;
            const program = runtime.activeProgram() orelse return error.TypeError;
            const this_arg = if (arguments.len > 1) arguments[1] else .undefined;
            var ordinal: usize = 0;
            while (true) : (ordinal += 1) {
                const headers_value = try self.headers(runtime, receiver);
                const entry_index = headerUniqueIndex(&headers_value, ordinal) orelse break;
                var value_buffer: [web_fetch.max_serialized_bytes]u8 = undefined;
                const name = headers_value.name(entry_index);
                const callback_arguments = [_]javascript.Value{
                    try runtime.makeString((try headers_value.get(name, value_buffer[0..])).?),
                    try runtime.makeString(name),
                    receiver,
                };
                _ = try runtime.callValue(program, arguments[0], this_arg, callback_arguments[0..]);
            }
            return .undefined;
        },
        .headers_keys, .headers_values, .headers_entries => {
            _ = try self.headers(runtime, receiver);
            return self.makeHeadersIterator(receiver, operation);
        },
        .headers_iterator_next => {
            const tag = try runtime.hostTag(receiver);
            if (tag != host_object_headers_keys and tag != host_object_headers_values and tag != host_object_headers_entries) return error.TypeError;
            const state = try runtime.hostState(receiver, tag);
            const headers_value = try self.headers(runtime, state[0]);
            const ordinal: usize = @intFromFloat(@max(0, try runtime.valueNumber(state[1])));
            const result = try runtime.createObject();
            const entry_index = headerUniqueIndex(&headers_value, ordinal) orelse {
                try runtime.set(result, "value", .undefined);
                try runtime.set(result, "done", .{ .boolean = true });
                return result;
            };
            const name = headers_value.name(entry_index);
            var value_buffer: [web_fetch.max_serialized_bytes]u8 = undefined;
            const combined = (try headers_value.get(name, value_buffer[0..])).?;
            const value = if (tag == host_object_headers_keys)
                try runtime.makeString(name)
            else if (tag == host_object_headers_values)
                try runtime.makeString(combined)
            else blk: {
                const pair = [_]javascript.Value{ try runtime.makeString(name), try runtime.makeString(combined) };
                break :blk try runtime.createArray(pair[0..]);
            };
            try runtime.setHostState(receiver, tag, state[0], .{ .number = @floatFromInt(ordinal + 1) });
            try runtime.set(result, "value", value);
            try runtime.set(result, "done", .{ .boolean = false });
            return result;
        },
        .count_queuing_strategy_constructor, .byte_length_queuing_strategy_constructor => {
            if (!runtime.hostCallIsConstruct() or arguments.len == 0 or arguments[0] == .undefined or arguments[0] == .null_value) return error.TypeError;
            const high_water_mark_value = try runtime.get(arguments[0], "highWaterMark");
            if (high_water_mark_value == .undefined) return error.TypeError;
            const high_water_mark = try runtime.valueNumber(high_water_mark_value);
            if (std.math.isNan(high_water_mark) or high_water_mark < 0) return error.RangeError;
            const tag: u16 = if (operation == .count_queuing_strategy_constructor) host_object_count_queuing_strategy else host_object_byte_length_queuing_strategy;
            const object = try runtime.createObject();
            const constructor_name = if (operation == .count_queuing_strategy_constructor) "CountQueuingStrategy" else "ByteLengthQueuingStrategy";
            if (runtime.global(constructor_name)) |constructor| try runtime.setPrototype(object, try runtime.get(constructor, "prototype"));
            try runtime.setHostPropertyHooks(object, tag, self, null, null);
            try runtime.setHostState(object, tag, .{ .number = high_water_mark }, .undefined);
            return object;
        },
        .queuing_strategy_get_high_water_mark => {
            const tag = try runtime.hostTag(receiver);
            if (tag != host_object_count_queuing_strategy and tag != host_object_byte_length_queuing_strategy) return error.TypeError;
            return (try runtime.hostState(receiver, tag))[0];
        },
        .count_queuing_strategy_get_size, .byte_length_queuing_strategy_get_size => {
            const expected_tag: u16 = if (operation == .count_queuing_strategy_get_size) host_object_count_queuing_strategy else host_object_byte_length_queuing_strategy;
            if ((runtime.hostTag(receiver) catch 0) != expected_tag) return error.TypeError;
            const size_operation: HostOp = if (operation == .count_queuing_strategy_get_size) .count_queuing_strategy_size else .byte_length_queuing_strategy_size;
            const function = try self.host(size_operation);
            try runtime.setFunctionMetadata(function, "size", 1);
            return function;
        },
        .count_queuing_strategy_size => return .{ .number = 1 },
        .byte_length_queuing_strategy_size => {
            if (arguments.len == 0 or arguments[0] == .undefined or arguments[0] == .null_value) return .{ .number = std.math.nan(f64) };
            const length = runtime.get(arguments[0], "byteLength") catch .undefined;
            return .{ .number = if (length == .undefined) std.math.nan(f64) else try runtime.valueNumber(length) };
        },
        .feature_supported => {
            const name = self.argumentString(arguments, 0);
            return .{ .boolean = equal(name, "fetch") or equal(name, "xhr") or equal(name, "promises") or equal(name, "dom") or equal(name, "storage") or equal(name, "cors") or equal(name, "csp") or equal(name, "encoding") or
                ((equal(name, "crypto") or equal(name, "webcrypto")) and web_crypto.secureEntropyAvailable()) };
        },
        .navigator_send_beacon => {
            if (arguments.len == 0) return .{ .boolean = false };
            const url = self.resolveArgumentUrl(arguments, 0) catch return .{ .boolean = false };
            _ = self.queueRequest(url, .fetch, .undefined, .undefined, .{ .mode = .no_cors, .credentials = .include }) catch return .{ .boolean = false };
            return .{ .boolean = true };
        },
        .crypto_get_random_values => {
            if (arguments.len == 0) return error.TypeError;
            const bytes = try runtime.writableIntegerTypedArrayBytes(arguments[0]);
            if (bytes.len > web_crypto.max_random_bytes) return error.RangeError;
            if (!web_crypto.fillSecureRandom(bytes)) return error.SecurityBlocked;
            return arguments[0];
        },
        .crypto_random_uuid => {
            var bytes: [16]u8 = undefined;
            if (!web_crypto.fillSecureRandom(bytes[0..])) return error.SecurityBlocked;
            bytes[6] = (bytes[6] & 0x0F) | 0x40;
            bytes[8] = (bytes[8] & 0x3F) | 0x80;
            var formatted: [36]u8 = undefined;
            formatUuid(&formatted, bytes);
            return runtime.makeString(formatted[0..]);
        },
        .subtle_digest => {
            const promise = try runtime.createPromise();
            const algorithm = cryptoAlgorithm(runtime, if (arguments.len > 0) arguments[0] else .undefined) catch {
                try runtime.rejectPromise(promise, try self.makeTypeError(runtime, "Unsupported digest algorithm"));
                return promise;
            };
            const input = runtime.copyBufferSource(if (arguments.len > 1) arguments[1] else .undefined, self.encoding_input[0..]) catch {
                try runtime.rejectPromise(promise, try self.makeTypeError(runtime, "Digest requires BufferSource input"));
                return promise;
            };
            var digest_bytes: [32]u8 = undefined;
            const digest = web_crypto.digest(algorithm, input, digest_bytes[0..]) catch {
                try runtime.rejectPromise(promise, try self.makeTypeError(runtime, "Unsupported digest algorithm"));
                return promise;
            };
            try runtime.resolvePromise(promise, try runtime.createArrayBufferCopy(digest));
            return promise;
        },
        .canvas_get_context => {
            const kind = try coercedText(runtime, if (arguments.len > 0) arguments[0] else .undefined);
            if (!equal(kind, "2d")) return .null_value;
            return self.makeCanvasContext(try self.receiverNode(receiver));
        },
        .canvas_fill_rect, .canvas_clear_rect => {
            if (arguments.len < 4) return error.TypeError;
            const surface = try self.receiverCanvas(runtime, receiver);
            const x = try runtime.valueNumber(arguments[0]);
            const y = try runtime.valueNumber(arguments[1]);
            const width = try runtime.valueNumber(arguments[2]);
            const height = try runtime.valueNumber(arguments[3]);
            if (operation == .canvas_fill_rect) self.canvases.fillRect(surface, x, y, width, height) else self.canvases.clearRect(surface, x, y, width, height);
            return .undefined;
        },
        .canvas_begin_path => {
            self.canvases.beginPath(try self.receiverCanvas(runtime, receiver));
            return .undefined;
        },
        .canvas_move_to, .canvas_line_to => {
            if (arguments.len < 2) return error.TypeError;
            const surface = try self.receiverCanvas(runtime, receiver);
            const x = try runtime.valueNumber(arguments[0]);
            const y = try runtime.valueNumber(arguments[1]);
            if (operation == .canvas_move_to) self.canvases.moveTo(surface, x, y) else self.canvases.lineTo(surface, x, y);
            return .undefined;
        },
        .canvas_stroke => {
            self.canvases.stroke(try self.receiverCanvas(runtime, receiver));
            return .undefined;
        },
        .canvas_fill_text => {
            if (arguments.len < 3) return error.TypeError;
            const surface = try self.receiverCanvas(runtime, receiver);
            self.canvases.fillText(surface, try coercedText(runtime, arguments[0]), try runtime.valueNumber(arguments[1]), try runtime.valueNumber(arguments[2]));
            return .undefined;
        },
        .canvas_translate, .canvas_scale => {
            if (arguments.len < 2) return error.TypeError;
            const surface = try self.receiverCanvas(runtime, receiver);
            const x = try runtime.valueNumber(arguments[0]);
            const y = try runtime.valueNumber(arguments[1]);
            if (operation == .canvas_translate) self.canvases.translate(surface, x, y) else self.canvases.scale(surface, x, y);
            return .undefined;
        },
        .canvas_rotate => {
            if (arguments.len < 1) return error.TypeError;
            self.canvases.rotate(try self.receiverCanvas(runtime, receiver), try runtime.valueNumber(arguments[0]));
            return .undefined;
        },
        .canvas_save => {
            self.canvases.save(try self.receiverCanvas(runtime, receiver));
            return .undefined;
        },
        .canvas_restore => {
            self.canvases.restore(try self.receiverCanvas(runtime, receiver));
            return .undefined;
        },
        .canvas_set_transform => {
            if (arguments.len < 6) return error.TypeError;
            self.canvases.setTransform(try self.receiverCanvas(runtime, receiver), try runtime.valueNumber(arguments[0]), try runtime.valueNumber(arguments[1]), try runtime.valueNumber(arguments[2]), try runtime.valueNumber(arguments[3]), try runtime.valueNumber(arguments[4]), try runtime.valueNumber(arguments[5]));
            return .undefined;
        },
        .canvas_get_image_data => {
            if (arguments.len < 4) return error.TypeError;
            return self.canvasImageData(
                try self.receiverCanvas(runtime, receiver),
                @intFromFloat(try runtime.valueNumber(arguments[0])),
                @intFromFloat(try runtime.valueNumber(arguments[1])),
                @intFromFloat(try runtime.valueNumber(arguments[2])),
                @intFromFloat(try runtime.valueNumber(arguments[3])),
            );
        },
        .canvas_put_image_data => {
            if (arguments.len < 3) return error.TypeError;
            try self.putCanvasImageData(
                try self.receiverCanvas(runtime, receiver),
                arguments[0],
                @intFromFloat(try runtime.valueNumber(arguments[1])),
                @intFromFloat(try runtime.valueNumber(arguments[2])),
            );
            return .undefined;
        },
        .form_submit => {
            try self.enqueueAction(.form_submit, null, try self.receiverNode(receiver));
            return .undefined;
        },
        .event_prevent_default => {
            if (!runtime.valueBoolean(try runtime.get(receiver, "cancelable"))) return .undefined;
            const serial = try runtime.valueNumber(try runtime.get(receiver, "_event_serial"));
            if (serial > 0 and serial <= std.math.maxInt(u32)) self.cancelled_event_serial = @intFromFloat(serial);
            try runtime.set(receiver, "defaultPrevented", .{ .boolean = true });
            return .undefined;
        },
        .event_stop_propagation => {
            try runtime.set(receiver, "_event_stopped", .{ .boolean = true });
            return .undefined;
        },
        .event_stop_immediate_propagation => {
            try runtime.set(receiver, "_event_stopped", .{ .boolean = true });
            try runtime.set(receiver, "_event_immediate_stopped", .{ .boolean = true });
            return .undefined;
        },
    }
}

fn xhrFor(self: *WebRuntime, runtime: *javascript.Runtime, receiver: javascript.Value) Error!*Xhr {
    const index_number = try runtime.valueNumber(try runtime.get(receiver, "_xhr"));
    if (index_number < 0 or index_number >= max_xhr) return error.TypeError;
    const index: usize = @intFromFloat(index_number);
    if (!self.xhrs[index].occupied or self.xhrs[index].generation != self.generation) return error.StaleGeneration;
    return &self.xhrs[index];
}

fn executableScript(document: *const html.Document, node: u16) bool {
    const script_type = document.attribute(node, "type") orelse "";
    return script_type.len == 0 or
        std.ascii.eqlIgnoreCase(script_type, "text/javascript") or
        std.ascii.eqlIgnoreCase(script_type, "application/javascript") or
        std.ascii.eqlIgnoreCase(script_type, "module");
}

fn cryptoAlgorithm(runtime: *javascript.Runtime, value: javascript.Value) Error![]const u8 {
    if (value == .string) return runtime.valueString(value);
    if (value == .undefined or value == .null_value) return error.TypeError;
    return coercedText(runtime, try runtime.get(value, "name"));
}

fn formatUuid(output: *[36]u8, bytes: [16]u8) void {
    const digits = "0123456789abcdef";
    var source: usize = 0;
    var destination: usize = 0;
    while (source < bytes.len) : (source += 1) {
        if (destination == 8 or destination == 13 or destination == 18 or destination == 23) {
            output[destination] = '-';
            destination += 1;
        }
        output[destination] = digits[bytes[source] >> 4];
        output[destination + 1] = digits[bytes[source] & 0x0F];
        destination += 2;
    }
}

fn canvasDimension(raw: ?[]const u8, fallback: u32) u32 {
    const text_value = raw orelse return fallback;
    const value = std.fmt.parseInt(u32, text_value, 10) catch return fallback;
    return if (value > 0 and value <= web_canvas.max_dimension) value else fallback;
}

fn canvasColor(runtime: *javascript.Runtime, value: javascript.Value) Error!u32 {
    const text_value = try coercedText(runtime, value);
    if (equal(text_value, "black")) return 0;
    if (equal(text_value, "white") or equal(text_value, "transparent")) return 0xFFFFFF;
    if (equal(text_value, "red")) return 0xFF0000;
    if (equal(text_value, "green")) return 0x008000;
    if (equal(text_value, "blue")) return 0x0000FF;
    if (text_value.len == 4 and text_value[0] == '#') {
        const r = std.fmt.charToDigit(text_value[1], 16) catch return error.TypeError;
        const g = std.fmt.charToDigit(text_value[2], 16) catch return error.TypeError;
        const b = std.fmt.charToDigit(text_value[3], 16) catch return error.TypeError;
        return (@as(u32, r) * 17 << 16) | (@as(u32, g) * 17 << 8) | (@as(u32, b) * 17);
    }
    if (text_value.len == 7 and text_value[0] == '#') return std.fmt.parseInt(u32, text_value[1..], 16) catch error.TypeError;
    return error.TypeError;
}

fn canvasColorString(color: u32) []const u8 {
    return switch (color) {
        0 => "#000000",
        0xFFFFFF => "#ffffff",
        0xFF0000 => "#ff0000",
        0x008000 => "#008000",
        0x0000FF => "#0000ff",
        else => "#000000",
    };
}

fn validModuleSpecifier(specifier: []const u8) bool {
    return std.mem.startsWith(u8, specifier, "./") or
        std.mem.startsWith(u8, specifier, "../") or
        std.mem.startsWith(u8, specifier, "/") or
        std.mem.startsWith(u8, specifier, "http://") or
        std.mem.startsWith(u8, specifier, "https://");
}

fn imageSelection(document: *const html.Document, node: u16, environment: Environment) ?web_images.Selection {
    if (node >= document.node_count or !std.ascii.eqlIgnoreCase(document.nodeName(node), "img")) return null;
    const context = web_images.Context{
        .viewport_width = @max(1, environment.viewport_width),
        .viewport_height = @max(1, environment.viewport_height),
        .device_pixel_ratio_milli = 1000,
    };
    const src = document.attribute(node, "src") orelse "";
    const srcset = document.attribute(node, "srcset") orelse "";
    const sizes = document.attribute(node, "sizes") orelse "";
    const parent = document.nodes[node].parent;
    if (parent == html.none or parent >= document.node_count or
        !std.ascii.eqlIgnoreCase(document.nodeName(parent), "picture"))
    {
        return web_images.selectImg(src, srcset, sizes, context);
    }

    var sources: [16]web_images.PictureSource = undefined;
    var source_count: usize = 0;
    var child = document.nodes[parent].first_child;
    while (child != html.none and child != node and source_count < sources.len) {
        if (document.nodes[child].kind == .element and std.ascii.eqlIgnoreCase(document.nodeName(child), "source")) {
            if (document.attribute(child, "srcset")) |source_srcset| {
                sources[source_count] = .{
                    .srcset = source_srcset,
                    .sizes = document.attribute(child, "sizes") orelse "",
                    .media = document.attribute(child, "media") orelse "",
                    .mime_type = document.attribute(child, "type") orelse "",
                };
                source_count += 1;
            }
        }
        child = document.nodes[child].next_sibling;
    }
    return web_images.selectPicture(sources[0..source_count], src, srcset, sizes, context);
}

fn isDataReference(reference: []const u8) bool {
    return reference.len >= 5 and std.ascii.eqlIgnoreCase(reference[0..5], "data:");
}

fn selectionHash(reference: []const u8) u64 {
    return std.hash.Wyhash.hash(0x5234494D47, reference);
}

fn effectiveDocumentBase(document: *const html.Document, fallback: *const navigation.Url) navigation.Url {
    var index: usize = 0;
    while (index < document.node_count) : (index += 1) {
        const node: u16 = @intCast(index);
        if (document.nodes[node].kind != .element or !std.ascii.eqlIgnoreCase(document.nodeName(node), "base")) continue;
        const href = document.attribute(node, "href") orelse return fallback.*;
        return navigation.resolve(fallback, href) catch fallback.*;
    }
    return fallback.*;
}

fn resourceTarget(
    document: *const html.Document,
    node: u16,
    kind: web_resources.Kind,
    base: *const navigation.Url,
    environment: Environment,
) Error!navigation.Url {
    const reference = switch (kind) {
        .script, .subdocument => document.attribute(node, "src") orelse return error.InvalidCharacter,
        .image => (imageSelection(document, node, environment) orelse return error.InvalidCharacter).url,
        .stylesheet => document.attribute(node, "href") orelse return error.InvalidCharacter,
        .font => return error.InvalidCharacter,
    };
    if (isDataReference(reference)) return error.InvalidCharacter;
    const document_base = effectiveDocumentBase(document, base);
    return navigation.resolve(&document_base, reference);
}

fn securityKind(kind: RequestKind) security.ResourceKind {
    return switch (kind) {
        .script => .script,
        .stylesheet => .style,
        .image => .image,
        .font => .font,
        .subdocument => .subdocument,
        .fetch, .xhr => .connect,
    };
}

fn urlPath(url: []const u8) []const u8 {
    const scheme = std.mem.indexOf(u8, url, "://") orelse return "/";
    const authority_start = scheme + 3;
    const path_start = std.mem.indexOfScalarPos(u8, url, authority_start, '/') orelse return "/";
    const end = std.mem.indexOfAnyPos(u8, url, path_start, "?#") orelse url.len;
    return url[path_start..end];
}

fn eventTargetToken(target: EventTarget) u32 {
    return switch (target) {
        .window => 1,
        .document => 2,
        .navigation => 3,
        .node => |node| 0x10000 + @as(u32, node),
        .xhr => |index| 0x20000 + @as(u32, index),
    };
}

fn blockText(reason: security.BlockReason) []const u8 {
    return switch (reason) {
        .stale_generation => "Stale document",
        .invalid_url => "Invalid URL",
        .mixed_content => "Mixed content blocked",
        .same_origin => "Same-origin policy blocked",
        .content_security_policy => "Content Security Policy blocked",
        .cors => "CORS blocked",
        .insecure_context => "Secure context required",
        .none => "Request blocked",
    };
}

fn statusText(status: u16) []const u8 {
    return switch (status) {
        200 => "OK",
        201 => "Created",
        204 => "No Content",
        301 => "Moved Permanently",
        302 => "Found",
        303 => "See Other",
        304 => "Not Modified",
        307 => "Temporary Redirect",
        308 => "Permanent Redirect",
        400 => "Bad Request",
        401 => "Unauthorized",
        403 => "Forbidden",
        404 => "Not Found",
        500 => "Internal Server Error",
        502 => "Bad Gateway",
        503 => "Service Unavailable",
        else => "",
    };
}

fn httpMethod(raw: []const u8) Error!http.Method {
    if (std.ascii.eqlIgnoreCase(raw, "GET")) return .get;
    if (std.ascii.eqlIgnoreCase(raw, "POST")) return .post;
    if (std.ascii.eqlIgnoreCase(raw, "HEAD")) return .head;
    if (std.ascii.eqlIgnoreCase(raw, "PUT")) return .put;
    if (std.ascii.eqlIgnoreCase(raw, "DELETE")) return .delete;
    if (std.ascii.eqlIgnoreCase(raw, "PATCH")) return .patch;
    if (std.ascii.eqlIgnoreCase(raw, "OPTIONS")) return .options;
    return error.TypeError;
}

fn requestModeText(raw: []const u8) Error![]const u8 {
    if (equal(raw, "same-origin") or equal(raw, "cors") or equal(raw, "no-cors")) return raw;
    return error.TypeError;
}

fn credentialsModeText(raw: []const u8) Error![]const u8 {
    if (equal(raw, "omit") or equal(raw, "same-origin") or equal(raw, "include")) return raw;
    return error.TypeError;
}

fn securityRequestMode(raw: []const u8) Error!security.RequestMode {
    if (equal(raw, "same-origin")) return .same_origin;
    if (equal(raw, "cors")) return .cors;
    if (equal(raw, "no-cors")) return .no_cors;
    if (equal(raw, "navigate")) return .navigate;
    return error.TypeError;
}

fn securityCredentialsMode(raw: []const u8) Error!security.CredentialsMode {
    if (equal(raw, "omit")) return .omit;
    if (equal(raw, "same-origin")) return .same_origin;
    if (equal(raw, "include")) return .include;
    return error.TypeError;
}

fn requestCacheText(raw: []const u8) Error![]const u8 {
    if (equal(raw, "default") or equal(raw, "no-store") or equal(raw, "reload") or equal(raw, "no-cache") or equal(raw, "force-cache") or equal(raw, "only-if-cached")) return raw;
    return error.TypeError;
}

fn requestRedirectText(raw: []const u8) Error![]const u8 {
    if (equal(raw, "follow") or equal(raw, "error") or equal(raw, "manual")) return raw;
    return error.TypeError;
}

fn fetchRedirectMode(raw: []const u8) Error!FetchRedirectMode {
    if (equal(raw, "follow")) return .follow;
    if (equal(raw, "error")) return .error_mode;
    if (equal(raw, "manual")) return .manual;
    return error.TypeError;
}

fn requestReferrerPolicyText(raw: []const u8) Error![]const u8 {
    if (raw.len == 0 or equal(raw, "no-referrer") or equal(raw, "no-referrer-when-downgrade") or equal(raw, "origin") or equal(raw, "origin-when-cross-origin") or equal(raw, "same-origin") or equal(raw, "strict-origin") or equal(raw, "strict-origin-when-cross-origin") or equal(raw, "unsafe-url")) return raw;
    return error.TypeError;
}

fn validateRequestHeaders(headers: *const web_fetch.Headers) Error!void {
    for (0..headers.count) |index| {
        const name = headers.name(index);
        if (equal(name, "accept-charset") or equal(name, "accept-encoding") or equal(name, "access-control-request-headers") or equal(name, "access-control-request-method") or equal(name, "connection") or equal(name, "content-length") or equal(name, "cookie") or equal(name, "cookie2") or equal(name, "date") or equal(name, "dnt") or equal(name, "expect") or equal(name, "host") or equal(name, "keep-alive") or equal(name, "origin") or equal(name, "permissions-policy") or equal(name, "referer") or equal(name, "set-cookie") or equal(name, "te") or equal(name, "trailer") or equal(name, "transfer-encoding") or equal(name, "upgrade") or equal(name, "user-agent") or equal(name, "via") or std.mem.startsWith(u8, name, "proxy-") or std.mem.startsWith(u8, name, "sec-")) return error.TypeError;
    }
}

fn validateNoCorsHeaders(headers: *const web_fetch.Headers) Error!void {
    for (0..headers.count) |index| {
        const name = headers.name(index);
        if (equal(name, "accept") or equal(name, "accept-language") or equal(name, "content-language")) continue;
        if (equal(name, "content-type")) {
            const value = headers.value(index);
            const semicolon = std.mem.indexOfScalar(u8, value, ';') orelse value.len;
            const essence = std.mem.trim(u8, value[0..semicolon], " \t");
            if (std.ascii.eqlIgnoreCase(essence, "application/x-www-form-urlencoded") or std.ascii.eqlIgnoreCase(essence, "multipart/form-data") or std.ascii.eqlIgnoreCase(essence, "text/plain")) continue;
        }
        return error.TypeError;
    }
}

fn corsResponseHeaderVisible(request: *const PendingRequest, name: []const u8) bool {
    if (std.ascii.eqlIgnoreCase(name, "cache-control") or
        std.ascii.eqlIgnoreCase(name, "content-language") or
        std.ascii.eqlIgnoreCase(name, "content-length") or
        std.ascii.eqlIgnoreCase(name, "content-type") or
        std.ascii.eqlIgnoreCase(name, "expires") or
        std.ascii.eqlIgnoreCase(name, "last-modified") or
        std.ascii.eqlIgnoreCase(name, "pragma")) return true;
    var lines = std.mem.splitSequence(u8, request.response_headers[0..request.response_headers_len], "\r\n");
    while (lines.next()) |line| {
        const colon = std.mem.indexOfScalar(u8, line, ':') orelse continue;
        const header_name = std.mem.trim(u8, line[0..colon], " \t");
        if (!std.ascii.eqlIgnoreCase(header_name, "access-control-expose-headers")) continue;
        var exposed = std.mem.splitScalar(u8, line[colon + 1 ..], ',');
        while (exposed.next()) |raw_exposed| {
            const exposed_name = std.mem.trim(u8, raw_exposed, " \t");
            if (std.mem.eql(u8, exposed_name, "*") and request.credentials != .include) return true;
            if (std.ascii.eqlIgnoreCase(exposed_name, name)) return true;
        }
    }
    return false;
}

fn valueText(runtime: *javascript.Runtime, value: javascript.Value) Error![]const u8 {
    if (value != .string) return error.TypeError;
    return runtime.valueString(value);
}

fn coercedText(runtime: *javascript.Runtime, value: javascript.Value) Error![]const u8 {
    return runtime.valueString(try runtime.coerceUSVString(value));
}

fn urlAccessorName(operation: HostOp) ?[]const u8 {
    return switch (operation) {
        .url_get_href, .url_set_href => "href",
        .url_get_origin => "origin",
        .url_get_protocol, .url_set_protocol => "protocol",
        .url_get_username, .url_set_username => "username",
        .url_get_password, .url_set_password => "password",
        .url_get_host, .url_set_host => "host",
        .url_get_hostname, .url_set_hostname => "hostname",
        .url_get_port, .url_set_port => "port",
        .url_get_pathname, .url_set_pathname => "pathname",
        .url_get_search, .url_set_search => "search",
        .url_get_search_params => "searchParams",
        .url_get_hash, .url_set_hash => "hash",
        else => null,
    };
}

fn headerUniqueIndex(headers_value: *const web_fetch.Headers, wanted: usize) ?usize {
    var indices: [web_fetch.max_headers]usize = undefined;
    const ordered = headers_value.ordered(&indices);
    var unique: usize = 0;
    var previous: ?[]const u8 = null;
    for (ordered) |index| {
        const name = headers_value.name(index);
        if (previous) |last| if (std.mem.eql(u8, last, name)) continue;
        if (unique == wanted) return index;
        previous = name;
        unique += 1;
    }
    return null;
}

fn equal(left: []const u8, right: []const u8) bool {
    return std.mem.eql(u8, left, right);
}

fn testingProgramCreate(_: *anyopaque) ?*javascript.Program {
    return std.testing.allocator.create(javascript.Program) catch null;
}

fn testingProgramDestroy(_: *anyopaque, program: *javascript.Program) void {
    std.testing.allocator.destroy(program);
}

fn testingMemoryAllocate(_: *anyopaque, length: usize, alignment: usize) ?[*]u8 {
    return std.testing.allocator.rawAlloc(length, .fromByteUnits(alignment), @returnAddress());
}

fn testingMemoryFree(_: *anyopaque, memory: [*]u8, length: usize, alignment: usize) void {
    std.testing.allocator.rawFree(memory[0..length], .fromByteUnits(alignment), @returnAddress());
}

fn testingProgramAllocator(context: *anyopaque) ProgramAllocator {
    return .{
        .context = context,
        .create = testingProgramCreate,
        .destroy = testingProgramDestroy,
        .allocate = testingMemoryAllocate,
        .free = testingMemoryFree,
    };
}

const TestingAllocationTracker = struct {
    active_bytes: usize = 0,
    peak_bytes: usize = 0,
    allocation_count: usize = 0,
    free_count: usize = 0,
    fail_next_allocation: bool = false,

    fn record(self: *TestingAllocationTracker, length: usize) void {
        self.active_bytes += length;
        self.peak_bytes = @max(self.peak_bytes, self.active_bytes);
        self.allocation_count += 1;
    }

    fn create(raw_context: *anyopaque) ?*javascript.Program {
        const self: *TestingAllocationTracker = @ptrCast(@alignCast(raw_context));
        const program = std.testing.allocator.create(javascript.Program) catch return null;
        program.* = .{};
        self.record(@sizeOf(javascript.Program));
        return program;
    }

    fn destroy(raw_context: *anyopaque, program: *javascript.Program) void {
        const self: *TestingAllocationTracker = @ptrCast(@alignCast(raw_context));
        std.debug.assert(self.active_bytes >= @sizeOf(javascript.Program));
        self.active_bytes -= @sizeOf(javascript.Program);
        self.free_count += 1;
        std.testing.allocator.destroy(program);
    }

    fn allocate(raw_context: *anyopaque, length: usize, alignment: usize) ?[*]u8 {
        const self: *TestingAllocationTracker = @ptrCast(@alignCast(raw_context));
        if (self.fail_next_allocation) {
            self.fail_next_allocation = false;
            return null;
        }
        const memory = std.testing.allocator.rawAlloc(length, .fromByteUnits(alignment), @returnAddress()) orelse return null;
        self.record(length);
        return memory;
    }

    fn free(raw_context: *anyopaque, memory: [*]u8, length: usize, alignment: usize) void {
        const self: *TestingAllocationTracker = @ptrCast(@alignCast(raw_context));
        std.debug.assert(self.active_bytes >= length);
        self.active_bytes -= length;
        self.free_count += 1;
        std.testing.allocator.rawFree(memory[0..length], .fromByteUnits(alignment), @returnAddress());
    }

    fn programAllocator(self: *TestingAllocationTracker) ProgramAllocator {
        return .{
            .context = self,
            .create = create,
            .destroy = destroy,
            .allocate = allocate,
            .free = free,
        };
    }
};

const TestingStopState = struct {
    remaining: usize,
};

fn testingStopRequested(context: ?*anyopaque) bool {
    const state: *TestingStopState = @ptrCast(@alignCast(context orelse return false));
    if (state.remaining == 0) return true;
    state.remaining -= 1;
    return false;
}

test "browser runtime allocates and releases JavaScript realm on demand" {
    try std.testing.expectEqual(@as(usize, 16), max_script_programs);
    try std.testing.expectEqual(@as(usize, 8), javascript.max_modules);
    try std.testing.expect(@sizeOf(javascript.Runtime) > 32 * 1024 * 1024);
    try std.testing.expect(@sizeOf(WebRuntime) < 4 * 1024 * 1024);

    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    var tracker: TestingAllocationTracker = .{};
    harness.web.initialize(tracker.programAllocator());
    defer harness.web.deinit();
    harness.document.reset();
    harness.storage.reset();
    _ = try harness.document.parse("<!doctype html><body><p>static</p></body>", .{ .content_type = "text/html" });
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://static.example/", "", 1, 0);

    try std.testing.expect(!harness.web.javascriptRealmActive());
    try std.testing.expectEqual(@as(usize, 0), harness.web.javascriptRealmBytes());
    try std.testing.expectEqual(@as(usize, 0), tracker.active_bytes);
    try std.testing.expectEqual(@as(usize, 0), try harness.web.executeDocumentScripts());
    try std.testing.expectEqual(@as(usize, 0), try harness.web.pump(1, 8));
    try std.testing.expectEqual(@as(usize, 0), (try harness.web.dispatchEvent(.window, "load", 1)).queued);
    try std.testing.expectEqual(@as(usize, 0), tracker.active_bytes);

    tracker.fail_next_allocation = true;
    try std.testing.expectError(error.ScriptAllocation, harness.web.executeSource("globalThis.unreachable=true;"));
    try std.testing.expect(!harness.web.javascriptRealmActive());
    try std.testing.expectEqual(@as(usize, 0), tracker.active_bytes);

    _ = try harness.web.executeSource("globalThis.realmActive=true;");
    try std.testing.expect(harness.web.javascriptRealmActive());
    try std.testing.expectEqual(@sizeOf(javascript.Runtime), harness.web.javascriptRealmBytes());
    try std.testing.expect(tracker.peak_bytes >= @sizeOf(javascript.Runtime));
    const global_object = harness.web.runtime.global("globalThis").?;
    try std.testing.expect(harness.web.runtime.valueBoolean(try harness.web.runtime.get(global_object, "realmActive")));

    harness.web.abortDocument();
    try std.testing.expect(!harness.web.javascriptRealmActive());
    try std.testing.expectEqual(@as(usize, 0), tracker.active_bytes);
    try std.testing.expectEqual(tracker.allocation_count, tracker.free_count);
}

test "script observer reports bounded begin and finish events without changing execution" {
    const allocator = std.testing.allocator;
    const TraceState = struct {
        begins: usize = 0,
        finishes: usize = 0,
        source_len: usize = 0,
        begin_steps: usize = 0,
        finish_steps: usize = 0,
        node: u16 = html.none,
        success: bool = false,

        fn report(raw: ?*anyopaque, event: ScriptExecutionEvent) void {
            const self: *@This() = @ptrCast(@alignCast(raw orelse return));
            self.source_len = event.source.len;
            self.node = event.node;
            switch (event.phase) {
                .begin => {
                    self.begins += 1;
                    self.begin_steps = event.steps;
                },
                .finish => {
                    self.finishes += 1;
                    self.finish_steps = event.steps;
                    self.success = event.success;
                },
            }
        }
    };
    const Harness = struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
        trace: TraceState,
    };
    const harness = try allocator.create(Harness);
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    harness.storage = .{};
    harness.trace = .{};
    const source = "let observed=40+2";
    _ = try harness.document.parse("<body><script>" ++ source ++ "</script></body>", .{ .content_type = "text/html" });
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://trace.example/", "", 1, 0);
    harness.web.setScriptObserver(.{ .context = &harness.trace, .report = TraceState.report });
    try std.testing.expectEqual(@as(usize, 1), try harness.web.executeDocumentScripts());
    try std.testing.expectEqual(@as(usize, 1), harness.trace.begins);
    try std.testing.expectEqual(@as(usize, 1), harness.trace.finishes);
    try std.testing.expectEqual(source.len, harness.trace.source_len);
    try std.testing.expect(harness.trace.node != html.none);
    try std.testing.expectEqual(@as(usize, 0), harness.trace.begin_steps);
    try std.testing.expect(harness.trace.finish_steps > harness.trace.begin_steps);
    try std.testing.expect(harness.trace.success);
    try std.testing.expectEqual(@as(f64, 42), try harness.web.runtime.valueNumber(harness.web.runtime.global("observed").?));
}

test "injected monotonic clock advances performance and Date during one document execution" {
    const allocator = std.testing.allocator;
    const ClockState = struct {
        now_ms: f64 = 100,
        finishes: usize = 0,

        fn now(raw: ?*anyopaque) f64 {
            const self: *@This() = @ptrCast(@alignCast(raw orelse return 0));
            return self.now_ms;
        }

        fn report(raw: ?*anyopaque, event: ScriptExecutionEvent) void {
            const self: *@This() = @ptrCast(@alignCast(raw orelse return));
            if (event.phase != .finish) return;
            self.finishes += 1;
            if (self.finishes == 1) self.now_ms = 125;
        }
    };
    const Harness = struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
        clock: ClockState,
    };
    const harness = try allocator.create(Harness);
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    harness.storage = .{};
    harness.clock = .{};
    _ = try harness.document.parse(
        "<script>let firstClock=performance.now();let firstDate=Date.now()</script>" ++
            "<script>let secondClock=performance.now();let secondDate=Date.now()</script>",
        .{ .content_type = "text/html" },
    );
    harness.web.setMonotonicClock(.{ .context = &harness.clock, .now_milliseconds = ClockState.now });
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://clock.example/", "", 1, 100);
    harness.web.setClockState(1000, 100, 0);
    harness.web.setScriptObserver(.{ .context = &harness.clock, .report = ClockState.report });
    try std.testing.expectEqual(@as(usize, 2), try harness.web.executeDocumentScripts());
    try std.testing.expectEqual(@as(f64, 0), try harness.web.runtime.valueNumber(harness.web.runtime.global("firstClock").?));
    try std.testing.expectEqual(@as(f64, 25), try harness.web.runtime.valueNumber(harness.web.runtime.global("secondClock").?));
    try std.testing.expectEqual(@as(f64, 1000), try harness.web.runtime.valueNumber(harness.web.runtime.global("firstDate").?));
    try std.testing.expectEqual(@as(f64, 1025), try harness.web.runtime.valueNumber(harness.web.runtime.global("secondDate").?));
}

test "web runtime bounds scripts supports cooperative stop and slices queued jobs" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    harness.document = .{};
    harness.storage = .{};
    _ = try harness.document.parse("<!doctype html><body>", .{ .content_type = "text/html" });

    var stop_state = TestingStopState{ .remaining = 64 };
    harness.web.setExecutionPolicy(.{ .context = &stop_state, .requested = testingStopRequested }, 100000);
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://runtime.example/", "default-src 'self'", 1, 0);
    try std.testing.expectError(error.Cancelled, harness.web.executeSource("let value=0;while(true){value++;}"));
    const cancelled_diagnostic = harness.web.scriptDiagnostics();
    try std.testing.expectEqual(javascript.DiagnosticPhase.vm, cancelled_diagnostic.phase);
    try std.testing.expectEqualStrings("https://runtime.example/", cancelled_diagnostic.source_name);

    harness.web.setExecutionPolicy(.{}, 128);
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://runtime.example/", "default-src 'self'", 2, 0);
    try std.testing.expectError(error.StepLimit, harness.web.executeSource("let value=0;while(true){value++;}"));
    const limit_diagnostic = harness.web.scriptDiagnostics();
    try std.testing.expectEqualStrings("StepLimit", limit_diagnostic.error_name);
    try std.testing.expect(limit_diagnostic.line >= 1);
    try std.testing.expect(std.mem.indexOf(u8, harness.web.runtime.diagnosticStack(), "https://runtime.example/:") != null);

    harness.web.setExecutionPolicy(.{}, 100000);
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://runtime.example/", "default-src 'self'", 3, 0);
    _ = try harness.web.executeSource("let completed=0;for(let index=0;index<10;index++){queueMicrotask(()=>completed++);}");
    try std.testing.expectEqual(@as(usize, 3), try harness.web.pump(1, 3));
    try std.testing.expectEqual(@as(f64, 3), try harness.web.runtime.valueNumber(harness.web.runtime.global("completed").?));
    try std.testing.expectEqual(@as(usize, 7), try harness.web.pump(2, 32));
    try std.testing.expectEqual(@as(f64, 10), try harness.web.runtime.valueNumber(harness.web.runtime.global("completed").?));

    harness.document = .{};
    _ = try harness.document.parse(
        "<!doctype html><script>let spin=0;while(true){spin++;}</script><script>var afterError=1;</script>",
        .{ .content_type = "text/html" },
    );
    harness.web.setExecutionPolicy(.{}, 128);
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://runtime.example/document", "", 4, 0);
    try std.testing.expectEqual(@as(usize, 1), try harness.web.executeDocumentScripts());
    try std.testing.expectEqual(@as(f64, 1), try harness.web.runtime.valueNumber(harness.web.runtime.global("afterError").?));
    const retained_diagnostic = harness.web.scriptDiagnostics();
    try std.testing.expectEqual(@as(usize, 1), retained_diagnostic.error_count);
    try std.testing.expectEqual(javascript.DiagnosticPhase.vm, retained_diagnostic.phase);
    try std.testing.expectEqualStrings("StepLimit", retained_diagnostic.error_name);
    try std.testing.expect(std.mem.startsWith(u8, retained_diagnostic.source_name, "https://runtime.example/document#r4-inline-script-"));
}

test "timer jobs have independent budgets and never build a pump backlog" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    harness.document = .{};
    harness.storage = .{};
    _ = try harness.document.parse("<!doctype html><body>", .{ .content_type = "text/html" });
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://timers.example/", "", 1, 0);
    _ = try harness.web.executeSource(
        "let timerTurns=0;const timerIds=[];" ++
            "for(let index=0;index<4;index++)timerIds.push(setInterval(()=>timerTurns++,1));",
    );

    harness.web.setExecutionPolicy(.{}, 64);
    var now_ms: u32 = 1;
    while (now_ms <= 12) : (now_ms += 1) {
        try std.testing.expectEqual(@as(usize, 1), try harness.web.pump(@floatFromInt(now_ms), 1));
    }
    try std.testing.expectEqual(@as(f64, 12), try harness.web.runtime.valueNumber(harness.web.runtime.global("timerTurns").?));

    harness.web.setExecutionPolicy(.{}, 100000);
    _ = try harness.web.executeSource("timerIds.forEach(id=>clearInterval(id));");
    try std.testing.expectEqual(@as(usize, 0), try harness.web.pump(20, 64));
    try std.testing.expectEqual(@as(f64, 12), try harness.web.runtime.valueNumber(harness.web.runtime.global("timerTurns").?));
}

test "DOM queries preserve identity and structural operations expose coherent relations" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    _ = try harness.document.parse(
        "<!doctype html><html><body><main id='root'><ul id='list'><li class='item first' data-id='1'><span>A</span></li><li class='item' data-id='2'>B</li></ul></main></body></html>",
        .{ .content_type = "text/html" },
    );
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://runtime.example/", "default-src 'self'", 1, 0);

    const value = try harness.web.executeSource(
        "let ok=true;const list=document.getElementById('list');const first=document.querySelector('#list > li.item[data-id=\"1\"]');" ++
            "const items=document.querySelectorAll('#list > .item');ok=ok&&items.length===2&&items[0]===first&&first===document.getElementsByClassName('item first')[0];" ++
            "ok=ok&&document.getElementsByTagName('li').length===2&&first.matches('li.item')&&first.closest('#list')===list&&list.contains(first);" ++
            "ok=ok&&first.nodeType===1&&first.nodeName==='li'&&first.tagName==='LI'&&first.parentNode===list&&first.firstChild.nodeName==='span'&&first.firstElementChild===first.firstChild;" ++
            "const made=document.createElement('li');made.setAttribute('data-id','3');made.toggleAttribute('hidden');ok=ok&&made.hasAttribute('hidden')&&!made.isConnected;" ++
            "made.removeAttribute('hidden');const text=document.createTextNode('raw & text');made.appendChild(text);list.insertBefore(made,items[1]);" ++
            "ok=ok&&made.isConnected&&made.nextSibling===items[1]&&items[1].previousElementSibling===made&&text.nodeType===3&&text.nodeName==='#text'&&text.nodeValue==='raw & text';" ++
            "const replacement=document.createElement('li');replacement.textContent='R';const old=list.replaceChild(replacement,made);ok=ok&&old===made&&!old.isConnected&&replacement.textContent==='R';" ++
            "const removed=list.removeChild(replacement);list.appendChild(removed);const clone=list.cloneNode(true);ok=ok&&removed===replacement&&list.lastElementChild===replacement&&list.childElementCount===3;" ++
            "ok=ok&&clone.childNodes.length===3&&!clone.isConnected&&clone.querySelectorAll('li').length===3&&document.body.ownerDocument===document;removed.remove();" ++
            "ok=ok&&!removed.isConnected&&list.childElementCount===2;String(ok);",
    );
    try std.testing.expectEqualStrings("true", harness.web.runtime.valueString(value));
    try std.testing.expect(harness.web.dom_dirty);
    try std.testing.expectEqual(@as(usize, 1), harness.web.action_count);
    try std.testing.expectEqual(ActionKind.dom_changed, harness.web.takeAction().?.kind);
    try std.testing.expect(harness.web.takeAction() == null);
    try std.testing.expect(harness.web.needsReflow());

    for ([_]usize{ 15, 16, 17 }) |mutation_count| {
        var source_buffer: [128]u8 = undefined;
        const source = try std.fmt.bufPrint(source_buffer[0..], "for(let i=0;i<{d};i++)document.body.setAttribute('data-r',String(i));", .{mutation_count});
        _ = try harness.web.executeSource(source);
        try std.testing.expect(harness.web.dom_dirty);
        try std.testing.expect(harness.web.dom_action_pending);
        try std.testing.expectEqual(@as(usize, 1), harness.web.action_count);
        try std.testing.expectEqual(ActionKind.dom_changed, harness.web.takeAction().?.kind);
        try std.testing.expect(!harness.web.dom_action_pending);
        try std.testing.expect(harness.web.takeAction() == null);
        try std.testing.expect(harness.web.needsReflow());
    }
}

test "DOM events capture target bubble cancel stop and honor listener options" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    _ = try harness.document.parse("<!doctype html><html><body><main id='root'><button id='target'>Go</button></main></body></html>", .{ .content_type = "text/html" });
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://runtime.example/", "default-src 'self'", 1, 0);

    const value = try harness.web.executeSource(
        "const root=document.getElementById('root'),target=document.getElementById('target');let trace=[];" ++
            "window.addEventListener('ping',event=>trace.push('wc'+event.eventPhase),{capture:true});document.addEventListener('ping',event=>trace.push('dc'+event.eventPhase),true);" ++
            "root.addEventListener('ping',event=>trace.push('rc'+event.eventPhase),{capture:true});target.addEventListener('ping',event=>trace.push('tc'+event.eventPhase+String(event.target===target)),true);" ++
            "target.addEventListener('ping',event=>trace.push('tb'+event.eventPhase),{once:true});root.addEventListener('ping',event=>{trace.push('rb'+event.eventPhase);event.preventDefault();});" ++
            "window.addEventListener('ping',event=>trace.push('wb'+event.eventPhase));const first=!target.dispatchEvent(new Event('ping',{bubbles:true,cancelable:true}));" ++
            "const second=!target.dispatchEvent(new Event('ping',{bubbles:true,cancelable:true}));let stopped=[];target.addEventListener('halt',event=>{stopped.push('first');event.stopImmediatePropagation();});" ++
            "target.addEventListener('halt',()=>stopped.push('second'));root.addEventListener('halt',()=>stopped.push('root'));target.dispatchEvent(new Event('halt',{bubbles:true}));" ++
            "let handled=0;const objectListener={handleEvent(){handled++;}};target.addEventListener('solo',objectListener);target.dispatchEvent(new Event('solo'));target.removeEventListener('solo',objectListener);target.dispatchEvent(new Event('solo'));" ++
            "[trace.join(','),first,second,stopped.join(','),handled,Object.prototype.toString.call(new Event('x')),Event.length].join('|');",
    );
    try std.testing.expectEqualStrings(
        "wc1,dc1,rc1,tc2true,tb2,rb3,wb3,wc1,dc1,rc1,tc2true,rb3,wb3|true|true|first|1|[object Event]|1",
        harness.web.runtime.valueString(value),
    );
}

test "MutationObserver filters records preserves order and delivers one microtask" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    _ = try harness.document.parse("<!doctype html><html><body><main id='root'></main></body></html>", .{ .content_type = "text/html" });
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://runtime.example/", "default-src 'self'", 1, 0);

    _ = try harness.web.executeSource(
        "var mutationResult='';var mutationCalls=0;var sameObserver=false;var invalidOptions=0;var emptyCalls=0;const root=document.getElementById('root');" ++
            "const invalid=new MutationObserver(()=>{});try{invalid.observe(root,{attributes:false,attributeOldValue:true});}catch(reason){if(reason instanceof TypeError)invalidOptions++;}" ++
            "try{invalid.observe(root,{characterData:false,characterDataOldValue:true});}catch(reason){if(reason instanceof TypeError)invalidOptions++;}new MutationObserver(()=>emptyCalls++).observe(root,{attributeFilter:[]});" ++
            "const observer=new MutationObserver((records,self)=>{mutationCalls++;sameObserver=self===observer;mutationResult=records.map(record=>record.type+':'+record.target.nodeName+':'+record.addedNodes.length+':'+record.removedNodes.length+':'+record.attributeName+':'+record.oldValue).join('|');});" ++
            "observer.observe(root,{attributes:true,attributeOldValue:true,attributeFilter:['data-mode'],childList:true,characterData:true,characterDataOldValue:true,subtree:true});" ++
            "root.setAttribute('ignored','x');root.setAttribute('data-mode','new');const added=document.createElement('section');root.appendChild(added);" ++
            "const text=document.createTextNode('before');added.appendChild(text);text.nodeValue='after';added.remove();text.nodeValue='detached';",
    );
    try std.testing.expectEqual(@as(usize, 1), try harness.web.pump(1, 16));
    try std.testing.expectEqualStrings(
        "attributes:main:0:0:data-mode:null|childList:main:1:0:null:null|childList:section:1:0:null:null|characterData:#text:0:0:null:before|childList:main:0:1:null:null|characterData:#text:0:0:null:after",
        harness.web.runtime.valueString(harness.web.runtime.global("mutationResult").?),
    );
    try std.testing.expectEqual(@as(f64, 1), try harness.web.runtime.valueNumber(harness.web.runtime.global("mutationCalls").?));
    try std.testing.expect(harness.web.runtime.valueBoolean(harness.web.runtime.global("sameObserver").?));
    try std.testing.expectEqual(@as(f64, 2), try harness.web.runtime.valueNumber(harness.web.runtime.global("invalidOptions").?));
    try std.testing.expectEqual(@as(f64, 0), try harness.web.runtime.valueNumber(harness.web.runtime.global("emptyCalls").?));

    const pending = try harness.web.executeSource(
        "root.setAttribute('data-mode','next');const records=observer.takeRecords();observer.disconnect();root.setAttribute('data-mode','ignored-after-disconnect');" ++
            "records.length+':'+records[0].oldValue+':'+(observer instanceof MutationObserver)+':'+Object.prototype.toString.call(observer);",
    );
    try std.testing.expectEqualStrings("1:new:true:[object MutationObserver]", harness.web.runtime.valueString(pending));
    try std.testing.expectEqual(@as(usize, 1), try harness.web.pump(2, 16));
    try std.testing.expectEqual(@as(f64, 1), try harness.web.runtime.valueNumber(harness.web.runtime.global("mutationCalls").?));
}

test "History Location Navigation and timing expose one coherent document view" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    _ = try harness.document.parse("<!doctype html><html><body></body></html>", .{ .content_type = "text/html" });
    harness.web.setClockState(100_000, 50, 60);
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://secure.example:8443/a?x=1#old", "default-src 'self'", 7, 50);
    const entries = [_]navigation.Url{
        try navigation.parse("https://secure.example:8443/zero"),
        try navigation.parse("https://secure.example:8443/a?x=1#old"),
        try navigation.parse("https://secure.example:8443/forward"),
    };
    try harness.web.setNavigationSnapshot(entries[0..], &.{ 11, 12, 13 }, 1);
    harness.web.markResponseStart(60);
    harness.web.markDomContentLoadedStart(70);
    harness.web.markDomContentLoadedEnd(71);
    harness.web.markLoadStart(72);
    harness.web.markLoadComplete(75);

    const value = try harness.web.executeSource(
        "let changes=0;navigation.addEventListener('currententrychange',()=>changes++);const original={step:1};history.scrollRestoration='manual';" ++
            "const locationParts=[location.href,location.origin,location.protocol,location.host,location.hostname,location.port,location.pathname,location.search,location.hash,String(location)].join(',');" ++
            "history.pushState(original,'','/next?q=2#h');const pushed=history.state===original&&location.href==='https://secure.example:8443/next?q=2#h'&&history.length===3;" ++
            "history.replaceState({step:2},'',new String('/next2'));const updated={step:3};navigation.updateCurrentEntry({state:updated});const current=navigation.currentEntry;" ++
            "const navEntries=navigation.entries();const navigationView=[navEntries.length,current.index,current.url,current.sameDocument,current.getState()===updated,current===navEntries[2],navigation.canGoBack,!navigation.canGoForward,changes].join(',');" ++
            "const cancel=event=>event.preventDefault();navigation.addEventListener('navigate',cancel);const cancelled=navigation.navigate('/blocked');cancelled.committed.catch(()=>{});cancelled.finished.catch(()=>{});navigation.removeEventListener('navigate',cancel);" ++
            "let lastDestination='';navigation.addEventListener('navigate',event=>lastDestination=event.destination.key);const backward=navigation.back();history.go(-2);location.hash='#new';history.go();const timingEntry=performance.getEntries()[0];const byName=performance.getEntriesByName(location.href,'navigation');" ++
            "let timingCallError=false;try{new PerformanceNavigationTiming();}catch(reason){timingCallError=reason instanceof TypeError;}" ++
            "let brandError=false;try{history.pushState.call({},null,'','/bad');}catch(reason){brandError=reason instanceof TypeError;}" ++
            "[locationParts,history.scrollRestoration,pushed,navigationView,cancelled.committed instanceof Promise,backward.finished instanceof Promise," ++
            "performance.timeOrigin,performance.now(),timingEntry.responseStart,timingEntry.domContentLoadedEventStart,timingEntry.loadEventEnd,timingEntry.duration," ++
            "performance.getEntriesByType('navigation').length,byName.length,timingEntry instanceof PerformanceNavigationTiming,Object.prototype.toString.call(timingEntry),timingEntry.toJSON().type," ++
            "performance.timing.responseStart,timingCallError,brandError,lastDestination,timingEntry===performance.getEntries()[0]].join('|');",
    );
    try std.testing.expectEqualStrings(
        "https://secure.example:8443/a?x=1#old,https://secure.example:8443,https:,secure.example:8443,secure.example,8443,/a,?x=1,#old,https://secure.example:8443/a?x=1#old|manual|true|3,2,https://secure.example:8443/next2,true,true,true,true,true,3|true|true|100000|25|10|20|25|25|1|1|true|[object PerformanceNavigationTiming]|navigate|100010|true|true|r4-12|true",
        harness.web.runtime.valueString(value),
    );
    const push = harness.web.takeAction().?;
    try std.testing.expectEqual(ActionKind.push_state, push.kind);
    const replace = harness.web.takeAction().?;
    try std.testing.expectEqual(ActionKind.replace_state, replace.kind);
    const back = harness.web.takeAction().?;
    try std.testing.expectEqual(ActionKind.traverse, back.kind);
    try std.testing.expectEqual(@as(i32, -1), back.delta);
    const go = harness.web.takeAction().?;
    try std.testing.expectEqual(ActionKind.traverse, go.kind);
    try std.testing.expectEqual(@as(i32, -2), go.delta);
    const hash = harness.web.takeAction().?;
    try std.testing.expectEqual(ActionKind.navigate, hash.kind);
    try std.testing.expectEqualStrings("https://secure.example:8443/next2#new", hash.url.bytes());
    const reload = harness.web.takeAction().?;
    try std.testing.expectEqual(ActionKind.reload, reload.kind);
    try std.testing.expect(harness.web.takeAction() == null);
}

test "web font demands preserve source order fallback redirect CORS and transient large bodies" {
    const allocator = std.testing.allocator;
    const Harness = struct {
        document: html.Document,
        storage: security.BrowserStorage,
        registry: web_fonts.Registry,
        web: WebRuntime,
        events: [24]ResourceEvent = undefined,
        event_count: usize = 0,
        completion_ok: bool = false,
        completion_bytes: usize = 0,

        fn report(raw: ?*anyopaque, event: ResourceEvent) void {
            const self: *@This() = @ptrCast(@alignCast(raw orelse return));
            self.events[self.event_count] = event;
            self.event_count += 1;
        }

        fn complete(raw: ?*anyopaque, completion: ResourceCompletion) bool {
            const self: *@This() = @ptrCast(@alignCast(raw orelse return false));
            self.completion_bytes = completion.body.len;
            self.completion_ok = completion.kind == .font and
                completion.font_face_index == 0 and
                completion.font_source_index == 2 and
                completion.font_format == .woff and
                completion.font_source_origin == .network and
                completion.request_origin.scheme == .https and
                std.mem.eql(u8, completion.request_origin.hostBytes(), "page.example") and
                completion.redirected and
                std.mem.eql(u8, completion.requested_url.bytes(), "https://cdn.example/css/fallback.woff") and
                std.mem.eql(u8, completion.final_url.bytes(), "https://assets.example/final.woff") and
                completion.body.len == 200 * 1024 and
                completion.body[0] == 0x5a;
            return self.completion_ok;
        }
    };
    const harness = try allocator.create(Harness);
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    harness.storage = .{};
    harness.event_count = 0;
    harness.completion_ok = false;
    harness.completion_bytes = 0;
    _ = try harness.document.parse("<!doctype html><body></body>", .{ .content_type = "text/html" });
    harness.registry.beginDocument(3901);
    _ = try harness.registry.appendStylesheet(
        "@font-face{font-family:'Used Face';src:local('Installed Face'),url('../fonts/primary.woff2') format(woff2),url('fallback.woff') format(woff);unicode-range:U+0-7F}" ++
            "@font-face{font-family:'Unused Face';src:url('unused.woff2') format(woff2)}",
        "https://cdn.example/css/site.css",
    );
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://page.example/index", "font-src https:", 39, 0);
    harness.web.setResourceObserver(.{ .context = harness, .report = Harness.report });
    harness.web.setResourceHandler(.{ .context = harness, .complete = Harness.complete });

    const stats = try harness.web.syncFontDemands(&harness.registry, &.{.{
        .family_list = "'Missing', 'Used Face', sans-serif",
        .text = "R4OS",
    }});
    try std.testing.expectEqual(@as(usize, 1), stats.demanded_faces);
    try std.testing.expectEqual(@as(usize, 1), stats.queued_faces);
    const primary = harness.web.takeRequest().?;
    const primary_id = primary.id;
    const primary_generation = primary.generation;
    try std.testing.expectEqual(RequestKind.font, primary.kind);
    try std.testing.expectEqual(security.RequestMode.cors, primary.mode);
    try std.testing.expectEqual(security.CredentialsMode.same_origin, primary.credentials);
    try std.testing.expectEqualStrings("https://cdn.example/fonts/primary.woff2", primary.url.bytes());
    try std.testing.expectEqual(@as(usize, 1), harness.web.resources.count);
    try harness.web.failRequest(primary_id, primary_generation, "primary unavailable");
    try std.testing.expectEqual(FontFaceStatus.loading, harness.web.fontFaceStatus(0));

    const fallback = harness.web.takeRequest().?;
    const fallback_id = fallback.id;
    const fallback_generation = fallback.generation;
    try std.testing.expectEqual(RequestKind.font, fallback.kind);
    try std.testing.expectEqualStrings("https://cdn.example/css/fallback.woff", fallback.url.bytes());
    const large_body = try allocator.alloc(u8, 200 * 1024);
    defer allocator.free(large_body);
    @memset(large_body, 0x5a);
    try harness.web.completeRequest(fallback_id, fallback_generation, .{
        .status = 200,
        .secure = true,
        .content_type = "font/woff",
        .redirected = true,
        .final_url = "https://assets.example/final.woff",
        .access_control_allow_origin = "https://page.example",
    }, large_body);
    try std.testing.expect(harness.completion_ok);
    try std.testing.expectEqual(@as(usize, 200 * 1024), harness.completion_bytes);
    try std.testing.expect(harness.web.resourcesSettled());
    try std.testing.expect(harness.web.takeRequest() == null);

    const retained = try harness.web.syncFontFaces(&harness.registry, &.{0});
    try std.testing.expectEqual(@as(usize, 1), retained.retained_faces);
    var saw_primary_failure = false;
    var saw_redirected_ready = false;
    var saw_unselected_local_transition = false;
    for (harness.events[0..harness.event_count]) |event| {
        if (event.kind != .font or event.font_face_index != 0) continue;
        if (event.font_source_index == 0) saw_unselected_local_transition = true;
        if (event.phase == .failed and event.failure == .fetch and event.font_source_index == 1) saw_primary_failure = true;
        if (event.phase == .ready and event.font_source_index == 2 and event.redirected and
            event.byte_count == 200 * 1024 and
            std.mem.eql(u8, event.final_url.bytes(), "https://assets.example/final.woff")) saw_redirected_ready = true;
    }
    try std.testing.expect(saw_primary_failure);
    try std.testing.expect(saw_redirected_ready);
    try std.testing.expect(!saw_unselected_local_transition);
}

test "web font source probes satisfy local and warm cache faces without network" {
    const allocator = std.testing.allocator;
    const Harness = struct {
        document: html.Document,
        storage: security.BrowserStorage,
        registry: web_fonts.Registry,
        web: WebRuntime,
        events: [12]ResourceEvent = undefined,
        event_count: usize = 0,
        consumer_calls: usize = 0,
        cache_contract_valid: bool = false,

        fn localAvailable(_: ?*anyopaque, probe: FontSourceProbe) bool {
            return probe.face_index == 0 and probe.source_index == 0 and std.mem.eql(u8, probe.source_value, "Installed Face");
        }

        fn cachedAvailable(_: ?*anyopaque, probe: FontSourceProbe, final_url: *navigation.Url) bool {
            final_url.* = navigation.parse("https://cache.example/final/cached.woff2") catch return false;
            return probe.request_origin.scheme == .https and
                std.mem.eql(u8, probe.request_origin.hostBytes(), "page.example") and
                probe.face_index == 1 and probe.source_index == 0 and
                std.mem.eql(u8, probe.resolved_url.bytes(), "https://cache.example/fonts/cached.woff2");
        }

        fn report(raw: ?*anyopaque, event: ResourceEvent) void {
            const self: *@This() = @ptrCast(@alignCast(raw orelse return));
            self.events[self.event_count] = event;
            self.event_count += 1;
        }

        fn complete(raw: ?*anyopaque, completion: ResourceCompletion) bool {
            const self: *@This() = @ptrCast(@alignCast(raw orelse return false));
            self.consumer_calls += 1;
            self.cache_contract_valid = completion.kind == .font and
                completion.font_source_origin == .cache and
                completion.font_face_index == 1 and completion.font_source_index == 0 and
                completion.font_format == .woff2 and completion.status == 0 and
                completion.body.len == 0 and completion.byte_count == 0 and completion.redirected and
                completion.request_origin.scheme == .https and
                std.mem.eql(u8, completion.request_origin.hostBytes(), "page.example") and
                std.mem.eql(u8, completion.requested_url.bytes(), "https://cache.example/fonts/cached.woff2") and
                std.mem.eql(u8, completion.final_url.bytes(), "https://cache.example/final/cached.woff2");
            return self.cache_contract_valid;
        }
    };
    const harness = try allocator.create(Harness);
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    harness.storage = .{};
    harness.event_count = 0;
    harness.consumer_calls = 0;
    harness.cache_contract_valid = false;
    _ = try harness.document.parse("<!doctype html><body></body>", .{ .content_type = "text/html" });
    harness.registry.beginDocument(3902);
    _ = try harness.registry.appendStylesheet(
        "@font-face{font-family:LocalFace;src:local('Installed Face'),url(local-fallback.woff2) format(woff2)}" ++
            "@font-face{font-family:CachedFace;src:url('/fonts/cached.woff2') format(woff2)}",
        "https://cache.example/css/site.css",
    );
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://page.example/", "font-src https:", 40, 0);
    harness.web.setResourceObserver(.{ .context = harness, .report = Harness.report });
    harness.web.setResourceHandler(.{ .context = harness, .complete = Harness.complete });
    harness.web.setFontSourceHandler(.{
        .local_available = Harness.localAvailable,
        .cached_available = Harness.cachedAvailable,
    });

    const stats = try harness.web.syncFontFaces(&harness.registry, &.{ 0, 1, 1 });
    try std.testing.expectEqual(@as(usize, 2), stats.demanded_faces);
    try std.testing.expectEqual(@as(usize, 2), stats.available_faces);
    try std.testing.expectEqual(@as(usize, 1), harness.consumer_calls);
    try std.testing.expect(harness.cache_contract_valid);
    try std.testing.expect(harness.web.takeRequest() == null);
    try std.testing.expect(harness.web.resourcesSettled());
    var local_ready = false;
    var cache_ready = false;
    for (harness.events[0..harness.event_count]) |event| {
        if (event.kind != .font or event.phase != .ready) continue;
        if (event.font_face_index == 0 and event.font_source_index == 0 and event.font_source_origin == .local) local_ready = true;
        if (event.font_face_index == 1 and event.font_source_index == 0 and event.font_source_origin == .cache) cache_ready = true;
    }
    try std.testing.expect(local_ready);
    try std.testing.expect(cache_ready);
}

test "web font rejected warm cache retries the same declared URL over network" {
    const allocator = std.testing.allocator;
    const Harness = struct {
        document: html.Document,
        storage: security.BrowserStorage,
        registry: web_fonts.Registry,
        web: WebRuntime,
        cache_calls: usize = 0,
        network_calls: usize = 0,

        fn cachedAvailable(_: ?*anyopaque, probe: FontSourceProbe, final_url: *navigation.Url) bool {
            if (probe.face_index != 0 or probe.source_index != 0) return false;
            final_url.* = probe.resolved_url;
            return true;
        }

        fn complete(raw: ?*anyopaque, completion: ResourceCompletion) bool {
            const self: *@This() = @ptrCast(@alignCast(raw orelse return false));
            switch (completion.font_source_origin) {
                .cache => {
                    self.cache_calls += 1;
                    return false;
                },
                .network => {
                    self.network_calls += 1;
                    return completion.font_source_index == 0 and
                        std.mem.eql(u8, completion.requested_url.bytes(), "https://fonts.example/first.woff2") and
                        std.mem.eql(u8, completion.body, "fresh font bytes");
                },
                .local => return false,
            }
        }
    };
    const harness = try allocator.create(Harness);
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    harness.storage = .{};
    harness.cache_calls = 0;
    harness.network_calls = 0;
    _ = try harness.document.parse("<!doctype html><body></body>", .{ .content_type = "text/html" });
    harness.registry.beginDocument(3907);
    _ = try harness.registry.appendStylesheet(
        "@font-face{font-family:Retry;src:url(first.woff2) format(woff2),url(second.woff2) format(woff2)}",
        "https://fonts.example/site.css",
    );
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://page.example/", "font-src https://fonts.example", 45, 0);
    harness.web.setResourceHandler(.{ .context = harness, .complete = Harness.complete });
    harness.web.setFontSourceHandler(.{ .cached_available = Harness.cachedAvailable });

    _ = try harness.web.syncFontFaces(&harness.registry, &.{0});
    try std.testing.expectEqual(@as(usize, 1), harness.cache_calls);
    try std.testing.expectEqual(FontFaceStatus.loading, harness.web.fontFaceStatus(0));
    try std.testing.expectEqual(@as(u8, 1), harness.web.font_faces[0].next_source_index);
    const request = harness.web.takeRequest().?;
    try std.testing.expectEqualStrings("https://fonts.example/first.woff2", request.url.bytes());
    try harness.web.completeRequest(request.id, request.generation, .{
        .status = 200,
        .secure = true,
        .content_type = "font/woff2",
        .access_control_allow_origin = "https://page.example",
    }, "fresh font bytes");
    try std.testing.expectEqual(@as(usize, 1), harness.network_calls);
    try std.testing.expectEqual(FontFaceStatus.ready, harness.web.fontFaceStatus(0));
    try std.testing.expect(harness.web.takeRequest() == null);
    try std.testing.expect(harness.web.resourcesSettled());
}

test "web font policy failures and document aborts remain terminal and generation safe" {
    const allocator = std.testing.allocator;
    const Harness = struct {
        document: html.Document,
        storage: security.BrowserStorage,
        registry: web_fonts.Registry,
        web: WebRuntime,
        events: [24]ResourceEvent = undefined,
        event_count: usize = 0,
        cache_probe_count: usize = 0,

        fn report(raw: ?*anyopaque, event: ResourceEvent) void {
            const self: *@This() = @ptrCast(@alignCast(raw orelse return));
            self.events[self.event_count] = event;
            self.event_count += 1;
        }

        fn cachedAvailable(raw: ?*anyopaque, probe: FontSourceProbe, final_url: *navigation.Url) bool {
            const self: *@This() = @ptrCast(@alignCast(raw orelse return false));
            self.cache_probe_count += 1;
            final_url.* = probe.resolved_url;
            return true;
        }
    };
    const harness = try allocator.create(Harness);
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    harness.storage = .{};
    harness.event_count = 0;
    harness.cache_probe_count = 0;
    _ = try harness.document.parse("<!doctype html><body></body>", .{ .content_type = "text/html" });
    harness.registry.beginDocument(3903);
    _ = try harness.registry.appendStylesheet(
        "@font-face{font-family:Denied;src:url(one.woff2) format(woff2),url(two.woff) format(woff)}",
        "https://fonts.example/site.css",
    );
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://page.example/", "font-src 'none'", 41, 0);
    harness.web.setResourceObserver(.{ .context = harness, .report = Harness.report });
    harness.web.setFontSourceHandler(.{ .context = harness, .cached_available = Harness.cachedAvailable });
    _ = try harness.web.syncFontDemands(&harness.registry, &.{.{ .family_list = "Denied", .text = "A" }});
    try std.testing.expect(harness.web.takeRequest() == null);
    try std.testing.expect(harness.web.resourcesSettled());
    try std.testing.expectEqual(@as(usize, 0), harness.cache_probe_count);
    const denied_repeat = try harness.web.syncFontFaces(&harness.registry, &.{0});
    try std.testing.expectEqual(@as(usize, 1), denied_repeat.failed_faces);
    try std.testing.expectEqual(FontFaceStatus.failed, harness.web.fontFaceStatus(0));
    var denied_sources: usize = 0;
    for (harness.events[0..harness.event_count]) |event| {
        if (event.kind == .font and event.phase == .failed and event.failure == .policy and event.font_face_index == 0) denied_sources += 1;
    }
    try std.testing.expectEqual(@as(usize, 2), denied_sources);

    harness.registry.beginDocument(3904);
    _ = try harness.registry.appendStylesheet("@font-face{font-family:AbortFace;src:url(abort.woff2) format(woff2)}", "https://fonts.example/site.css");
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://page.example/next", "font-src https:", 42, 0);
    harness.web.setFontSourceHandler(.{});
    _ = try harness.web.syncFontFaces(&harness.registry, &.{0});
    const request = harness.web.takeRequest().?;
    const request_id = request.id;
    const request_generation = request.generation;
    harness.web.abortDocument();
    try std.testing.expectError(error.StaleGeneration, harness.web.completeRequest(request_id, request_generation, .{
        .status = 200,
        .secure = true,
        .access_control_allow_origin = "https://page.example",
    }, "late"));
    var saw_abort = false;
    for (harness.events[0..harness.event_count]) |event| {
        if (event.kind == .font and event.phase == .aborted and event.generation == 42 and event.font_face_index == 0 and event.font_source_index == 0) saw_abort = true;
    }
    try std.testing.expect(saw_abort);
}

test "web font warm redirect is reauthorized and resource limit rolls back face state" {
    const allocator = std.testing.allocator;
    const Harness = struct {
        document: html.Document,
        storage: security.BrowserStorage,
        registry: web_fonts.Registry,
        web: WebRuntime,
        consumer_calls: usize = 0,
        local_probe_calls: usize = 0,

        fn redirectedCache(_: ?*anyopaque, _: FontSourceProbe, final_url: *navigation.Url) bool {
            final_url.* = navigation.parse("https://blocked.example/final.woff2") catch return false;
            return true;
        }

        fn complete(raw: ?*anyopaque, _: ResourceCompletion) bool {
            const self: *@This() = @ptrCast(@alignCast(raw orelse return false));
            self.consumer_calls += 1;
            return true;
        }

        fn localAvailable(raw: ?*anyopaque, _: FontSourceProbe) bool {
            const self: *@This() = @ptrCast(@alignCast(raw orelse return false));
            self.local_probe_calls += 1;
            return true;
        }
    };
    const harness = try allocator.create(Harness);
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    harness.storage = .{};
    harness.consumer_calls = 0;
    harness.local_probe_calls = 0;
    _ = try harness.document.parse("<!doctype html><body></body>", .{ .content_type = "text/html" });
    harness.registry.beginDocument(3905);
    _ = try harness.registry.appendStylesheet(
        "@font-face{font-family:WarmRedirect;src:url(font.woff2) format(woff2)}",
        "https://cache.example/site.css",
    );
    try harness.web.beginDocument(
        &harness.document,
        &harness.storage,
        "https://page.example/",
        "font-src https://cache.example",
        43,
        0,
    );
    harness.web.setResourceHandler(.{ .context = harness, .complete = Harness.complete });
    harness.web.setFontSourceHandler(.{ .cached_available = Harness.redirectedCache });
    _ = try harness.web.syncFontFaces(&harness.registry, &.{0});
    try std.testing.expectEqual(@as(usize, 0), harness.consumer_calls);
    const request = harness.web.takeRequest().?;
    try std.testing.expectEqual(RequestKind.font, request.kind);
    try std.testing.expectEqualStrings("https://cache.example/font.woff2", request.url.bytes());
    harness.web.abortDocument();

    harness.registry.beginDocument(3906);
    _ = try harness.registry.appendStylesheet(
        "@font-face{font-family:NoSlot;src:local('Installed Face'),url(font.woff2) format(woff2)}",
        "https://cache.example/site.css",
    );
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://page.example/next", "font-src https:", 44, 0);
    harness.web.setFontSourceHandler(.{ .context = harness, .local_available = Harness.localAvailable });
    harness.web.resources.count = harness.web.resources.entries.len;
    try std.testing.expectError(error.ResourceLimit, harness.web.syncFontFaces(&harness.registry, &.{0}));
    try std.testing.expectEqual(@as(usize, 0), harness.local_probe_calls);
    try std.testing.expectEqual(FontFacePhase.failed, harness.web.font_faces[0].phase);
    try std.testing.expectEqual(@as(u32, 0), harness.web.font_faces[0].active_resource_id);
    const repeated = try harness.web.syncFontFaces(&harness.registry, &.{0});
    try std.testing.expectEqual(@as(usize, 1), repeated.failed_faces);
}

test "partial local web font success settles before preserving ResourceLimit" {
    const allocator = std.testing.allocator;
    const Harness = struct {
        document: html.Document,
        storage: security.BrowserStorage,
        registry: web_fonts.Registry,
        web: WebRuntime,
        local_probe_calls: usize = 0,
        events: [4]ResourceEvent = undefined,
        event_count: usize = 0,

        fn localAvailable(raw: ?*anyopaque, _: FontSourceProbe) bool {
            const self: *@This() = @ptrCast(@alignCast(raw orelse return false));
            self.local_probe_calls += 1;
            return true;
        }

        fn report(raw: ?*anyopaque, event: ResourceEvent) void {
            const self: *@This() = @ptrCast(@alignCast(raw orelse return));
            if (event.kind != .font or self.event_count >= self.events.len) return;
            self.events[self.event_count] = event;
            self.event_count += 1;
        }
    };
    const harness = try allocator.create(Harness);
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    harness.storage = .{};
    harness.local_probe_calls = 0;
    harness.event_count = 0;
    _ = try harness.document.parse("<!doctype html><body></body>", .{ .content_type = "text/html" });
    harness.registry.beginDocument(3910);
    _ = try harness.registry.appendStylesheet(
        "@font-face{font-family:First;src:local('Installed First')}" ++
            "@font-face{font-family:Second;src:local('Installed Second')}",
        "https://page.example/site.css",
    );
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://page.example/", "font-src 'self'", 48, 0);
    harness.web.setResourceObserver(.{ .context = harness, .report = Harness.report });
    harness.web.setFontSourceHandler(.{ .context = harness, .local_available = Harness.localAvailable });

    harness.web.resources.count = harness.web.resources.entries.len;
    harness.web.resources.next_id = 100;
    for (&harness.web.resources.entries, 0..) |*entry, index| {
        entry.* = .{
            .id = @intCast(index + 1),
            .generation = harness.web.generation,
            .sequence = @intCast(index),
            .node = html.none,
            .kind = if (index == 0) .font else .image,
            .script_mode = .none,
            .request_required = false,
            .state = .complete,
        };
    }

    try std.testing.expectError(error.ResourceLimit, harness.web.syncFontFaces(&harness.registry, &.{ 0, 1 }));
    try std.testing.expectEqual(@as(usize, 1), harness.local_probe_calls);
    try std.testing.expectEqual(FontFaceStatus.ready, harness.web.fontFaceStatus(0));
    try std.testing.expectEqual(FontFaceStatus.failed, harness.web.fontFaceStatus(1));
    try std.testing.expectEqual(web_resources.State.complete, harness.web.resources.entries[0].state);
    try std.testing.expect(harness.web.resources.settled());
    var saw_ready = false;
    for (harness.events[0..harness.event_count]) |event| {
        if (event.font_face_index == 0 and event.font_source_index == 0 and event.phase == .ready and
            event.font_source_origin == .local) saw_ready = true;
    }
    try std.testing.expect(saw_ready);
}

test "transport redirect targets enforce current CSP and mixed content policy" {
    const allocator = std.testing.allocator;
    const web = try allocator.create(WebRuntime);
    defer allocator.destroy(web);
    web.generation = 47;
    web.last_block_reason = .none;
    web.security_context = try security.SecurityContext.init(
        "https://page.example/document",
        web.generation,
        "font-src https://assets.example",
    );

    try std.testing.expect(web.authorizeRequestTarget(
        web.generation,
        .font,
        .cors,
        "https://assets.example/start.woff2",
    ));
    try std.testing.expect(!web.authorizeRequestTarget(
        web.generation,
        .font,
        .cors,
        "http://assets.example/intermediate.woff2",
    ));
    try std.testing.expectEqual(security.BlockReason.mixed_content, web.last_block_reason);
    try std.testing.expect(!web.authorizeRequestTarget(
        web.generation,
        .font,
        .cors,
        "https://blocked.example/intermediate.woff2",
    ));
    try std.testing.expectEqual(security.BlockReason.content_security_policy, web.last_block_reason);
    try std.testing.expect(web.authorizeRequestTarget(
        web.generation,
        .font,
        .cors,
        "https://assets.example/final.woff2",
    ));
    try std.testing.expect(!web.authorizeRequestTarget(
        web.generation - 1,
        .font,
        .cors,
        "https://assets.example/stale.woff2",
    ));
}

test "web font discovery retries after a general request slot becomes reusable" {
    const allocator = std.testing.allocator;
    const Harness = struct {
        document: html.Document,
        storage: security.BrowserStorage,
        registry: web_fonts.Registry,
        web: WebRuntime,
    };
    const harness = try allocator.create(Harness);
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    harness.storage = .{};
    _ = try harness.document.parse("<!doctype html><body></body>", .{ .content_type = "text/html" });
    harness.registry.beginDocument(3907);
    _ = try harness.registry.appendStylesheet(
        "@font-face{font-family:RetryFace;src:url(font.woff2) format(woff2)}",
        "https://page.example/site.css",
    );
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://page.example/", "font-src 'self'", 45, 0);
    const fetch_url = try navigation.parse("https://page.example/fetch");
    var request_index: usize = 0;
    while (request_index < max_requests) : (request_index += 1) {
        _ = try harness.web.queueRequest(fetch_url, .fetch, .undefined, .undefined, .{});
    }
    _ = try harness.web.syncFontFaces(&harness.registry, &.{0});
    try std.testing.expect(!harness.web.resourcesSettled());
    const fetch = harness.web.takeRequest().?;
    try std.testing.expectEqual(RequestKind.fetch, fetch.kind);
    const fetch_id = fetch.id;
    const fetch_generation = fetch.generation;
    try harness.web.completeRequest(fetch_id, fetch_generation, .{ .status = 200, .secure = true }, "ok");
    _ = try harness.web.pump(1, 1);
    const font = harness.web.takeRequest().?;
    try std.testing.expectEqual(RequestKind.font, font.kind);
    try std.testing.expectEqualStrings("https://page.example/font.woff2", font.url.bytes());
}

test "conditional web font reset aborts stale work and reuses its resource slot" {
    const allocator = std.testing.allocator;
    const Harness = struct {
        document: html.Document,
        storage: security.BrowserStorage,
        first_registry: web_fonts.Registry,
        second_registry: web_fonts.Registry,
        web: WebRuntime,
    };
    const harness = try allocator.create(Harness);
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    harness.storage = .{};
    _ = try harness.document.parse("<!doctype html><body></body>", .{ .content_type = "text/html" });
    harness.first_registry.beginDocument(3908);
    _ = try harness.first_registry.appendStylesheet(
        "@font-face{font-family:Responsive;src:url(compact.woff2) format(woff2)}",
        "https://page.example/site.css",
    );
    harness.second_registry.beginDocument(3908);
    _ = try harness.second_registry.appendStylesheet(
        "@font-face{font-family:Responsive;src:url(wide.woff2) format(woff2)}",
        "https://page.example/site.css",
    );
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://page.example/", "font-src 'self'", 46, 0);

    _ = try harness.web.syncFontFaces(&harness.first_registry, &.{0});
    const compact = harness.web.takeRequest().?;
    const compact_id = compact.id;
    try std.testing.expectEqualStrings("https://page.example/compact.woff2", compact.url.bytes());
    const resource_count = harness.web.resources.count;
    harness.web.resetFontFaces();
    try std.testing.expectEqual(RequestState.aborted, compact.state);
    try std.testing.expect(harness.web.resources.entries[0].state == .aborted);

    _ = try harness.web.syncFontFaces(&harness.second_registry, &.{0});
    try std.testing.expectEqual(resource_count, harness.web.resources.count);
    const wide = harness.web.takeRequest().?;
    try std.testing.expectEqualStrings("https://page.example/wide.woff2", wide.url.bytes());
    try std.testing.expect(wide.id != compact_id);
}

test "document resources honor parser blocking async defer generations and shared completion" {
    const allocator = std.testing.allocator;
    const Harness = struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
        completions: [8]web_resources.Kind = undefined,
        completion_count: usize = 0,

        fn complete(raw: ?*anyopaque, completion: ResourceCompletion) bool {
            const self: *@This() = @ptrCast(@alignCast(raw orelse return false));
            if (completion.generation != 21) return false;
            self.completions[self.completion_count] = completion.kind;
            self.completion_count += 1;
            return switch (completion.kind) {
                .stylesheet => std.mem.eql(u8, completion.body, "body{color:red}"),
                .image => std.mem.eql(u8, completion.body, "BM"),
                .subdocument => std.mem.indexOf(u8, completion.body, "frame") != null,
                .script => false,
                .font => false,
            };
        }
    };
    const harness = try allocator.create(Harness);
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    harness.completion_count = 0;
    _ = try harness.document.parse(
        "<body><script>var resourceOrder='A'</script>" ++
            "<script src='/block.js'></script><script>resourceOrder+='C';const dynamicScript=document.createElement('script');dynamicScript.textContent=\"resourceOrder+='Y'\";document.querySelector('body').appendChild(dynamicScript)</script>" ++
            "<script async src='/async.js'></script><script defer src='/defer.js'></script>" ++
            "<link rel=stylesheet href='/page.css'><img src='/pixel.bmp'>" ++
            "<iframe srcdoc='<p>frame</p>'></iframe></body>",
        .{ .content_type = "text/html" },
    );
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://resource.example/index", "", 21, 0);
    harness.web.setResourceHandler(.{ .context = harness, .complete = Harness.complete });
    try std.testing.expectEqual(@as(usize, 1), try harness.web.executeDocumentScripts());
    try std.testing.expectEqual(@as(usize, 1), harness.completion_count);
    try std.testing.expectEqual(web_resources.Kind.subdocument, harness.completions[0]);

    var requests: [5]struct { id: u32, generation: u32, kind: RequestKind } = undefined;
    for (&requests) |*saved| {
        const request = harness.web.takeRequest().?;
        saved.* = .{ .id = request.id, .generation = request.generation, .kind = request.kind };
    }
    try std.testing.expect(harness.web.takeRequest() == null);
    try std.testing.expectEqual(RequestKind.script, requests[0].kind);
    try std.testing.expectEqual(RequestKind.script, requests[1].kind);
    try std.testing.expectEqual(RequestKind.script, requests[2].kind);
    try std.testing.expectEqual(RequestKind.stylesheet, requests[3].kind);
    try std.testing.expectEqual(RequestKind.image, requests[4].kind);

    try harness.web.completeRequest(requests[1].id, requests[1].generation, .{ .status = 200, .secure = true }, "resourceOrder+='X'");
    try std.testing.expectEqualStrings("AX", harness.web.runtime.valueString(harness.web.runtime.global("resourceOrder").?));
    try harness.web.completeRequest(requests[2].id, requests[2].generation, .{ .status = 200, .secure = true }, "resourceOrder+='D'");
    try std.testing.expectEqualStrings("AX", harness.web.runtime.valueString(harness.web.runtime.global("resourceOrder").?));
    try harness.web.completeRequest(requests[0].id, requests[0].generation, .{ .status = 200, .secure = true }, "resourceOrder+='B'");
    try std.testing.expectEqual(@as(usize, 9), harness.web.resources.count);
    try std.testing.expectEqual(web_resources.ScriptMode.dynamic, harness.web.resources.entries[8].script_mode);
    try std.testing.expectEqual(web_resources.State.complete, harness.web.resources.entries[8].state);
    try std.testing.expectEqualStrings("AXBCYD", harness.web.runtime.valueString(harness.web.runtime.global("resourceOrder").?));
    try harness.web.completeRequest(requests[3].id, requests[3].generation, .{ .status = 200, .secure = true, .content_type = "text/css" }, "body{color:red}");
    try harness.web.completeRequest(requests[4].id, requests[4].generation, .{ .status = 200, .secure = true, .content_type = "image/bmp" }, "BM");
    try std.testing.expectEqualSlices(web_resources.Kind, &.{ .subdocument, .stylesheet, .image }, harness.completions[0..harness.completion_count]);
    try std.testing.expect(harness.web.resourcesSettled());
    try std.testing.expectEqual(@as(usize, 0), harness.web.script_error_count);
}

test "responsive picture base URLs and embedded SVG share the document resource lifecycle" {
    const allocator = std.testing.allocator;
    const Harness = struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
        embedded_ok: bool = false,

        fn complete(raw: ?*anyopaque, completion: ResourceCompletion) bool {
            const self: *@This() = @ptrCast(@alignCast(raw orelse return false));
            if (completion.kind != .image) return true;
            if (completion.status == 0) {
                self.embedded_ok = std.ascii.eqlIgnoreCase(completion.content_type, "image/svg+xml") and
                    std.mem.indexOf(u8, completion.body, "<svg") != null and
                    std.mem.indexOf(u8, completion.body, "<rect") != null;
                return self.embedded_ok;
            }
            return completion.status == 200;
        }
    };
    const harness = try allocator.create(Harness);
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    _ = try harness.document.parse(
        "<!doctype html><base href='https://resource.example/assets/'>" ++
            "<picture><source media='(min-width:600px)' type='image/png' srcset='wide.png 1x, wide2.png 2x'>" ++
            "<img src='fallback.png' alt='picture'></picture>" ++
            "<img srcset='small.png 320w, large.png 800w' sizes='400px' alt='width'>" ++
            "<img src='data:image/svg+xml,%3Csvg%20viewBox=%220%200%201%201%22%3E%3Crect%20width=%221%22%20height=%221%22/%3E%3C/svg%3E' alt='embedded'>",
        .{ .content_type = "text/html" },
    );
    harness.web.setEnvironment(.{ .viewport_width = 800, .viewport_height = 600 });
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://resource.example/index", "img-src 'self' data:", 61, 0);
    harness.web.setResourceHandler(.{ .context = harness, .complete = Harness.complete });
    _ = try harness.web.executeDocumentScripts();
    try std.testing.expect(harness.embedded_ok);

    const picture = harness.web.takeRequest().?;
    try std.testing.expectEqual(RequestKind.image, picture.kind);
    try std.testing.expectEqualStrings("https://resource.example/assets/wide.png", picture.url.bytes());
    const width = harness.web.takeRequest().?;
    try std.testing.expectEqual(RequestKind.image, width.kind);
    try std.testing.expectEqualStrings("https://resource.example/assets/large.png", width.url.bytes());
    try std.testing.expect(harness.web.takeRequest() == null);

    try harness.web.completeRequest(picture.id, picture.generation, .{ .status = 200, .secure = true, .content_type = "image/png" }, "PNG");
    try harness.web.completeRequest(width.id, width.generation, .{ .status = 200, .secure = true, .content_type = "image/png" }, "PNG");
    try std.testing.expect(harness.web.resourcesSettled());
}

test "CSS background images share resource policy without stealing IMG content or DOM events" {
    const allocator = std.testing.allocator;
    const Harness = struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
        completions: [8]ResourceCompletion = undefined,
        completion_count: usize = 0,
        events: [48]ResourceEvent = undefined,
        event_count: usize = 0,

        fn complete(raw: ?*anyopaque, completion: ResourceCompletion) bool {
            const self: *@This() = @ptrCast(@alignCast(raw orelse return false));
            if (self.completion_count >= self.completions.len) return false;
            self.completions[self.completion_count] = completion;
            self.completion_count += 1;
            return switch (completion.role) {
                .content => completion.status == 200 and std.mem.eql(u8, completion.body, "PNG"),
                .css_background => (completion.status == 0 and std.mem.indexOf(u8, completion.body, "<svg") != null) or
                    (completion.status == 200 and std.mem.eql(u8, completion.body, "BG")),
            };
        }

        fn report(raw: ?*anyopaque, event: ResourceEvent) void {
            const self: *@This() = @ptrCast(@alignCast(raw orelse return));
            if (self.event_count >= self.events.len) return;
            self.events[self.event_count] = event;
            self.event_count += 1;
        }
    };
    const harness = try allocator.create(Harness);
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    harness.completion_count = 0;
    harness.event_count = 0;
    _ = try harness.document.parse(
        "<body><img id='mixed' src='/content.png'><script>let imageErrors=0;" ++
            "document.getElementById('mixed').addEventListener('error',()=>imageErrors++);</script></body>",
        .{ .content_type = "text/html" },
    );
    const node = harness.document.findElementById("mixed").?;
    harness.web.setResourceHandler(.{ .context = harness, .complete = Harness.complete });
    harness.web.setResourceObserver(.{ .context = harness, .report = Harness.report });
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://page.example/path/index.html", "img-src * data:", 63, 0);
    _ = try harness.web.executeDocumentScripts();

    const first_stats = try harness.web.syncCssImages(&.{.{
        .node = node,
        .raw_value = "image-set(url('../icons/one.png') 1x, url('../icons/two.png') 2x)",
        .base_url = "https://cdn.example/css/site.css",
    }});
    try std.testing.expectEqual(@as(usize, 1), first_stats.selected);
    const content_request = harness.web.takeRequest().?;
    try std.testing.expectEqualStrings("https://page.example/content.png", content_request.url.bytes());
    const stale_css_request = harness.web.takeRequest().?;
    try std.testing.expectEqualStrings("https://cdn.example/icons/one.png", stale_css_request.url.bytes());
    try std.testing.expect(harness.web.takeRequest() == null);

    const embedded_stats = try harness.web.syncCssImages(&.{.{
        .node = node,
        .raw_value = "url('data:image/svg+xml,%3Csvg%20viewBox=%220%200%201%201%22%3E%3Cpath%20d=%22M0%200L1%201%22/%3E%3C/svg%3E')",
    }});
    try std.testing.expectEqual(@as(usize, 1), embedded_stats.selected);
    try std.testing.expectError(error.RequestState, harness.web.completeRequest(
        stale_css_request.id,
        stale_css_request.generation,
        .{ .status = 200, .secure = true, .content_type = "image/png" },
        "OLD",
    ));
    try harness.web.completeRequest(
        content_request.id,
        content_request.generation,
        .{ .status = 200, .secure = true, .content_type = "image/png" },
        "PNG",
    );
    try std.testing.expectEqual(@as(usize, 2), harness.completion_count);
    try std.testing.expectEqual(ImageRole.css_background, harness.completions[0].role);
    try std.testing.expectEqual(ImageRole.content, harness.completions[1].role);

    const failed_stats = try harness.web.syncCssImages(&.{.{
        .node = node,
        .raw_value = "linear-gradient(red, blue)",
    }});
    try std.testing.expectEqual(@as(usize, 1), failed_stats.failed);
    const error_count = try harness.web.executeSource("String(imageErrors)");
    try std.testing.expectEqualStrings("0", harness.web.runtime.valueString(error_count));
    var saw_css_selection_failure = false;
    for (harness.events[0..harness.event_count]) |event| {
        if (event.role == .css_background and event.phase == .failed and event.failure == .selection) {
            saw_css_selection_failure = true;
            break;
        }
    }
    try std.testing.expect(saw_css_selection_failure);

    const final_stats = try harness.web.syncCssImages(&.{.{
        .node = node,
        .raw_value = "url('../icons/final.png')",
        .base_url = "https://cdn.example/css/site.css",
    }});
    try std.testing.expectEqual(@as(usize, 1), final_stats.selected);
    const final_request = harness.web.takeRequest().?;
    try std.testing.expectEqualStrings("https://cdn.example/icons/final.png", final_request.url.bytes());
    try harness.web.completeRequest(
        final_request.id,
        final_request.generation,
        .{ .status = 200, .secure = true, .content_type = "image/png" },
        "BG",
    );
    try std.testing.expectEqual(@as(usize, 3), harness.completion_count);
    try std.testing.expectEqual(ImageRole.css_background, harness.completions[2].role);
    try std.testing.expect(harness.web.resourcesSettled());

    const retired = try harness.web.syncCssImages(&.{});
    try std.testing.expectEqual(@as(usize, 1), retired.retired);
    try std.testing.expect(harness.web.resourcesSettled());
}

test "responsive image reselection replaces requests rejects late completions and emits one terminal error" {
    const allocator = std.testing.allocator;
    const Harness = struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
        completion_urls: [8]navigation.Url = [_]navigation.Url{.{}} ** 8,
        completion_count: usize = 0,
        replaced_count: usize = 0,

        fn complete(raw: ?*anyopaque, completion: ResourceCompletion) bool {
            const self: *@This() = @ptrCast(@alignCast(raw orelse return false));
            if (completion.kind != .image or completion.status != 200 or self.completion_count >= self.completion_urls.len) return false;
            self.completion_urls[self.completion_count] = completion.requested_url;
            self.completion_count += 1;
            return std.mem.eql(u8, completion.content_type, "image/png") and std.mem.eql(u8, completion.body, "PNG");
        }

        fn report(raw: ?*anyopaque, event: ResourceEvent) void {
            const self: *@This() = @ptrCast(@alignCast(raw orelse return));
            if (event.phase == .replaced) self.replaced_count += 1;
        }
    };
    const SavedRequest = struct { id: u32, generation: u32 };
    const harness = try allocator.create(Harness);
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    harness.completion_count = 0;
    harness.replaced_count = 0;
    harness.web.setEnvironment(.{ .viewport_width = 800, .viewport_height = 600 });
    harness.web.setResourceHandler(.{ .context = harness, .complete = Harness.complete });
    harness.web.setResourceObserver(.{ .context = harness, .report = Harness.report });
    _ = try harness.document.parse(
        "<picture><source id='choice' media='(min-width:600px)' type='image/png' srcset='wide.png'>" ++
            "<img id='hero' src='narrow.png'></picture>" ++
            "<img id='responsive' src='fallback.png' srcset='small.png 320w, large.png 800w' sizes='(max-width:500px) 320px, 800px'>" ++
            "<script>let imageErrors=0;document.getElementById('hero').addEventListener('error',()=>imageErrors++);" ++
            "document.getElementById('responsive').addEventListener('error',()=>imageErrors++);</script>",
        .{ .content_type = "text/html" },
    );
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://resource.example/index", "", 62, 0);
    _ = try harness.web.executeDocumentScripts();

    const old_picture_ptr = harness.web.takeRequest().?;
    try std.testing.expectEqualStrings("https://resource.example/wide.png", old_picture_ptr.url.bytes());
    const old_picture = SavedRequest{ .id = old_picture_ptr.id, .generation = old_picture_ptr.generation };
    const old_responsive_ptr = harness.web.takeRequest().?;
    try std.testing.expectEqualStrings("https://resource.example/large.png", old_responsive_ptr.url.bytes());
    const old_responsive = SavedRequest{ .id = old_responsive_ptr.id, .generation = old_responsive_ptr.generation };

    harness.web.setViewport(400, 600);
    try std.testing.expectEqual(@as(usize, 2), harness.replaced_count);
    try std.testing.expectError(error.RequestNotFound, harness.web.completeRequest(old_picture.id, old_picture.generation, .{ .status = 200, .secure = true, .content_type = "image/png" }, "OLD"));
    try std.testing.expectError(error.RequestNotFound, harness.web.completeRequest(old_responsive.id, old_responsive.generation, .{ .status = 200, .secure = true, .content_type = "image/png" }, "OLD"));

    const narrow = harness.web.takeRequest().?;
    try std.testing.expectEqualStrings("https://resource.example/narrow.png", narrow.url.bytes());
    const small = harness.web.takeRequest().?;
    try std.testing.expectEqualStrings("https://resource.example/small.png", small.url.bytes());
    try harness.web.completeRequest(narrow.id, narrow.generation, .{ .status = 200, .secure = true, .content_type = "image/png" }, "PNG");
    try harness.web.completeRequest(small.id, small.generation, .{ .status = 200, .secure = true, .content_type = "image/png" }, "PNG");
    try std.testing.expectEqual(@as(usize, 2), harness.completion_count);

    _ = try harness.web.executeSource("document.getElementById('choice').setAttribute('media','(max-width:500px)')");
    const picture_source = harness.web.takeRequest().?;
    try std.testing.expectEqualStrings("https://resource.example/wide.png", picture_source.url.bytes());
    try harness.web.completeRequest(picture_source.id, picture_source.generation, .{ .status = 200, .secure = true, .content_type = "image/png" }, "PNG");

    _ = try harness.web.executeSource("const responsive=document.getElementById('responsive');responsive.src='direct.png';responsive.removeAttribute('srcset')");
    const direct = harness.web.takeRequest().?;
    try std.testing.expectEqualStrings("https://resource.example/direct.png", direct.url.bytes());
    try harness.web.completeRequest(direct.id, direct.generation, .{ .status = 200, .secure = true, .content_type = "image/png" }, "PNG");

    _ = try harness.web.executeSource("document.getElementById('responsive').setAttribute('srcset','small.png 320w, large.png 800w')");
    const before_sizes_ptr = harness.web.takeRequest().?;
    try std.testing.expectEqualStrings("https://resource.example/small.png", before_sizes_ptr.url.bytes());
    const before_sizes = SavedRequest{ .id = before_sizes_ptr.id, .generation = before_sizes_ptr.generation };
    _ = try harness.web.executeSource("document.getElementById('responsive').setAttribute('sizes','800px')");
    try std.testing.expectError(error.RequestNotFound, harness.web.completeRequest(before_sizes.id, before_sizes.generation, .{ .status = 200, .secure = true, .content_type = "image/png" }, "OLD"));
    const after_sizes = harness.web.takeRequest().?;
    try std.testing.expectEqualStrings("https://resource.example/large.png", after_sizes.url.bytes());
    try harness.web.completeRequest(after_sizes.id, after_sizes.generation, .{ .status = 200, .secure = true, .content_type = "image/png" }, "PNG");

    _ = try harness.web.executeSource("document.getElementById('choice').setAttribute('srcset','missing.png')");
    const missing = harness.web.takeRequest().?;
    const completions_before_error = harness.completion_count;
    try harness.web.completeRequest(missing.id, missing.generation, .{ .status = 404, .secure = true, .content_type = "image/png" }, "not an image");
    try std.testing.expectEqual(completions_before_error, harness.completion_count);
    try harness.web.failRequest(missing.id, missing.generation, "duplicate terminal failure");
    const error_count = try harness.web.executeSource("String(imageErrors)");
    try std.testing.expectEqualStrings("1", harness.web.runtime.valueString(error_count));
    try std.testing.expect(harness.web.resourcesSettled());
}

test "document resource observer reports bounded lifecycle response failures abort and replacement" {
    const allocator = std.testing.allocator;
    const Harness = struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
        events: [24]ResourceEvent = undefined,
        event_count: usize = 0,
        completion_count: usize = 0,
        completion_valid: bool = false,
        completion_resource_id: u32 = 0,

        fn report(raw: ?*anyopaque, event: ResourceEvent) void {
            const self: *@This() = @ptrCast(@alignCast(raw orelse return));
            if (self.event_count >= self.events.len) return;
            self.events[self.event_count] = event;
            self.event_count += 1;
        }

        fn complete(raw: ?*anyopaque, completion: ResourceCompletion) bool {
            const self: *@This() = @ptrCast(@alignCast(raw orelse return false));
            self.completion_count += 1;
            self.completion_resource_id = completion.resource_id;
            self.completion_valid = completion.status == 200 and
                completion.resource_id != 0 and completion.role == .content and
                completion.redirected and
                completion.byte_count == 3 and
                std.mem.eql(u8, completion.requested_url.bytes(), "https://resource.example/mark.png") and
                std.mem.eql(u8, completion.final_url.bytes(), "https://cdn.example/mark.png") and
                std.mem.eql(u8, completion.url.bytes(), completion.final_url.bytes()) and
                std.mem.eql(u8, completion.content_type, "image/png") and
                std.mem.eql(u8, completion.body, "PNG");
            return self.completion_valid;
        }
    };
    const harness = try allocator.create(Harness);
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    harness.event_count = 0;
    harness.completion_count = 0;
    harness.completion_valid = false;
    harness.completion_resource_id = 0;
    harness.web.setResourceObserver(.{ .context = harness, .report = Harness.report });
    harness.web.setResourceHandler(.{ .context = harness, .complete = Harness.complete });

    _ = try harness.document.parse("<body><img src='/mark.png'></body>", .{ .content_type = "text/html" });
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://resource.example/index", "", 51, 0);
    _ = try harness.web.executeDocumentScripts();
    try std.testing.expectEqualSlices(ResourcePhase, &.{ .selected, .queued }, &.{ harness.events[0].phase, harness.events[1].phase });
    const success = harness.web.takeRequest().?;
    try std.testing.expectEqual(ResourcePhase.fetching, harness.events[2].phase);
    try harness.web.completeRequest(success.id, success.generation, .{
        .status = 200,
        .secure = true,
        .content_type = "image/png",
        .redirected = true,
        .final_url = "https://cdn.example/mark.png",
    }, "PNG");
    try std.testing.expectEqual(@as(usize, 5), harness.event_count);
    try std.testing.expectEqual(ResourcePhase.response, harness.events[3].phase);
    try std.testing.expectEqual(ResourcePhase.ready, harness.events[4].phase);
    try std.testing.expectEqual(harness.events[4].resource_id, harness.completion_resource_id);
    try std.testing.expectEqual(ImageRole.content, harness.events[4].role);
    try std.testing.expectEqualStrings("https://resource.example/mark.png", harness.events[3].requested_url.bytes());
    try std.testing.expectEqualStrings("https://cdn.example/mark.png", harness.events[3].final_url.bytes());
    try std.testing.expectEqual(@as(u16, 200), harness.events[3].status);
    try std.testing.expect(harness.events[3].redirected);
    try std.testing.expectEqualStrings("image/png", harness.events[3].content_type.bytes());
    try std.testing.expectEqual(@as(usize, 3), harness.events[3].byte_count);
    try std.testing.expectEqual(@as(usize, 1), harness.completion_count);
    try std.testing.expect(harness.completion_valid);

    harness.event_count = 0;
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://resource.example/not-found", "", 52, 0);
    _ = try harness.web.executeDocumentScripts();
    const not_found = harness.web.takeRequest().?;
    try harness.web.completeRequest(not_found.id, not_found.generation, .{
        .status = 404,
        .secure = true,
        .content_type = "image/png",
    }, "bad");
    try std.testing.expectEqual(ResourcePhase.response, harness.events[3].phase);
    try std.testing.expectEqual(@as(u16, 404), harness.events[3].status);
    try std.testing.expectEqual(ResourcePhase.failed, harness.events[4].phase);
    try std.testing.expectEqual(ResourceFailure.http_status, harness.events[4].failure);
    try std.testing.expectEqual(@as(usize, 1), harness.completion_count);
    try std.testing.expect(harness.web.resourcesSettled());

    harness.event_count = 0;
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://resource.example/fetch-error", "", 53, 0);
    _ = try harness.web.executeDocumentScripts();
    const failed = harness.web.takeRequest().?;
    try harness.web.failRequest(failed.id, failed.generation, "Connection failed");
    try std.testing.expectEqual(ResourcePhase.failed, harness.events[3].phase);
    try std.testing.expectEqual(ResourceFailure.fetch, harness.events[3].failure);
    try std.testing.expect(harness.web.resourcesSettled());

    harness.event_count = 0;
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://resource.example/abort", "", 54, 0);
    _ = try harness.web.executeDocumentScripts();
    _ = harness.web.takeRequest().?;
    harness.web.abortDocument();
    try std.testing.expectEqual(ResourcePhase.aborted, harness.events[3].phase);
    try std.testing.expectEqual(@as(u32, 54), harness.events[3].generation);
    try std.testing.expect(harness.web.resourcesSettled());

    harness.event_count = 0;
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://resource.example/old", "", 55, 0);
    _ = try harness.web.executeDocumentScripts();
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://resource.example/new", "", 56, 0);
    try std.testing.expectEqual(ResourcePhase.replaced, harness.events[2].phase);
    try std.testing.expectEqual(@as(u32, 55), harness.events[2].generation);
    try std.testing.expectEqualStrings("https://resource.example/mark.png", harness.events[2].requested_url.bytes());
}

test "oversized document resources fail terminally instead of leaving the queue fetching" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    _ = try harness.document.parse("<body><img src='/large.png'></body>", .{ .content_type = "text/html" });
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://resource.example/index", "", 31, 0);
    _ = try harness.web.executeDocumentScripts();
    const request = harness.web.takeRequest().?;
    const oversized = try allocator.alloc(u8, max_response_body_bytes + 1);
    defer allocator.free(oversized);
    @memset(oversized, 0xAA);
    try std.testing.expectError(
        error.ResponseTooLarge,
        harness.web.completeRequest(request.id, request.generation, .{ .status = 200, .secure = true, .content_type = "image/png" }, oversized),
    );
    try std.testing.expect(harness.web.resourcesSettled());
}

test "module resources fetch register and evaluate a relative cyclic dependency graph" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    _ = try harness.document.parse("<body><script type=module src='/app/main.js'></script></body>", .{ .content_type = "text/html" });
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://modules.example/index.html", "script-src 'self'", 22, 0);
    try std.testing.expectEqual(@as(usize, 0), try harness.web.executeDocumentScripts());

    const root = harness.web.takeRequest().?;
    try std.testing.expectEqualStrings("https://modules.example/app/main.js", root.url.bytes());
    try harness.web.completeRequest(root.id, root.generation, .{ .status = 200, .secure = true }, "import {value} from './dep.js';export const result=value+2;");
    try std.testing.expect(!harness.web.resourcesSettled());

    const dependency = harness.web.takeRequest().?;
    try std.testing.expectEqualStrings("https://modules.example/app/dep.js", dependency.url.bytes());
    try harness.web.completeRequest(dependency.id, dependency.generation, .{ .status = 200, .secure = true }, "import './main.js';export {value} from './nested.js';");

    const nested = harness.web.takeRequest().?;
    try std.testing.expectEqualStrings("https://modules.example/app/nested.js", nested.url.bytes());
    try harness.web.completeRequest(nested.id, nested.generation, .{ .status = 200, .secure = true }, "export const value=40;");
    try std.testing.expect(harness.web.resourcesSettled());
    try std.testing.expectEqual(@as(usize, 0), harness.web.script_error_count);
    const namespace = try harness.web.runtime.evaluateModule("https://modules.example/app/main.js");
    try std.testing.expectEqual(@as(f64, 42), try harness.web.runtime.valueNumber(try harness.web.runtime.get(namespace, "result")));
}

test "iframe views expose stable same-origin proxies and block cross-origin documents" {
    const allocator = std.testing.allocator;
    const Harness = struct {
        document: html.Document,
        child_document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
        same_node: u16 = html.none,

        fn inspect(raw: ?*anyopaque, _: security.Origin, generation: u32, node: u16) ?FrameInfo {
            const self: *@This() = @ptrCast(@alignCast(raw orelse return null));
            if (generation != 31) return null;
            return if (node == self.same_node)
                .{ .url = navigation.parse("https://parent.example/frame") catch return null, .same_origin = true, .complete = true, .document = &self.child_document }
            else
                .{ .url = navigation.parse("https://other.example/frame") catch return null, .same_origin = false, .complete = true };
        }
    };
    const harness = try allocator.create(Harness);
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    _ = try harness.document.parse("<body><iframe id=same></iframe><iframe id=cross></iframe></body>", .{ .content_type = "text/html" });
    _ = try harness.child_document.parse("<html><head><title>Child</title></head><body><div id=inside>before</div></body></html>", .{ .content_type = "text/html" });
    harness.same_node = harness.document.findElementById("same").?;
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://parent.example/", "", 31, 0);
    harness.web.setFrameLookup(.{ .context = harness, .inspect = Harness.inspect });
    const value = try harness.web.executeSource(
        "const same=document.getElementById('same');const cross=document.getElementById('cross');" ++
            "const inside=same.contentDocument.getElementById('inside');const stable=inside===same.contentDocument.querySelector('#inside');" ++
            "inside.textContent='changed';inside.setAttribute('data-live','yes');let blocked=false;try{cross.contentWindow.document;}catch(reason){blocked=reason instanceof TypeError;}" ++
            "[same.contentDocument.URL,same.contentDocument.readyState,same.contentWindow===same.contentWindow,same.contentWindow.location," ++
            "same.contentDocument.title,inside.nodeName,inside.tagName,inside.textContent,inside.getAttribute('data-live'),stable," ++
            "cross.contentDocument===null,cross.contentWindow===cross.contentWindow,blocked].join('|');",
    );
    try std.testing.expectEqualStrings("https://parent.example/frame|complete|true|https://parent.example/frame|Child|div|DIV|changed|yes|true|true|true|true", harness.web.runtime.valueString(value));
    const inside = harness.child_document.findElementById("inside").?;
    try std.testing.expectEqualStrings("changed", try harness.child_document.textContent(inside, harness.web.script_scratch[0..]));
}

test "browser environment reflects injected R4OS properties without spoofing" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    harness.web.setEnvironment(.{
        .viewport_width = 640,
        .viewport_height = 480,
        .screen_width = 1920,
        .screen_height = 1080,
        .color_depth = 24,
        .hardware_concurrency = 4,
        .online = true,
        .language = "de-DE",
        .user_agent = "Klickifax/0.20 R4OS",
        .platform = "R4OS x86_64",
    });
    _ = try harness.document.parse("<body></body>", .{ .content_type = "text/html" });
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://environment.example/", "", 41, 0);
    const value = try harness.web.executeSource(
        "[navigator.userAgent,navigator.platform,navigator.language,navigator.languages.join(','),navigator.onLine," ++
            "navigator.hardwareConcurrency,navigator.maxTouchPoints,screen.width,screen.height,screen.colorDepth," ++
            "window.innerWidth,window.innerHeight,window.outerWidth,window.outerHeight,window.devicePixelRatio,navigator.webdriver,navigator.supports('canvas')].join('|');",
    );
    try std.testing.expectEqualStrings("Klickifax/0.20 R4OS|R4OS x86_64|de-DE|de-DE|true|4|0|1920|1080|24|640|480|640|480|1|false|false", harness.web.runtime.valueString(value));
    harness.web.setViewport(800, 600);
    const resized = try harness.web.executeSource("window.innerWidth+'x'+window.innerHeight+'|'+window.outerWidth+'x'+window.outerHeight;");
    try std.testing.expectEqualStrings("800x600|800x600", harness.web.runtime.valueString(resized));
}

test "document readyState follows parsing and load lifecycle" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    _ = try harness.document.parse(
        "<!doctype html><body><script>globalThis.readyDuringScript=document.readyState;</script></body>",
        .{ .content_type = "text/html" },
    );
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://lifecycle.example/", "", 42, 0);
    try harness.web.ensureJavascriptRealm();
    const document_object = harness.web.runtime.global("document").?;
    try std.testing.expectEqualStrings("loading", harness.web.runtime.valueString(try harness.web.runtime.get(document_object, "readyState")));
    try std.testing.expectEqual(@as(usize, 1), try harness.web.executeDocumentScripts());
    const global_object = harness.web.runtime.global("globalThis").?;
    try std.testing.expectEqualStrings("loading", harness.web.runtime.valueString(try harness.web.runtime.get(global_object, "readyDuringScript")));
    try std.testing.expectEqualStrings("interactive", harness.web.runtime.valueString(try harness.web.runtime.get(document_object, "readyState")));
    harness.web.markLoadStart(1);
    try std.testing.expectEqualStrings("complete", harness.web.runtime.valueString(try harness.web.runtime.get(document_object, "readyState")));
}

test "Web Crypto digests BufferSource and reports entropy availability honestly" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    _ = try harness.document.parse("<body></body>", .{ .content_type = "text/html" });
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://crypto.example/", "", 42, 0);
    _ = try harness.web.executeSource(
        "const input=new TextEncoder().encode('abc');let digestHex='';" ++
            "crypto.subtle.digest({name:'SHA-256'},input).then(bytes=>{digestHex=Array.from(new Uint8Array(bytes)).map(value=>value.toString(16).padStart(2,'0')).join('');});" ++
            "let cryptoAdvertised=navigator.supports('crypto');",
    );
    _ = try harness.web.pump(0, 32);
    try std.testing.expectEqualStrings("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", harness.web.runtime.valueString(harness.web.runtime.global("digestHex").?));
    const advertised = harness.web.runtime.valueBoolean(harness.web.runtime.global("cryptoAdvertised").?);
    try std.testing.expectEqual(web_crypto.secureEntropyAvailable(), advertised);
    if (advertised) {
        const value = try harness.web.executeSource("const values=new Uint16Array(8);crypto.getRandomValues(values);const uuid=crypto.randomUUID();values.some(value=>value!==0)&&/^[-0-9a-f]{36}$/.test(uuid)&&uuid[14]==='4'&&'89ab'.includes(uuid[19]);");
        try std.testing.expect(harness.web.runtime.valueBoolean(value));
    }
}

test "Canvas 2D keeps bounded pixels paths text and transforms outside graphics drivers" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    _ = try harness.document.parse("<!doctype html><canvas id='c' width='20' height='10'></canvas>", .{ .content_type = "text/html" });
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://canvas.example/", "", 43, 0);
    const result = try harness.web.executeSource("const c=document.getElementById('c');const x=c.getContext('2d');x.fillStyle='#f00';x.fillRect(1,2,3,4);const image=x.getImageData(1,2,1,1);x.putImageData(image,8,1);x.strokeStyle='#00f';x.beginPath();x.moveTo(0,0);x.lineTo(4,4);x.stroke();x.translate(2,1);x.fillText('R4',1,2);[c.width,c.height,x.fillStyle,x.strokeStyle,image.data.length].join('|');");
    try std.testing.expectEqualStrings("20|10|#ff0000|#0000ff|4", harness.web.runtime.valueString(result));
    const node = harness.document.findElementById("c").?;
    const surface = harness.web.canvasView(node).?;
    try std.testing.expectEqual(@as(u32, 20), surface.width);
    try std.testing.expectEqual(@as(u32, 10), surface.height);
    try std.testing.expectEqual(@as(u32, 0xFF0000), surface.pixels[2 * surface.width + 1]);
    try std.testing.expectEqual(@as(u32, 0xFF0000), surface.pixels[1 * surface.width + 8]);
    try std.testing.expectEqual(@as(usize, 1), surface.text_ops.len);
    try std.testing.expectEqualStrings("R4", surface.text_ops[0].text());
}

test "offline browser fixtures exercise layout scripts forms frames and resources" {
    const fixture_allocator = std.testing.allocator;
    const layout_fixture = try std.Io.Dir.cwd().readFileAlloc(std.testing.io, "Tests/Fixture/Browser/Layout06228.html", fixture_allocator, .limited(16 * 1024));
    defer fixture_allocator.free(layout_fixture);
    const script_fixture = try std.Io.Dir.cwd().readFileAlloc(std.testing.io, "Tests/Fixture/Browser/Script06228.html", fixture_allocator, .limited(16 * 1024));
    defer fixture_allocator.free(script_fixture);
    const forms_fixture = try std.Io.Dir.cwd().readFileAlloc(std.testing.io, "Tests/Fixture/Browser/Forms06228.html", fixture_allocator, .limited(16 * 1024));
    defer fixture_allocator.free(forms_fixture);
    const frame_fixture = try std.Io.Dir.cwd().readFileAlloc(std.testing.io, "Tests/Fixture/Browser/Frame06228.html", fixture_allocator, .limited(16 * 1024));
    defer fixture_allocator.free(frame_fixture);
    const resources_fixture = try std.Io.Dir.cwd().readFileAlloc(std.testing.io, "Tests/Fixture/Browser/Resources06228.html", fixture_allocator, .limited(16 * 1024));
    defer fixture_allocator.free(resources_fixture);

    var layout_document = html.Document{};
    _ = try layout_document.parse(layout_fixture, .{ .content_type = "text/html" });
    var sheet = css.Stylesheet{};
    try sheet.appendDocumentStyles(&layout_document);
    var layout = @import("web_layout.zig").Layout{};
    const layout_stats = try layout.reflow(&layout_document, &sheet, .{ .width = 480, .height = 240 });
    try std.testing.expect(layout_stats.render_ops >= 2);
    try std.testing.expect(layout_stats.render_ops <= 64);
    try std.testing.expect(layout_document.node_count <= 32);

    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    _ = try harness.document.parse(script_fixture, .{ .content_type = "text/html" });
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://fixture.example/script", "", 44, 0);
    try std.testing.expectEqual(@as(usize, 1), try harness.web.executeDocumentScripts());
    try std.testing.expect(harness.web.runtime.stats.steps <= 4_096);
    try std.testing.expect(harness.web.runtime.stats.peak_cells <= 2_048);
    const script_result = try harness.web.executeSource("const r=document.getElementById('result');[r.textContent,r.getAttribute('data-ran')].join('|');");
    try std.testing.expectEqualStrings("offline-script-ok|yes", harness.web.runtime.valueString(script_result));

    var forms_document = html.Document{};
    _ = try forms_document.parse(forms_fixture, .{ .content_type = "text/html" });
    const form = forms_document.findFirstElement("form").?;
    const input = forms_document.findFirstElement("input").?;
    try std.testing.expectEqualStrings("/search", forms_document.attribute(form, "action").?);
    try std.testing.expectEqualStrings("R4OS", forms_document.attribute(input, "value").?);
    var form_interaction = @import("web_forms.zig").Interaction{};
    try form_interaction.rebuild(&forms_document);
    const submitter = forms_document.findFirstElement("button").?;
    const submit_control = form_interaction.controlForNodeConst(submitter).?;
    try std.testing.expectEqualStrings("search", submit_control.value());
    try std.testing.expectEqualStrings("Search", submit_control.displayValue());
    const form_base = try navigation.parse("https://fixture.example/base");
    var form_target: [256]u8 = undefined;
    var form_body: [256]u8 = undefined;
    const form_submission = try form_interaction.submit(&forms_document, submitter, &form_base, form_target[0..], form_body[0..]);
    try std.testing.expectEqual(@import("web_forms.zig").SubmissionMethod.get, form_submission.method);
    try std.testing.expectEqualStrings("https://fixture.example/search?q=R4OS&safe=on&lang=de&submit=search", form_submission.target);

    var frame_document = html.Document{};
    _ = try frame_document.parse(frame_fixture, .{ .content_type = "text/html" });
    const iframe = frame_document.findFirstElement("iframe").?;
    try std.testing.expectEqual(web_resources.Kind.subdocument, web_resources.resourceKind(&frame_document, iframe).?);
    try std.testing.expect(std.mem.indexOf(u8, frame_document.attribute(iframe, "srcdoc").?, "offline-frame") != null);

    var resources_document = html.Document{};
    _ = try resources_document.parse(resources_fixture, .{ .content_type = "text/html" });
    var stylesheet_count: usize = 0;
    var image_count: usize = 0;
    var script_count: usize = 0;
    for (resources_document.nodes[0..resources_document.node_count], 0..) |node, index| {
        if (node.kind != .element) continue;
        switch (web_resources.resourceKind(&resources_document, @intCast(index)) orelse continue) {
            .stylesheet => stylesheet_count += 1,
            .image => image_count += 1,
            .script => script_count += 1,
            .subdocument => {},
            .font => {},
        }
    }
    try std.testing.expectEqual(@as(usize, 1), stylesheet_count);
    try std.testing.expectEqual(@as(usize, 1), image_count);
    try std.testing.expectEqual(@as(usize, 1), script_count);
}

test "repeated offline navigations release realms canvas buffers and pending work" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();

    var generation: u32 = 100;
    while (generation < 164) : (generation += 1) {
        harness.document.reset();
        _ = try harness.document.parse(
            "<!doctype html><body><canvas id='c' width='32' height='16'></canvas><script>" ++
                "const x=document.getElementById('c').getContext('2d');x.fillStyle='#00f';x.fillRect(0,0,32,16);</script></body>",
            .{ .content_type = "text/html" },
        );
        try harness.web.beginDocument(&harness.document, &harness.storage, "https://fixture.example/session", "", generation, @floatFromInt(generation));
        try std.testing.expectEqual(@as(usize, 1), try harness.web.executeDocumentScripts());
        _ = try harness.web.pump(@floatFromInt(generation), 16);
        const canvas = harness.document.findElementById("c").?;
        try std.testing.expect(harness.web.canvasView(canvas) != null);
        harness.web.abortDocument();
        try std.testing.expect(harness.web.canvasView(canvas) == null);
        try std.testing.expect(harness.web.takeRequest() == null);
        try std.testing.expect(harness.web.takeAction() == null);
    }
}

test "URL and URLSearchParams stay live ordered iterable and form encoded" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    _ = try harness.document.parse("<!doctype html><body></body>", .{ .content_type = "text/html" });
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://runtime.example/base/index.html", "default-src 'self'", 1, 0);

    const value = try harness.web.executeSource(
        "const url=new URL('../next?b=2&a=1&a=3#old','https://Example.com/base/index.html');" ++
            "const same=url.searchParams===url.searchParams;url.searchParams.append('space key','a+b');url.searchParams.set('b','4');" ++
            "url.searchParams.delete('a','3');url.searchParams.sort();url.hash='done';" ++
            "const first=[url.href,url.origin,url.protocol,url.hostname,url.pathname,url.search,url.hash,url.searchParams.size,Array.from(url.searchParams.keys()).join(','),same].join('|');" ++
            "let visited='';url.searchParams.forEach((value,name)=>visited+=name+value);" ++
            "url.search='?x=1&x=2';const standalone=new URLSearchParams('q=hello+world&q=two');" ++
            "let direct='';for(const [name,value] of standalone){direct+=name+':'+value+';';}" ++
            "const parsed=URL.parse('/ok?yes=1','https://parse.example/base');" ++
            "first+'|'+visited+'|'+url.searchParams.getAll('x').join(',')+'|'+standalone.get('q')+'|'+Array.from(standalone.values()).join(',')+'|'+direct+'|'+URL.canParse('/ok','https://parse.example/')+'|'+(URL.parse('http://')===null)+'|'+parsed.href+'|'+String(url);",
    );
    try std.testing.expectEqualStrings(
        "https://example.com/next?a=1&b=4&space+key=a%2Bb#done|https://example.com|https:|example.com|/next|?a=1&b=4&space+key=a%2Bb|#done|3|a,b,space key|true|a1b4space keya+b|1,2|hello world|hello world,two|q:hello world;q:two;|true|true|https://parse.example/ok?yes=1|https://example.com/next?x=1&x=2#done",
        harness.web.runtime.valueString(value),
    );
}

test "TextEncoder exposes WebIDL metadata USVString conversion and bounded writes" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    _ = try harness.document.parse("<!doctype html><body></body>", .{ .content_type = "text/html" });
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://runtime.example/", "default-src 'self'", 1, 0);

    const value = try harness.web.executeSource(
        "const encoder=new TextEncoder();const encoded=encoder.encode('A\\u20ac\\ud83d\\ude00');" ++
            "const repaired=encoder.encode(String.fromCharCode(0xd800));const target=new Uint8Array(4);" ++
            "const progress=encoder.encodeInto('A\\u20ac\\ud83d\\ude00',target);" ++
            "let callError=false;try{TextEncoder();}catch(reason){callError=reason instanceof TypeError;}" ++
            "let brandError=false;try{TextEncoder.prototype.encode.call({});}catch(reason){brandError=reason instanceof TypeError;}" ++
            "[encoder.encoding,encoder instanceof TextEncoder,Object.prototype.toString.call(encoder),TextEncoder.length," ++
            "TextEncoder.prototype.encode.length,TextEncoder.prototype.encodeInto.length," ++
            "Object.getOwnPropertyDescriptor(TextEncoder.prototype,'encoding').set===undefined," ++
            "Array.from(encoded).join(','),Array.from(repaired).join(','),progress.read,progress.written,Array.from(target).join(','),callError,brandError].join('|');",
    );
    try std.testing.expectEqualStrings(
        "utf-8|true|[object TextEncoder]|0|0|2|true|65,226,130,172,240,159,152,128|239,191,189|2|4|65,226,130,172|true|true",
        harness.web.runtime.valueString(value),
    );
}

test "TextDecoder handles BufferSource labels BOM fatal errors and streaming state" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    _ = try harness.document.parse("<!doctype html><body></body>", .{ .content_type = "text/html" });
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://runtime.example/", "default-src 'self'", 1, 0);

    const value = try harness.web.executeSource(
        "const decoder=new TextDecoder();const direct=decoder.decode(new Uint8Array([226,130,172]));" ++
            "const backing=new Uint8Array([0,226,130,172,0]);const view=new DataView(backing.buffer,1,3);const viewed=decoder.decode(view);" ++
            "const streamed=new TextDecoder();const first=streamed.decode(new Uint8Array([226,130]),{stream:true});" ++
            "const second=streamed.decode(new Uint8Array([172]),{stream:true});const flushed=streamed.decode();" ++
            "const replacement=decoder.decode(new Uint8Array([255]));" ++
            "const legacy=new TextDecoder(' latin1 ');const legacyText=legacy.decode(new Uint8Array([128,147]));" ++
            "const stripped=decoder.decode(new Uint8Array([239,187,191,65]));" ++
            "const kept=new TextDecoder('utf8',{ignoreBOM:true});const keptText=kept.decode(new Uint8Array([239,187,191,65]));" ++
            "let fatal=false;try{new TextDecoder('utf-8',{fatal:true}).decode(new Uint8Array([255]));}catch(reason){fatal=reason instanceof TypeError;}" ++
            "let label=false;try{new TextDecoder('utf-16');}catch(reason){label=reason instanceof RangeError;}" ++
            "let callError=false;try{TextDecoder();}catch(reason){callError=reason instanceof TypeError;}" ++
            "let brandError=false;try{TextDecoder.prototype.decode.call({});}catch(reason){brandError=reason instanceof TypeError;}" ++
            "[decoder.encoding,decoder.fatal,decoder.ignoreBOM,decoder instanceof TextDecoder,Object.prototype.toString.call(decoder)," ++
            "TextDecoder.length,TextDecoder.prototype.decode.length,direct,viewed,first,second,flushed,replacement,legacy.encoding,legacyText," ++
            "stripped,keptText.charCodeAt(0),keptText.charCodeAt(1),fatal,label,callError,brandError].join('|');",
    );
    try std.testing.expectEqualStrings(
        "utf-8|false|false|true|[object TextDecoder]|0|0|\xe2\x82\xac|\xe2\x82\xac||\xe2\x82\xac||\xef\xbf\xbd|windows-1252|\xe2\x82\xac\xe2\x80\x9c|A|65279|65|true|true|true|true",
        harness.web.runtime.valueString(value),
    );
}

test "Headers validates WebIDL initializers mutations iteration and brands" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    _ = try harness.document.parse("<!doctype html><body></body>", .{ .content_type = "text/html" });
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://runtime.example/", "default-src 'self'", 1, 0);

    const value = try harness.web.executeSource(
        "const headers=new Headers({B:' 2 ',a:'1'});headers.append('b','3');headers.append('Set-Cookie','a=1');headers.append('set-cookie','b=2');" ++
            "const before=headers.get('B');headers.set('A','final');const cookies=headers.getSetCookie().join(',');" ++
            "const clone=new Headers(headers);clone.delete('b');const sequence=new Headers([['X-Test','one'],['x-test','two']]);" ++
            "let visited='';headers.forEach((value,name)=>visited+=name+'='+value+';');const iterator=headers.keys();headers.set('z-last','yes');" ++
            "let invalid=false;try{headers.set('bad name','x');}catch(reason){invalid=reason instanceof TypeError;}" ++
            "let callError=false;try{Headers();}catch(reason){callError=reason instanceof TypeError;}" ++
            "let brandError=false;try{Headers.prototype.get.call({},'a');}catch(reason){brandError=reason instanceof TypeError;}" ++
            "[headers instanceof Headers,Object.prototype.toString.call(headers),Headers.length,Headers.prototype.append.length," ++
            "before,headers.get('a'),headers.has('b'),clone.has('b'),sequence.get('x-test'),cookies,Array.from(headers).map(pair=>pair.join(':')).join(',')," ++
            "visited,Array.from(iterator).join(','),invalid,callError,brandError].join('|');",
    );
    try std.testing.expectEqualStrings(
        "true|[object Headers]|0|2|2, 3|final|true|false|one, two|a=1,b=2|a:final,b:2, 3,set-cookie:a=1, b=2,z-last:yes|a=final;b=2, 3;set-cookie=a=1, b=2;|a,b,set-cookie,z-last|true|true|true",
        harness.web.runtime.valueString(value),
    );
}

test "Response owns cloneable bodies and returns real byte objects and reader chunks" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    _ = try harness.document.parse("<!doctype html><body></body>", .{ .content_type = "text/html" });
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://runtime.example/", "default-src 'self'", 1, 0);

    const value = try harness.web.executeSource(
        "const response=new Response('{\"ok\":true}',{status:201,statusText:'Created',headers:{'X-Test':'yes'}});" ++
            "const textClone=response.clone(),jsonClone=response.clone(),bytesClone=response.clone(),bufferClone=response.clone(),streamClone=response.clone();" ++
            "const errorResponse=Response.error(),redirectResponse=Response.redirect('/next',307),staticJson=Response.json({value:2});" ++
            "const reader=streamClone.body.getReader();const metadata=[response.status,response.ok,response.statusText,response.type,response.url,response.redirected,response.headers.get('x-test')," ++
            "response.headers.get('content-type'),response.bodyUsed,response.body.locked,reader instanceof Object,streamClone.body.locked,errorResponse.type,errorResponse.status," ++
            "redirectResponse.status,redirectResponse.headers.get('location'),staticJson.headers.get('content-type')].join(',');" ++
            "let text='',json=false,bytes='',buffer=0,chunk='',done=false,staticText='';" ++
            "textClone.text().then(value=>text=value);jsonClone.json().then(value=>json=value.ok);bytesClone.bytes().then(value=>bytes=Array.from(value).join(','));" ++
            "bufferClone.arrayBuffer().then(value=>buffer=value.byteLength);reader.read().then(part=>{chunk=new TextDecoder().decode(part.value);return reader.read();}).then(part=>done=part.done);" ++
            "staticJson.text().then(value=>staticText=value);" ++
            "metadata+'|'+Object.prototype.toString.call(response)+'|'+(response instanceof Response);",
    );
    try std.testing.expectEqualStrings(
        "201,true,Created,default,,false,yes,text/plain;charset=UTF-8,false,false,true,true,error,0,307,https://runtime.example/next,application/json|[object Response]|true",
        harness.web.runtime.valueString(value),
    );
    _ = try harness.web.pump(1, 64);
    try std.testing.expectEqualStrings("{\"ok\":true}", harness.web.runtime.valueString(harness.web.runtime.global("text").?));
    try std.testing.expect(harness.web.runtime.valueBoolean(harness.web.runtime.global("json").?));
    try std.testing.expectEqualStrings("123,34,111,107,34,58,116,114,117,101,125", harness.web.runtime.valueString(harness.web.runtime.global("bytes").?));
    try std.testing.expectEqual(@as(f64, 11), try harness.web.runtime.valueNumber(harness.web.runtime.global("buffer").?));
    try std.testing.expectEqualStrings("{\"ok\":true}", harness.web.runtime.valueString(harness.web.runtime.global("chunk").?));
    try std.testing.expect(harness.web.runtime.valueBoolean(harness.web.runtime.global("done").?));
    try std.testing.expectEqualStrings("{\"value\":2}", harness.web.runtime.valueString(harness.web.runtime.global("staticText").?));
}

test "Request preserves init body signal and transport state without visible host slots" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    harness.document.reset();
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://runtime.example/base/", "", 1, 0);

    const value = try harness.web.executeSource(
        "const controller=new AbortController();let abortEvents=0;controller.signal.addEventListener('abort',()=>abortEvents++);controller.signal.onabort=()=>abortEvents++;" ++
            "const source=new Request('/submit',{method:'post',headers:{'X-Test':'yes'},body:'payload',mode:'same-origin',credentials:'include',cache:'no-store',redirect:'manual',referrer:'',referrerPolicy:'origin',integrity:'sha256-demo',keepalive:1,signal:controller.signal});" ++
            "const clone=source.clone();const moved=new Request(clone);let movedText='';moved.text().then(value=>movedText=value);" ++
            "const outbound=new Request('/api',{method:'PUT',headers:[['Content-Type','application/json'],['X-Request','r4']],body:'{\"ok\":true}',mode:'same-origin',credentials:'omit'});fetch(outbound);" ++
            "globalThis.bodyController=new AbortController();globalThis.bodyResult='';fetch(new Request('/body',{signal:globalThis.bodyController.signal,mode:'no-cors'})).then(response=>globalThis.linkedResponse=response);" ++
            "let abortReason='';const aborting=new Request('/abort',{signal:controller.signal});fetch(aborting).catch(reason=>abortReason=reason);controller.abort('stopped');let thrown='';try{controller.signal.throwIfAborted();}catch(reason){thrown=reason;}" ++
            "let invalid=0;for(const action of [()=>Request('/'),()=>new Request('/',{method:'GET',body:'x'}),()=>new Request('/',{headers:{Host:'bad'}}),()=>new Request('/',{mode:'no-cors',headers:{'X-Test':'bad'}}),()=>new Request('/',{cache:'only-if-cached'})]){try{action();}catch(reason){if(reason instanceof TypeError)invalid++;}}" ++
            "[source.method,source.url,source.headers.get('x-test'),source.mode,source.credentials,source.cache,source.redirect,source.referrer,source.referrerPolicy,source.integrity,source.keepalive,source.duplex,source.bodyUsed," ++
            "clone.bodyUsed,moved instanceof Request,Object.prototype.toString.call(source),controller.signal.aborted,controller.signal.reason,abortEvents,thrown,invalid].join(',')",
    );
    try std.testing.expectEqualStrings(
        "POST,https://runtime.example/submit,yes,same-origin,include,no-store,manual,,origin,sha256-demo,true,half,false,true,true,[object Request],true,stopped,2,stopped,5",
        harness.web.runtime.valueString(value),
    );
    _ = try harness.web.pump(1, 64);
    try std.testing.expectEqualStrings("payload", harness.web.runtime.valueString(harness.web.runtime.global("movedText").?));
    try std.testing.expectEqualStrings("stopped", harness.web.runtime.valueString(harness.web.runtime.global("abortReason").?));
    const request = harness.web.takeRequest().?;
    try std.testing.expectEqual(http.Method.put, request.method);
    try std.testing.expectEqual(security.RequestMode.same_origin, request.mode);
    try std.testing.expectEqual(security.CredentialsMode.omit, request.credentials);
    try std.testing.expectEqualStrings("https://runtime.example/api", request.url.bytes());
    try std.testing.expectEqualStrings("content-type:application/json\nx-request:r4\n", request.requestHeaders());
    try std.testing.expectEqualStrings("{\"ok\":true}", request.bodyBytes());
    const body_request = harness.web.takeRequest().?;
    try std.testing.expectEqual(security.RequestMode.no_cors, body_request.mode);
    try harness.web.completeRequest(body_request.id, body_request.generation, .{ .status = 200, .secure = true }, "body-data");
    _ = try harness.web.pump(2, 64);
    _ = try harness.web.executeSource("globalThis.bodyController.abort('body-stop');globalThis.linkedResponse.text().catch(reason=>globalThis.bodyResult=reason)");
    _ = try harness.web.pump(3, 64);
    const global_object = harness.web.runtime.global("globalThis").?;
    try std.testing.expectEqualStrings("body-stop", harness.web.runtime.valueString(try harness.web.runtime.get(global_object, "bodyResult")));
    try std.testing.expect(harness.web.takeRequest() == null);
}

test "AbortSignal static factories listeners metadata and brands" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    harness.document.reset();
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://runtime.example/", "default-src 'self'", 1, 0);
    const value = try harness.web.executeSource("const signal=AbortSignal.abort('ready'),fallback=AbortSignal.abort(),first=new AbortController(),second=new AbortController(),combined=AbortSignal.any([first.signal,second.signal]);let events=0;const listener={handleEvent(){events++;}};combined.addEventListener('abort',listener,{once:true});combined.addEventListener('abort',()=>events++,{once:true});second.abort('combined');let reusable=true;for(let index=0;index<40;index++){const left=new AbortController(),right=new AbortController(),joined=AbortSignal.any([left.signal,right.signal]);left.abort(index);reusable=reusable&&joined.aborted&&joined.reason===index;}globalThis.timeout=AbortSignal.timeout(5);globalThis.timeoutEvents=0;globalThis.timeout.addEventListener('abort',()=>globalThis.timeoutEvents++,{once:true});let callError=false,brandError=false;try{AbortController();}catch(reason){callError=reason instanceof TypeError;}try{AbortSignal.prototype.throwIfAborted.call({});}catch(reason){brandError=reason instanceof TypeError;}[signal.aborted,signal.reason,fallback.reason.name,combined.aborted,combined.reason,events,reusable,globalThis.timeout.aborted,callError,brandError,AbortSignal.abort.length,AbortSignal.timeout.length,AbortSignal.any.length].join(',')");
    try std.testing.expectEqualStrings("true,ready,AbortError,true,combined,2,true,false,true,true,0,1,1", harness.web.runtime.valueString(value));
    const global_object = harness.web.runtime.global("globalThis").?;
    _ = try harness.web.pump(4, 64);
    const timeout = try harness.web.runtime.get(global_object, "timeout");
    try std.testing.expect(!harness.web.runtime.valueBoolean(try harness.web.runtime.get(timeout, "aborted")));
    _ = try harness.web.pump(5, 64);
    try std.testing.expect(harness.web.runtime.valueBoolean(try harness.web.runtime.get(timeout, "aborted")));
    try std.testing.expectEqualStrings("TimeoutError", harness.web.runtime.valueString(try harness.web.runtime.get(try harness.web.runtime.get(timeout, "reason"), "name")));
    try std.testing.expectEqual(@as(f64, 1), try harness.web.runtime.valueNumber(try harness.web.runtime.get(global_object, "timeoutEvents")));
}

test "Streams queuing strategies validate watermarks sizes metadata and brands" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    harness.document.reset();
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://runtime.example/", "", 1, 0);
    const value = try harness.web.executeSource(
        "const count=new CountQueuingStrategy({highWaterMark:5}),bytes=new ByteLengthQueuingStrategy({highWaterMark:8});" ++
            "let invalid=0,brand=false,construct=false;for(const make of [()=>new CountQueuingStrategy(),()=>new CountQueuingStrategy({}),()=>new CountQueuingStrategy({highWaterMark:-1}),()=>new ByteLengthQueuingStrategy({highWaterMark:NaN})]){try{make();}catch(reason){if(reason instanceof TypeError||reason instanceof RangeError)invalid++;}}" ++
            "try{CountQueuingStrategy.prototype.highWaterMark;}catch(reason){brand=reason instanceof TypeError;}try{new count.size();}catch(reason){construct=reason instanceof TypeError;}" ++
            "[count.highWaterMark,count.size('anything'),bytes.highWaterMark,bytes.size(new Uint8Array(4)),Number.isNaN(bytes.size({})),Object.prototype.toString.call(count),Object.prototype.toString.call(bytes),CountQueuingStrategy.length,ByteLengthQueuingStrategy.length,count.size.length,invalid,brand,construct].join(',')",
    );
    try std.testing.expectEqualStrings("5,1,8,4,true,[object CountQueuingStrategy],[object ByteLengthQueuingStrategy],1,1,1,4,true,true", harness.web.runtime.valueString(value));
}

test "ReadableStream controllers readers cancellation and Response bodies share one surface" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    harness.document.reset();
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://runtime.example/", "", 1, 0);
    const value = try harness.web.executeSource(
        "let desired='';const stream=new ReadableStream({start(controller){desired+=controller.desiredSize;controller.enqueue('a');desired+=controller.desiredSize;},pull(controller){controller.enqueue('b');controller.close();}});" ++
            "const reader=stream.getReader();globalThis.readableResult='';Promise.all([reader.read(),reader.read(),reader.read(),reader.closed]).then(items=>{reader.releaseLock();globalThis.readableResult=[items[0].value,items[0].done,items[1].value,items[1].done,items[2].done,stream.locked].join(',');});" ++
            "let cancelled='';const cancelledStream=new ReadableStream({cancel(reason){cancelled=reason;}});cancelledStream.cancel('stop').then(()=>globalThis.cancelledResult=cancelled);" ++
            "[stream instanceof ReadableStream,Object.prototype.toString.call(stream),reader instanceof ReadableStreamDefaultReader,Object.prototype.toString.call(reader),desired,new Response('x').body instanceof ReadableStream,ReadableStream.length].join(',')",
    );
    try std.testing.expectEqualStrings("true,[object ReadableStream],true,[object ReadableStreamDefaultReader],10,true,0", harness.web.runtime.valueString(value));
    _ = try harness.web.pump(1, 64);
    const global_object = harness.web.runtime.global("globalThis").?;
    try std.testing.expectEqualStrings("a,false,b,false,true,false", harness.web.runtime.valueString(try harness.web.runtime.get(global_object, "readableResult")));
    try std.testing.expectEqualStrings("stop", harness.web.runtime.valueString(try harness.web.runtime.get(global_object, "cancelledResult")));
}

test "WritableStream serializes writes backpressure close abort and writer state" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    harness.document.reset();
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://runtime.example/", "", 1, 0);
    const value = try harness.web.executeSource(
        "let events='';const writable=new WritableStream({start(controller){events+='S'+controller.signal.aborted;},write(chunk){events+='W'+chunk;},close(){events+='C';}});" ++
            "const writer=writable.getWriter(),initialSize=writer.desiredSize;const first=writer.write('a'),pressured=writer.desiredSize===0;globalThis.writableResult='';first.then(()=>writer.ready).then(()=>writer.write('b')).then(()=>writer.close()).then(()=>writer.closed).then(()=>{const finalSize=writer.desiredSize;writer.releaseLock();globalThis.writableResult=[events,writable.locked,finalSize].join(',');}).catch(reason=>globalThis.writableResult='failed:'+reason);" ++
            "let aborted='';const abortedStream=new WritableStream({abort(reason){aborted=reason;}});abortedStream.abort('stop').then(()=>globalThis.writableAbort=aborted);" ++
            "let queuedEvents='';const queuedStream=new WritableStream({write(chunk){queuedEvents+='W'+chunk;},abort(reason){queuedEvents+='A'+reason;}}),queuedWriter=queuedStream.getWriter(),queuedFirst=queuedWriter.write('1'),queuedSecond=queuedWriter.write('2');queuedWriter.closed.catch(()=>{});queuedWriter.abort('stop');Promise.allSettled([queuedFirst,queuedSecond]).then(results=>{globalThis.queuedAbort=[queuedEvents,results[0].status,results[1].status,queuedWriter.desiredSize].join(',');});" ++
            "[writable instanceof WritableStream,Object.prototype.toString.call(writable),writer instanceof WritableStreamDefaultWriter,Object.prototype.toString.call(writer),writable.locked,initialSize,pressured,WritableStream.length].join(',')",
    );
    try std.testing.expectEqualStrings("true,[object WritableStream],true,[object WritableStreamDefaultWriter],true,1,true,0", harness.web.runtime.valueString(value));
    _ = try harness.web.pump(1, 128);
    const global_object = harness.web.runtime.global("globalThis").?;
    try std.testing.expectEqualStrings("SfalseWaWbC,false,0", harness.web.runtime.valueString(try harness.web.runtime.get(global_object, "writableResult")));
    try std.testing.expectEqualStrings("stop", harness.web.runtime.valueString(try harness.web.runtime.get(global_object, "writableAbort")));
    try std.testing.expectEqualStrings("Astop,rejected,rejected,", harness.web.runtime.valueString(try harness.web.runtime.get(global_object, "queuedAbort")));
}

test "TransformStream applies backpressure transforms flushes and exposes paired streams" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    harness.document.reset();
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://runtime.example/", "", 1, 0);
    const value = try harness.web.executeSource(
        "let desired='';const transform=new TransformStream({start(controller){desired=String(controller.desiredSize);},transform(chunk,controller){controller.enqueue(chunk.toUpperCase());},flush(controller){controller.enqueue('!');}});" ++
            "const reader=transform.readable.getReader(),writer=transform.writable.getWriter();globalThis.transformResult='';const reads=Promise.all([reader.read(),reader.read(),reader.read(),reader.read()]);writer.write('a').then(()=>writer.write('b')).then(()=>writer.close());reads.then(items=>{globalThis.transformResult=[items[0].value,items[1].value,items[2].value,items[3].done].join(',');});" ++
            "[transform instanceof TransformStream,Object.prototype.toString.call(transform),transform.readable instanceof ReadableStream,transform.writable instanceof WritableStream,desired,TransformStream.length].join(',')",
    );
    try std.testing.expectEqualStrings("true,[object TransformStream],true,true,0,0", harness.web.runtime.valueString(value));
    _ = try harness.web.pump(1, 192);
    const global_object = harness.web.runtime.global("globalThis").?;
    try std.testing.expectEqualStrings("A,B,!,true", harness.web.runtime.valueString(try harness.web.runtime.get(global_object, "transformResult")));
}

test "Readable byte streams support BYOB requests partial fills and auto allocation" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    harness.document.reset();
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://runtime.example/", "", 1, 0);
    const value = try harness.web.executeSource(
        "let autoPulls=0;const automatic=new ReadableStream({type:'bytes',autoAllocateChunkSize:4,pull(controller){autoPulls++;const request=controller.byobRequest,view=request.view;view[0]=65;view[1]=66;request.respond(2);if(autoPulls===2)controller.close();}});" ++
            "const automaticReader=automatic.getReader();globalThis.autoBytes='';automaticReader.read().then(first=>automaticReader.read().then(second=>automaticReader.read().then(last=>{globalThis.autoBytes=[first.value.length,first.value[0],second.value[1],last.done,autoPulls].join(',');})));" ++
            "let byteController;const byteStream=new ReadableStream({type:'bytes',start(controller){byteController=controller;controller.enqueue(new Uint8Array([1,2]));},pull(controller){const request=controller.byobRequest;request.view[0]=3;request.respond(1);controller.close();}});" ++
            "const byobReader=byteStream.getReader({mode:'byob'});globalThis.byobBytes='';byobReader.read(new Uint8Array(4),{min:3}).then(first=>byobReader.read(new Uint8Array(2)).then(last=>{globalThis.byobBytes=[first.value.length,first.value[0],first.value[1],first.value[2],first.done,last.value.length,last.done].join(',');}));" ++
            "const replacementStream=new ReadableStream({type:'bytes',pull(controller){const request=controller.byobRequest,view=request.view;view[0]=7;view[1]=8;request.respondWithNewView(view.subarray(0,2));controller.close();}}),replacementReader=replacementStream.getReader({mode:'byob'});globalThis.replacementBytes='';replacementReader.read(new Uint8Array(4),{min:2}).then(item=>{globalThis.replacementBytes=[item.value.length,item.value[0],item.value[1],item.done].join(',');});" ++
            "[automatic instanceof ReadableStream,byobReader instanceof ReadableStreamBYOBReader,Object.prototype.toString.call(byteController),Object.prototype.toString.call(byteController.byobRequest)].join(',')",
    );
    try std.testing.expectEqualStrings("true,true,[object ReadableByteStreamController],[object ReadableStreamBYOBRequest]", harness.web.runtime.valueString(value));
    _ = try harness.web.pump(1, 256);
    const global_object = harness.web.runtime.global("globalThis").?;
    try std.testing.expectEqualStrings("2,65,66,true,2", harness.web.runtime.valueString(try harness.web.runtime.get(global_object, "autoBytes")));
    try std.testing.expectEqualStrings("3,1,2,3,false,0,true", harness.web.runtime.valueString(try harness.web.runtime.get(global_object, "byobBytes")));
    try std.testing.expectEqualStrings("2,7,8,false", harness.web.runtime.valueString(try harness.web.runtime.get(global_object, "replacementBytes")));
}

test "Stream from pipeThrough and pipeTo compose with writable closure" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    harness.document.reset();
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://runtime.example/", "", 1, 0);
    _ = try harness.web.executeSource(
        "globalThis.pipeResult='';const written=[],source=ReadableStream.from(['a','b']),transform=new TransformStream({transform(value,controller){controller.enqueue(value.toUpperCase());}}),output=source.pipeThrough(transform);output.pipeTo(new WritableStream({write(value){written.push(value);},close(){written.push('closed');}})).then(()=>{globalThis.pipeResult=written.join(',');},error=>{globalThis.pipeResult='ERR:'+String(error);});",
    );
    _ = try harness.web.pump(1, 4096);
    const global_object = harness.web.runtime.global("globalThis").?;
    try std.testing.expectEqualStrings("A,B,closed", harness.web.runtime.valueString(try harness.web.runtime.get(global_object, "pipeResult")));
}

test "ReadableStream tee cancellation and values iterator preserve the active branch" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    harness.document.reset();
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://runtime.example/", "", 1, 0);
    _ = try harness.web.executeSource(
        "globalThis.teeResult='';const source=new ReadableStream({start(controller){controller.enqueue('left');controller.enqueue('right');controller.close();}}),branches=source.tee(),left=branches[0],right=branches[1],iterator=right.values();left.cancel('unused');iterator.next().then(first=>iterator.next().then(second=>iterator.next().then(last=>{globalThis.teeResult=[first.value,second.value,last.done,source.locked].join(',');})));",
    );
    _ = try harness.web.pump(1, 512);
    const global_object = harness.web.runtime.global("globalThis").?;
    try std.testing.expectEqualStrings("left,right,true,false", harness.web.runtime.valueString(try harness.web.runtime.get(global_object, "teeResult")));
}

test "TransformStream propagates transform start and flush failures to both sides" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    harness.document.reset();
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://runtime.example/", "", 1, 0);
    _ = try harness.web.executeSource(
        "globalThis.transformErrors='';globalThis.startErrors='';globalThis.flushErrors='';" ++
            "const broken=new TransformStream({transform(){throw new Error('transform');}}),reader=broken.readable.getReader(),writer=broken.writable.getWriter();reader.read();writer.write('x').catch(writeError=>reader.closed.catch(readError=>{globalThis.transformErrors=writeError.message+','+readError.message;}));" ++
            "const startBroken=new TransformStream({start(){return Promise.reject(new Error('start'));}}),startReader=startBroken.readable.getReader(),startWriter=startBroken.writable.getWriter();startReader.closed.catch(readError=>startWriter.closed.catch(writeError=>{globalThis.startErrors=readError.message+','+writeError.message;}));" ++
            "const flushBroken=new TransformStream({flush(){throw new Error('flush');}}),flushReader=flushBroken.readable.getReader(),flushWriter=flushBroken.writable.getWriter();flushReader.read();flushWriter.close().catch(writeError=>flushReader.closed.catch(readError=>{globalThis.flushErrors=writeError.message+','+readError.message;}));",
    );
    _ = try harness.web.pump(1, 512);
    const global_object = harness.web.runtime.global("globalThis").?;
    try std.testing.expectEqualStrings("transform,transform", harness.web.runtime.valueString(try harness.web.runtime.get(global_object, "transformErrors")));
    try std.testing.expectEqualStrings("start,start", harness.web.runtime.valueString(try harness.web.runtime.get(global_object, "startErrors")));
    try std.testing.expectEqualStrings("flush,flush", harness.web.runtime.valueString(try harness.web.runtime.get(global_object, "flushErrors")));
}

test "Stream piping consumes Response bodies and propagates AbortSignal cancellation" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    harness.document.reset();
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://runtime.example/", "", 1, 0);
    _ = try harness.web.executeSource(
        "globalThis.responsePipe='';let responseText='';new Response('body').body.pipeTo(new WritableStream({write(chunk){responseText+=new TextDecoder().decode(chunk);}})).then(()=>{globalThis.responsePipe=responseText;});" ++
            "globalThis.abortPipe='';let canceled='',aborted='';const source=new ReadableStream({pull(){return new Promise(()=>{});},cancel(reason){canceled=reason;}}),sink=new WritableStream({abort(reason){aborted=reason;}}),controller=new AbortController();source.pipeTo(sink,{signal:controller.signal}).catch(reason=>{globalThis.abortPipe=[reason,canceled,aborted,source.locked,sink.locked].join(',');});controller.abort('stop');",
    );
    _ = try harness.web.pump(1, 512);
    const global_object = harness.web.runtime.global("globalThis").?;
    try std.testing.expectEqualStrings("body", harness.web.runtime.valueString(try harness.web.runtime.get(global_object, "responsePipe")));
    try std.testing.expectEqualStrings("stop,stop,stop,false,false", harness.web.runtime.valueString(try harness.web.runtime.get(global_object, "abortPipe")));
}

test "URLSearchParams accepts records sequences clones and WebIDL string coercion" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    _ = try harness.document.parse("<!doctype html><body></body>", .{ .content_type = "text/html" });
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://runtime.example/", "default-src 'self'", 1, 0);

    const value = try harness.web.executeSource(
        "const sequence=new URLSearchParams([['a',1],['a',2]]);" ++
            "const record=new URLSearchParams({b:2,a:1});const clone=new URLSearchParams(sequence);" ++
            "clone.append(3,false);clone.append('missing',undefined);" ++
            "clone.append('\\uD800','\\uD800');" ++
            "const before=clone.has('missing',undefined);clone.delete('missing',undefined);" ++
            "const optional=new URLSearchParams('x=undefined&x=other');optional.delete('x',undefined);" ++
            "const url=new URL('/path',new URL('https://Example.test/base'));" ++
            "[sequence.toString(),record.toString(),clone.toString(),before,clone.has('missing'),optional.toString()," ++
            "sequence instanceof URLSearchParams,url instanceof URL,url.toJSON(),URL.canParse(17)].join('|');",
    );
    try std.testing.expectEqualStrings(
        "a=1&a=2|b=2&a=1|a=1&a=2&3=false&%EF%BF%BD=%EF%BF%BD|true|false||true|true|https://example.test/path|true",
        harness.web.runtime.valueString(value),
    );
}

test "URL components mutate consistently and URL host methods enforce brands" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    _ = try harness.document.parse("<!doctype html><body></body>", .{ .content_type = "text/html" });
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://runtime.example/", "default-src 'self'", 1, 0);

    const value = try harness.web.executeSource(
        "const url=new URL('https://user:pass@Example.test:443/a?x=1#old');" ++
            "url.username='new user';url.password='p@ss';url.host='Other.test:80';url.hostname='Final.test';" ++
            "url.port=443;url.pathname='next';url.search='';url.hash='';url.href='../relative?q=2';" ++
            "const setParams=url.searchParams;url.search='?live=1';" ++
            "const iterable=new URLSearchParams(new Set([['s',1],['t',2]]));" ++
            "let invalidPair=false;try{new URLSearchParams([['only']]);}catch(reason){invalidPair=reason instanceof TypeError;}" ++
            "let urlBrand=false;try{URL.prototype.toString.call({});}catch(reason){urlBrand=reason instanceof TypeError;}" ++
            "let paramsBrand=false;try{URLSearchParams.prototype.append.call({},'x','y');}catch(reason){paramsBrand=reason instanceof TypeError;}" ++
            "let urlCall=false;try{URL('https://example.test/');}catch(reason){urlCall=reason instanceof TypeError;}" ++
            "let paramsCall=false;try{URLSearchParams('x=1');}catch(reason){paramsCall=reason instanceof TypeError;}" ++
            "const live=new URLSearchParams('a=1');const liveIterator=live.entries();live.append('b',2);" ++
            "const liveValues=liveIterator.next().value.join('')+liveIterator.next().value.join('');" ++
            "const liveEach=new URLSearchParams('a=1');let each='';liveEach.forEach((value,name)=>{each+=name+value;if(name==='a')liveEach.append('b',2);});" ++
            "url.origin='https://wrong.test';url.searchParams='wrong';iterable.size=99;" ++
            "[url.href,url.origin,url.username,url.password,url.host,url.hostname,url.port,url.pathname,url.search,url.hash," ++
            "setParams===url.searchParams,setParams.get('live'),iterable.toString(),invalidPair,urlBrand,paramsBrand," ++
            "urlCall,paramsCall,liveValues,each,liveIterator instanceof Iterator,iterable.size," ++
            "Object.prototype.toString.call(url),Object.prototype.toString.call(iterable)," ++
            "URL.prototype.toString===url.toString,URLSearchParams.prototype.entries===iterable.entries," ++
            "URL.length,URL.canParse.length,URLSearchParams.length,URLSearchParams.prototype.append.length," ++
            "URLSearchParams.prototype.delete.length,Object.keys(URL.prototype).length,Object.keys(URLSearchParams.prototype).length," ++
            "Object.getOwnPropertyDescriptor(URL.prototype,'href').get.name,Object.getOwnPropertyDescriptor(URL.prototype,'href').set.length," ++
            "Object.getOwnPropertyDescriptor(URL.prototype,'origin').set===undefined,Object.getOwnPropertyDescriptor(URLSearchParams.prototype,'size').get.name].join('|');",
    );
    try std.testing.expectEqualStrings(
        "https://new%20user:p%40ss@final.test/relative?live=1|https://final.test|new%20user|p%40ss|final.test|final.test||/relative|?live=1||true|1|s=1&t=2|true|true|true|true|true|a1b2|a1b2|true|2|[object URL]|[object URLSearchParams]|true|true|1|1|0|2|1|0|0|get href|1|true|get size",
        harness.web.runtime.valueString(value),
    );
}

test "bindings mutate DOM dispatch events timers and preserve origin storage" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    _ = try harness.document.parse(
        "<!doctype html><body><p id=answer>old</p><script nonce=r4>" ++
            "const answer = document.getElementById('answer');" ++
            "answer.textContent = 'new';" ++
            "localStorage.saved = 'yes'; document.cookie = 'theme=dark; Path=/';" ++
            "const standardGlobals = window.Proxy === Proxy && window.Reflect === Reflect && window.Function === Function && window.JSON === JSON && window.Map === Map;" ++
            "let trace = ''; addEventListener('load', (event) => { event.preventDefault(); trace += 'L'; });" ++
            "setTimeout(() => { trace += 'T'; }, 5);" ++
            "</script></body>",
        .{ .content_type = "text/html;charset=utf-8" },
    );
    try harness.web.beginDocument(
        &harness.document,
        &harness.storage,
        "https://example.com/app",
        "default-src 'self'; script-src 'nonce-r4'; connect-src 'self'",
        4,
        100,
    );
    try std.testing.expectEqual(@as(usize, 1), try harness.web.executeDocumentScripts());
    const answer = harness.document.findElementById("answer").?;
    var text: [32]u8 = undefined;
    try std.testing.expectEqualStrings("new", try harness.document.textContent(answer, text[0..]));
    try std.testing.expectEqualStrings("yes", (try harness.storage.local.area(&harness.web.security_context.document_origin)).get("saved").?);
    var cookie_out: [128]u8 = undefined;
    try std.testing.expectEqualStrings("theme=dark", harness.storage.cookies.writeDocumentCookie(&harness.web.security_context.document_origin, "/app", cookie_out[0..]));
    const dispatch = try harness.web.dispatchEvent(.window, "load", 101);
    try std.testing.expectEqual(@as(usize, 1), dispatch.queued);
    _ = try harness.web.pump(106, 8);
    try std.testing.expect(harness.web.eventCancelled(dispatch.serial));
    try std.testing.expectEqualStrings("LT", harness.web.runtime.valueString(harness.web.runtime.global("trace").?));
    try std.testing.expect(harness.web.runtime.valueBoolean(harness.web.runtime.global("standardGlobals").?));
    try std.testing.expect(harness.web.needsReflow());
}

test "fetch CORS response promise and stale generation are enforced" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    _ = try harness.document.parse("<!doctype html><body></body>", .{ .content_type = "text/html" });
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://app.example/", "connect-src https://api.example", 9, 0);
    _ = try harness.web.executeSource(
        "let result = ''; fetch('https://api.example/data').then((response) => response.text()).then((text) => { result = text; });",
    );
    const request = harness.web.takeRequest().?;
    const id = request.id;
    try std.testing.expectError(error.CorsBlocked, harness.web.completeRequest(id, 9, .{
        .status = 200,
        .secure = true,
        .access_control_allow_origin = "https://other.example",
    }, "denied"));
    _ = try harness.web.pump(1, 8);

    _ = try harness.web.executeSource(
        "fetch('https://api.example/ok').then((response) => response.text()).then((text) => { result = text; });",
    );
    const accepted = harness.web.takeRequest().?;
    try harness.web.completeRequest(accepted.id, 9, .{
        .status = 200,
        .secure = true,
        .access_control_allow_origin = "https://app.example",
    }, "accepted");
    _ = try harness.web.pump(2, 16);
    try std.testing.expectEqualStrings("accepted", harness.web.runtime.valueString(harness.web.runtime.global("result").?));
    _ = try harness.web.executeSource(
        "let streamed = ''; fetch('https://api.example/stream').then((response) => response.body.getReader().read()).then((part) => { streamed = new TextDecoder().decode(part.value); });",
    );
    const streamed_request = harness.web.takeRequest().?;
    try harness.web.completeRequest(streamed_request.id, 9, .{
        .status = 200,
        .secure = true,
        .access_control_allow_origin = "https://app.example",
    }, "chunk");
    _ = try harness.web.pump(3, 16);
    try std.testing.expectEqualStrings("chunk", harness.web.runtime.valueString(harness.web.runtime.global("streamed").?));
    harness.web.abortDocument();
    try std.testing.expectError(error.StaleGeneration, harness.web.completeRequest(accepted.id, 9, .{ .status = 200, .secure = true }, "late"));
}

test "fetch redirect modes opaque filtering and network errors are coherent" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    harness.document.reset();
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://app.example/", "connect-src https://api.example", 10, 0);
    _ = try harness.web.executeSource(
        "let manualResult='',opaqueResult='',headersResult='',failureKind=false;" ++
            "fetch('https://api.example/redirect',{redirect:'manual'}).then(response=>manualResult=[response.type,response.status,response.ok,response.url,response.redirected,response.body===null,response.headers.get('location')].join(','));" ++
            "fetch('https://api.example/opaque',{mode:'no-cors'}).then(response=>opaqueResult=[response.type,response.status,response.ok,response.url,response.redirected,response.body===null].join(','));" ++
            "fetch('https://api.example/headers').then(response=>headersResult=[response.type,response.headers.get('content-type'),response.headers.get('x-visible'),response.headers.get('x-hidden'),response.headers.get('set-cookie')].join(','));" ++
            "fetch('https://api.example/failure').catch(reason=>failureKind=reason instanceof TypeError);",
    );
    const manual = harness.web.takeRequest().?;
    try std.testing.expectEqual(FetchRedirectMode.manual, manual.redirect);
    try harness.web.completeRequest(manual.id, manual.generation, .{
        .status = 302,
        .secure = true,
        .manual_redirect = true,
        .final_url = "https://api.example/redirect",
        .access_control_allow_origin = "https://app.example",
    }, "hidden redirect body");
    const opaque_request = harness.web.takeRequest().?;
    try std.testing.expectEqual(security.RequestMode.no_cors, opaque_request.mode);
    try harness.web.completeRequest(opaque_request.id, opaque_request.generation, .{
        .status = 200,
        .secure = true,
        .final_url = "https://api.example/opaque",
        .content_type = "text/plain",
    }, "hidden body");
    const headers_request = harness.web.takeRequest().?;
    try harness.web.completeRequest(headers_request.id, headers_request.generation, .{
        .status = 200,
        .secure = true,
        .final_url = "https://api.example/headers",
        .content_type = "text/plain",
        .headers = "Content-Type: text/plain\r\nX-Visible: yes\r\nX-Hidden: no\r\nAccess-Control-Expose-Headers: X-Visible\r\nSet-Cookie: hidden=yes",
        .access_control_allow_origin = "https://app.example",
    }, "headers");
    const failed = harness.web.takeRequest().?;
    try harness.web.failRequest(failed.id, failed.generation, "Connection failed");
    _ = try harness.web.pump(1, 32);
    try std.testing.expectEqualStrings("opaqueredirect,0,false,,false,true,", harness.web.runtime.valueString(harness.web.runtime.global("manualResult").?));
    try std.testing.expectEqualStrings("opaque,0,false,,false,true", harness.web.runtime.valueString(harness.web.runtime.global("opaqueResult").?));
    try std.testing.expectEqualStrings("cors,text/plain,yes,,", harness.web.runtime.valueString(harness.web.runtime.global("headersResult").?));
    try std.testing.expect(harness.web.runtime.valueBoolean(harness.web.runtime.global("failureKind").?));
}

test "mixed content CSP navigation XHR and timing remain bounded" {
    const allocator = std.testing.allocator;
    const harness = try allocator.create(struct {
        document: html.Document,
        storage: security.BrowserStorage,
        web: WebRuntime,
    });
    defer allocator.destroy(harness);
    harness.web.initialize(testingProgramAllocator(harness));
    defer harness.web.deinit();
    _ = try harness.document.parse("<!doctype html><body></body>", .{ .content_type = "text/html" });
    try harness.web.beginDocument(&harness.document, &harness.storage, "https://secure.example/a", "connect-src 'self'", 2, 50);
    _ = try harness.web.executeSource(
        "let blocked = ''; fetch('http://secure.example/data').catch((reason) => { blocked = String(reason); });" ++
            "location.assign('/next'); const xhr = new XMLHttpRequest(); xhr.open('GET', '/api'); xhr.send();" ++
            "const elapsed = performance.now();",
    );
    _ = try harness.web.pump(51, 8);
    try std.testing.expectEqualStrings("TypeError: Mixed content blocked", harness.web.runtime.valueString(harness.web.runtime.global("blocked").?));
    const action = harness.web.takeAction().?;
    try std.testing.expectEqual(ActionKind.navigate, action.kind);
    try std.testing.expectEqualStrings("https://secure.example/next", action.url.bytes());
    const request = harness.web.takeRequest().?;
    try std.testing.expectEqual(RequestKind.xhr, request.kind);
    try std.testing.expectEqualStrings("https://secure.example/api", request.url.bytes());
    try std.testing.expectEqual(@as(f64, 0), try harness.web.runtime.valueNumber(harness.web.runtime.global("elapsed").?));
    _ = try harness.web.executeSource(
        "history.pushState({}, '', '/state'); const navigationEntries = performance.getEntriesByType('navigation'); const entryType = navigationEntries[0].entryType;",
    );
    const history_action = harness.web.takeAction().?;
    try std.testing.expectEqual(ActionKind.push_state, history_action.kind);
    try std.testing.expectEqualStrings("https://secure.example/state", history_action.url.bytes());
    try std.testing.expectEqualStrings("navigation", harness.web.runtime.valueString(harness.web.runtime.global("entryType").?));
}
