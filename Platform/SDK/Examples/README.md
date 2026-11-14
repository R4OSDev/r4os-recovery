# SDK examples

`Canvas.zig` is a complete ordinary hosted GUI entry point. It paints the full
current client rectangle with bounded caller-owned command/resource arrays and
waits for events when unchanged. Resize paints a new transaction; drawing,
resource overflow or publication failure discards the entire frame and exits.
No driver detection, direct framebuffer access or private NVIDIA route exists.

Build it as an SDK R4X using `ENTRY_MODE=app`, `APP_CLASS=gui` and imports
`R4SYS:Query2:2`, `R4DESK:Query2:2`, `R4DRAW:Query2:2`. Copy this source into an
application created from `Templates/R4X`; use its normal Build.bat/Build.sh.
Launch from Desktop: a GUI window is a prerequisite. The same source uses
software composition or the admitted native output chosen by Desktop.
This example is source documentation, not an installed module or a new test gate.

SDK0.64.146 demonstrates two rounded cards with independent borders and
shadow layers: one linear and one elliptical radial gradient. It requires
the R4DRAW39 grammar and corresponding Desktop renderer. The optional
`gui_shapes.gradientsSupported` query allows older consumers to choose a
solid fill. The resource builder validates coordinates and two through eight
ordered color stops before changing its caller-owned output buffer.

`Modern.zig` opts its own Canvas into SDK0.64.147 `gui.Style.light/dark`.
It uses the same Button, TextField, TabBar and ModalDialog input owners,
plus shared Card/TileGrid, Paragraph and Progress helpers. Tab/arrow/Enter,
Unicode/clipboard, native pointer capture, hover/pressed/disabled states,
light/dark switching and a native dialog are interactive. The outer frame
and system buttons remain Desktop-owned. Build it with the same three imports
and ordinary module template as Canvas.zig; it installs no global theme.
Resolve `Style.withSystemFonts(draw)` again on font_changed, and use
Canvas.layoutTabs for both painting and hit testing with its font metrics.
FontSet selects existing renderable R4 Sans catalog entries; unavailable
roles retain the builtin font. R4FONT remains the scalable-font owner.
For the complete contract and migration see Docs/SDK/GuiControls.txt.

`GuiEvents.c` uses an actual App2 entry and a borrowed current C facade.
The App2 owner stays live through the complete event/window scope.
Use the same GUI imports and `ENTRY_MODE=app`, with `LANGUAGE=C` and
`SOURCE=src/main.c` in an ordinary R4X project. Copy the example to that source
path and build with the project's normal starter. It waits for messages,
paints on change, and changes its caption on focus or font notifications.

The window loop waits on the current per-program `gui_activity_wait` callback
with shared clipboard notifications. It requires that current callback; the
Desktop host activity channel does not deliver these client event wakeups.

The C event loop returns `R4_MESSAGE_FOCUS_GAINED` and
`R4_MESSAGE_FOCUS_LOST` with `message.value.focus.window_id` and `.tick`.
`R4_MESSAGE_FONT_CHANGED` uses `message.value.font_changed`; query the current
font/metrics or repaint when handling it. The existing global font broadcast
has `window_id=-1` and `tick=0`, with no font ID or revision. The facade preserves
these absent values. Other unknown raw events remain in
`R4_MESSAGE_UNKNOWN` and `message.value.unknown`.

`R4GuiWindowInfo.flags` can be tested with `R4_GUI_WINDOW_FLAG_VISIBLE`,
`R4_GUI_WINDOW_FLAG_MINIMIZED`, `R4_GUI_WINDOW_FLAG_MAXIMIZED`,
`R4_GUI_WINDOW_FLAG_CLOSE_REQUESTED` and `R4_GUI_WINDOW_FLAG_FULLSCREEN`.
These public names alias the canonical Contract definitions. The technical
header `<r4os/abi_generated.h>` also exposes the generated
`R4ABI_GUI_WINDOW_FLAG_*` names for the first four flags and the existing raw
`R4ABI_GUI_EVENT_KIND_FOCUS_GAINED`, `...FOCUS_LOST`, `...FONT_CHANGED` names.
The SDK's shared session bridge and Rust `gui::EventKind` expose the same three
new semantic events. Existing message numbers and public C payload sizes remain
stable; raw, higher C, and shared session event kinds are distinct enums.

For retained resources and output ownership see Libraries/R4GFX/Examples;
Vulkan bootstrap: Libraries/R4VK/Examples; a complete ordinary OpenGL window:
Libraries/R4GL/Examples/Triangle.zig. The integration/cost report is
Docs/Desktop/GrafikIntegration07944.txt in the workspace Docs repository.


## Bounded POST and SSE

SDK 0.64.124 adds a caller-owned HTTP POST stream. It uses the existing TCP,
TLS certificate/hostname/trust and HTTP owners. `app_web.PostStream` is the Zig
owner; C includes `<r4os/transport_helpers.h>` and Rust uses
`web::transport::{PostRequest, PostBuffers, PostStream, StreamState}`.
Use the same generated headers, bindings and runtime objects together.
Nexus SDK/Contract pins are not changed by this example.

