Native pointer-capture / physical mouse-look guest fixtures
=========================================================

These are public C consumers, not installed applications. Every manifest uses
IMAGE_SCOPE=none. The main fixture includes the single public source
Examples/MouseLook.c; Observe and Contender have their own small entry points.
Build each project with the current SDK Tools/ManifestProject and a matching
Contract source. Keep output and working files in the workspace Temp directory.

Run MLOOK28.R4X as a real hosted GUI through the Desktop or DESKRUN /WAITFRAME.
Normal C compilation or callback stubs do not qualify actual pointer delivery.

Main controls:
- Left Down requests DRAG; release after the final Up, including outside client.
- Key2 requests RELATIVE without a held button; ACTIVE is asynchronous.
- Escape explicitly releases, Q exits. Window Close must terminate capture.
- I/J exercise stale window/process-generation requests and unchanged outputs.
- V tries the previous terminal token during a newer lease and verifies that
  the current exact capture remains unchanged.
- B pauses the receiver for a bounded 3000-tick queue-overflow test.

M28OBS.R4X is an explicit console helper, normally launched through SSH:
- K:pid:generation binds portable completion/output and prints its cookie.
- R:pid:generation:cookie polls, then reads all completed output and closes
  that reference. Pending keeps the cookie intact. Close every kept reference.
- X:pid:generation and C:pid:generation kill or request close of that exact
  test process. Never point these commands at an unrelated process.
- S:pid:generation:epoch:window:capture checks a foreign/stale token; query and
  release must fail, and failed query output must remain untouched.
- W/A enqueue a real public remote-input wheel/absolute-move event. W is a
  routing test; it is not a physical-wheel measurement. A must cancel RELATIVE
  and must never be converted into raw physical motion.

M28RIVAL.R4X presents a second window. During its first1000ticks, raise/focus
MouseLook and capture there. The contender then requests its own exact native
identity while unfocused. BUSY and unchanged token output are required. During
its second1000ticks, move/release the captured pointer outside MouseLook over
the contender. Its mouse-event count must remain0. It then returns0 on success.

Actual input qualification:
- Use a real Desktop source, for example QEMU QMP input-send-event relative
  PS/2 movements and button packets. Space packets so the emulated device can
  transmit each vector before a later opposite vector cancels its backlog.
- In RELATIVE, send enough positive and negative movement on both axes to
  exceed client and screen extents. Check actual received sums/source markers;
  injected host vectors alone are not proof of delivered physical reports.
- Check software/hardware/remote cursor paths in their qualified environments.
  A screenshot from a virtual software display does not qualify physical GPU
  cursor visibility, USB devices, Windows hosts or physical input latency.
- Verify release, focus loss, window close, owner kill, Desktop end, quick
  WINSVC stop/start, native window-slot reuse and reactivation. A generation-
  bound broker completion guard must catch restart between successful RPCs.
- Fill the ordinary event queue while the owner is paused. Native delivery
  must cancel with INPUT_OVERFLOW. The terminal notice is ordered after prior
  queued input; do not infer current native state from an undrained old frame.

M28 finished checks=N failures=0, exit0, complete retained output and concrete
input/cursor/lifecycle evidence are separate requirements. A forced kill has
its actual negative exit and no fabricated normal-finish marker. The project
roadmap and Docs/API/GuiFacade.md record the current qualified scope; this
fixture README does not claim hardware or benchmark results.