Keep the context, all four buffers, request/header/body slices, callback table
and user state at their original addresses until disposal is acknowledged.
There is no response-sized allocation. Header storage is 16 KB, TLS scratch is
54 KB; choose small nonempty receive/upload buffers (for example 4 KB each).
The context holds bounded request/header metadata. Requests above 12 KB work
because the request header and body are sent separately. Defaults limit each
request/response body to 64 MB, URLs to 1024 bytes, request headers to 12 KB,
response headers to 16 KB/64 fields, chunk/trailer lines to 1024 bytes, trailers
to 16 KB/64 fields and interim responses to eight. 1 MB means 1024 KB.
The upload owner requests at most 8 KB from a reader each time. Smaller caller
buffers reduce this amount. These are body limits: wire counters also include
HTTP framing and, for HTTPS, encrypted application record overhead. Handshake
traffic is excluded from `application_wire_confirmed`.

A fixed body uses Content-Length. With `post_stream_read`, `request_length`
selects Content-Length when present, otherwise chunked request framing.
The reader writes into the supplied bounded output slice and returns the
produced byte count, 0 for EOF, -1 to pause without consuming input, -2 to
cancel, or -3 on source failure. Reader and fixed request body are exclusive.
Content-Length/Transfer-Encoding/Expect/Connection headers are owned by the
transport. Request trailers and automatic POST replay are not supported.
Redirect handling is manual (default) or an error; credentials are never
forwarded through an automatic redirect. Existing target/cookie/CORS hooks
apply, including a bounded preflight on its own acknowledged connection.

The write callback kind `R4SdkWebCallbackKind_post_stream_write` receives
(context, delivered offset, borrowed bytes). Return `accept` (0), `pause` (1),
`cancel` (2), or `fail` (3). A pause accepts zero bytes; `run` returns Paused.
Keep buffers unchanged and call `run` again when the application can receive:
the identical pending chunk is presented again. Copy/process bytes before
accepting them. Callbacks must return promptly; the single absolute request
deadline continues during application pauses. Use the existing atomic StopFlag
for asynchronous stop intent, or `cancel` between runs. No POST or partially
submitted TLS record is automatically retried.

For Rust, construct the existing stable `web::Callbacks` table with the sink
kind enabled, then use this pattern (`app`, `callbacks`, `url`, `body` and
caller-owned buffers are supplied by the application):

```rust
use core::mem::MaybeUninit;
use r4os_sdk::web::transport::{Transport, PostRequest, PostBuffers, StreamState};
let mut owner_storage = MaybeUninit::uninit();
let mut stream_storage = MaybeUninit::uninit();
let mut transport = Transport::open(&mut owner_storage, app)?;
let mut request = PostRequest::new(url, body, callbacks);
request.request.content_type = b"application/json";
request.request.headers = b"Accept: text/event-stream\n";
let mut stream = transport.post_stream(&mut stream_storage, request,
    PostBuffers { headers, io, upload, tls })?;
let report = stream.run()?;
if report.state == StreamState::Paused {
    // Return to the application's scheduling/backpressure policy, retaining
    // stream and every loan; call run() again when ready.
}
// Inspect report.state, confirmed/request and delivered/response byte counts.
// On terminal completion/cancel/error, explicitly close if can_release() is
// false, and inspect report().close_ack. An unknown close keeps this owner.
```

C uses the generated `R4SdkTransportPostStreamOptions_create`,
`R4SdkTransportPostStreamBuffers_from_fields`, `R4SdkTransport_postStreamCallbacks`,
`R4SdkTransport_postStreamSink`, then `postStreamInit`, `postStreamRun`,
`postStreamReport`, `postStreamClose` and `postStreamCanRelease` wrappers.
Initialize the nested FetchOptions with method POST and manual/error redirect;
its ordinary default method is GET. The generated field getters preserve
optional totals and every report flag; do not read native opaque bytes.

Zig initializes `var stream: sdk.app_web.PostStream = undefined` in its final
address with `stream.init(&transport, url, buffers, sink, options)`, then calls
`stream.run()`. Set `options.request.method = .post` and `.redirect = .manual`
when supplying a nested request value. All three projections retain the same
owner, sink actions, deadline and explicit disposal contract.

For Nexus-style SSE, maintain an application-owned bounded line accumulator
across callback invocations. HTTP chunks may divide a UTF-8 code point, a line,
CRLF, an event ID, or a `data:` value. Split on complete lines, retain `id:`,
join multiple `data:` fields with a newline, and dispatch on a blank line.
Decode UTF-8 only after its complete input is available (or retain decoder
state). A complete event whose data equals `[DONE]` is an application/LLM end
marker. It is independent of HTTP framing completion, TLS close_notify and
TCP EOF. Missing application end markers remain an application error even
when HTTP completes; a received marker never forgives truncated HTTP/TLS.

Responses support Content-Length, chunked sizes/extensions/trailers, and
explicit opt-in close-delimited framing. A bare TCP EOF under TLS is always
an error; only authenticated TLS close_notify can end an allowed EOF body.
`http_complete`, `tcp_eof`, `tls_close_notify`, delivered bytes and `close_ack`
are separate. A failed/unknown write retains the confirmed prefix and marks
uncertain effect; TCP acceptance is not proof of remote POST execution.
Drop is best effort, not a disposal acknowledgement. No full half-close-send,
physical NIC/heap release, production Nexus or SDK speed claim follows.

Modern native title colors (SDK148)
----------------------------------
Build `Modern.zig` with the ordinary GUI manifest and optionally add:
```
META=gui.title.background=341F4A
META=gui.title.foreground=F7F0FF
```
The Desktop owns the real outer title bar. Missing values retain its defaults;
its inactive title and native window buttons remain Desktop policy. These
immutable loaded metadata do not change the Canvas style or another process's
terminal. See `Docs/API/GuiWindowAppearance.txt` and the Contract document.
