Native runtime support for shared libraries
===========================================

Owner: Libraries. These sources compile into each consuming R4L; they have
no separate runtime module, install target, manifest or public table ABI.

cache_codec.zig owns bounded canonical scalar schemas and C01 cache-envelope
mechanics for R4NAK/R4ACO. Scalar fields are explicit LE32/LE64; padding and
selected transient fields are canonical zero. Entire schema/header/identity/
digest/capacity/alias admission precedes publication. This pure source helper
allocates nothing and retains no caller memory. Vendor key/ISA/resource
admission and actual compiler identities stay in each compiler provider.
The existing COMPILER_V1:1 cache interfaces expose it to Zig/C/Rust; no new
runtime import is needed. Schema descriptors and all input buffers remain
immutable and mapped through return. Normative contract and C01 identity
limits: Docs/API/CanonicalCacheCodec.txt in the documentation repository.
Targeted new schema cases: Shared/Tests/cache_codec.zig (named cache_codec
module points to this directory's cache_codec.zig); original vendor/compiler
tests and byte fixtures remain independent. No GPU execution is implied.

R4VK consumes threads, locks, memory and process-local storage through its r4native
Zig module. Compiler arenas, job failure policy and private C entrypoint names
remain in R4VK. A native caller requires R4SYS21 and its exact current-thread
identity, plus the existing notification/VM/process-local platform services.

The immutable kernel table, key-token addresses, constant templates and stateless
console identities may be shared across processes. Mutable mutexes, conditions,
published blobs, heaps and TLS payloads belong
to the calling program. Publication initializes region-local data before the
winner becomes visible; a losing initializer releases its own region.

process.modulePath and environmentValue read caller-bound R4SYS metadata into
explicit caller storage, reserve a NUL byte and reject incomplete output.
They do not retain a startup context or supply a getenv pointer lifetime/cache.

process.cpuCapacity optionally requires the R4SYS22 tail. It reads actual
schedulable CPUs and the boot-configured CPU slot count, including failed or
offline slots, without allocation or a CPUID package-count guess. It returns
failure when unavailable, never a fabricated one-CPU fallback. This advisory
snapshot is neither an affinity reservation nor a cache/heterogeneous-core map.

options.Runtime(Memory) provides that lifetime with the consumer's ordinary
process C heap. get reads the current R4SYS value, while getCached fixes the
first successful read, including absence. Names follow R4SYS case-insensitive
comparison; values keep exact bytes. Empty values remain distinct from absence.
All returned strings stay valid until closeAfterUsersStop, even across later
reads, environment updates, thread release or another process's cleanup. Equal
values are interned; old differing values remain until this lifetime ends.
Dynamic reads grow caller storage without truncation. Allocation/read failure
publishes no cache entry; unused map capacity may be retained for retry.

The consumer closes options only after API users, internal workers and final
Mesa/C++ callbacks have stopped using strings. Closing frees all owned strings
and map allocations, rejects subsequent reads and is sequentially idempotent.
It is not a concurrent shutdown or cache-reset operation. Process death retains
the normal kernel VM cleanup. C NULL/default and secure-option policy belongs
to the consumer; R4VK currently retains its explicit fixed-option policy.

math.zig owns native x86_64 rounding, copysign/frexp and the C wrappers for
Zig's musl-derived inverse trigonometric and hyperbolic functions. lrint/llrint/rint follow
the caller's MXCSR rounding mode; lround uses ties away from zero. rint keeps
signed zero and does not convert already integral large finite values to i64.
Zig compiler-rt supplies elementary trig/log/exp, fma, sqrt and basic rounding.
Consumers needing pow/powf and ldexp/ldexpf also link the archive produced by
Math/Build.ps1 from 18 original checksum-pinned bundled musl C units. It uses
strict floating-point evaluation, caller-provided native headers/compiler and
an output directory owned by that build. Sources.json and NOTICES.txt record
the provider and licensing. This covers the selected Mesa math imports; it
does not expose a complete C libc/fenv API or promise C errno semantics.

The C string.c/format.c/stdio.c sources own common string/formatting and memory-
stream algorithms. R4VK includes them through thin private C wrappers and keeps
its compiler abort/assert policy. The base stdio profile routes console output
through the consumer's r4native_console_write and has caller-serialized memory
streams. Formatting uses the existing pinned stb source under R4NAK/ThirdParty/
stb and retains its license; asprintf/vasprintf check allocation and publish
output only after complete formatting.

The optional R4NATIVE_FILE_IO profile adds files.zig/files.h and C11 stream
locks. Bind threads first, then application.bind(raw): the latter validates the
actual process identity and retains a process-owned startup snapshot and Bundle,
never a caller's stack pointer. Platform/import tables retain their ordinary
program lifetime. The application must import R4DESK for console streams.
Compile stdio.c with R4NATIVE_FILE_IO and include native.files in the Zig root;
the base R4VK profile does not acquire this filesystem dependency.

Native FILE objects own a normalized absolute R4OS path and cursor. fopen
captures the actual CWD once; r/w/a, update, binary/text and exclusive-create
modes use the existing SDK storage APIs. Exclusive creation is atomic in VFS.
Read/write waits retain caller buffers until the real I/O request ends and is
closed. Append uses the existing native append operation. Streams have no C
read/write buffering; fflush does not promise fsync or power-loss durability.
A path-based FILE does not pin an inode across rename, removal or replacement.
Separate stream writers require caller coordination when cursor accuracy matters;
append-position observation follows the write. This is not a POSIX file model.

The native profile serializes each stream operation, including a full fprintf,
and keeps its fflush(NULL) registry in the process owner. Memory-stream buffers
remain caller-owned after fclose. Standard-stream identity tokens resolve to
per-process state, so close/error/EOF flags cannot leak between applications.
stdin waits for actual console input; an empty queue is not EOF. An unavailable
console reports failure. fileno only supplies the three console identities;
file/memory streams and FD duplication report unsupported. External-FD EGL/GL
extensions must remain disabled. No synthetic kernel file handles are created.
Closing a stream concurrently with its use is outside the contract. Process-wide
stream cleanup follows quiescence of all users: r4native_stdio_finish flushes
and closes the process registry and standard streams, retaining caller-owned
memory-stream buffers. Its result distinguishes completed cleanup with an I/O
error from an incomplete close requiring retry. Remaining records retain their
mutex identities for retry; a completed call is sequentially idempotent and
rejects subsequent opens/standard-stream operations. R4GL calls this from its
quiescent process-finish path. A failed stream-lock setup permits retry.

process_local.initializedBlob adds one-time construction after publication.
All users of a key wait for the same completed initializer; the unique key's
layout and callback must remain fixed. Initialization may allocate or access
other keys, but may not recursively access its own key. It must return normally
or retire the process; killing only an initializer thread is unsupported.
Final callbacks remain the consumer's responsibility, after all object users
have stopped. This accessor does not run destructors or permit reuse after final
destruction. R4GL's first adapted Mesa owners use this private C boundary.

memory.Runtime provides a process-owned SDK VM heap and C allocation semantics:
malloc/calloc/realloc/free, aligned_alloc and posix_memalign. Size overflow and
failed unscoped allocation return failure; failed resize preserves the original
allocation. C adapters own errno policy. Separate threads of the same process
may transfer ordinary allocations using their application's synchronization.
The optional job scope is confined to its consumer's isolated compiler worker;
its ledger is drained only after that worker has retired. R4VK supplies its
existing arena/failure policy; Unscoped supports long-lived native API objects.
Heap counters track live allocations, not physical pages retained by VM caches.

thread_local.zig implements the four-word compiler-rt emutls control layout.
It never writes the shared descriptor. Initial bytes are copied from its
immutable template, or zeroed; requested power-of-two alignment is preserved.
Descriptors and their templates must remain pinned while TLS can use them.
Failure returns null to the language adapter; no emergency shared TLS exists.

Exact thread generation indexes a process-owned tree. A 64-entry cache keeps
ordinary hits free of a userland registry lock; it is not a thread limit.
Atomic sequence/tag/address reads only publish a pointer for the actual
calling thread, which alone can release that entry. Collision misses use the
tree. Process lookup and exact current identity still use R4SYS. No latency
or throughput claim is made before profiling the full renderer.

releaseCurrent only frees raw current-thread TLS and is idempotent. Its caller
must first unbind API objects and run any required language destructors. Later
use starts again from the template. It is not an automatic thread-exit hook,
Mesa context teardown, C++ static destructor service or EGL implementation.
Whole-process termination retains the normal kernel VM cleanup boundary.

thread_lifecycle.Runtime(Memory, release_api_thread) adds the optional normal
exit path for native C11 workers. Bind its immutable code-only dispatch before
creating workers. R4VK leaves this dispatch unbound and keeps its existing
compiler-worker path. Runtime metadata, admission and worker records remain
process-owned; a growing identity tree uses actual thread generations rather
than a fixed worker limit. Worker entries must be valid absolute function
pointers in code retained by the calling process's import/image lifetime.

Both ordinary worker return and thrd_exit drain registered language destructors
in reverse registration order, release API thread state, then release raw TLS.
Destructors may register more destructors. API cleanup that creates language TLS
causes another drain/unbind pass. No owner lock spans callbacks or cleanup, and
lookup failures never masquerade as absent TLS. A failed cleanup preserves its
remaining state; the void worker-exit boundary fails rather than reporting a
successful teardown. C++ __cxa_thread_atexit adapters belong to the consumer.

closeAdmission prevents new workers; already admitted workers finish normally.
liveWorkers is a logical cleanup count, not proof of kernel task retirement:
join still precedes releasing worker arguments or the library lifetime. Creation
failure preserves the caller's output handle and retires its private start record.
finishCurrent is a terminal thread cleanup operation, not eglReleaseThread and
not an operation to call halfway through a managed worker. Application threads
created outside this native transport require an explicit library thread-scope
cleanup. Process kill retains kernel VM/resource cleanup and does not run foreign
destructors. R4GL binds the worker/API lifecycle and joins before process finish.

finalizers.Runtime(Memory) owns a process-local dynamic LIFO callback list for
one consuming R4L, without a fixed callback capacity. Ordinary atexit callbacks
and private callbacks with arguments share the list. Allocation failure leaves
the list unchanged. finish runs callbacks outside the owner lock; callbacks may
register more callbacks, which run next. Recursive/concurrent finish reports
busy; completed finish is idempotent and rejects further registrations. The
consumer first stops API users and joins workers, then finishes thread/API TLS,
then runs global finalizers while files/options remain available. After that it
closes streams and options and releases any raw TLS recreated by finalizers.
Do not reenter Mesa after its global finalizers. This is not DSO unloading,
exception unwinding or a kernel process-exit hook.

cpp.cpp adapts private C atexit and C++ new-handler storage to those owners.
The consuming R4L implements cpp_runtime.h's state/finalizer/fatal adapters and
retains the callback code for the process lifetime. C++ metadata and its mutex
remain in the process owner until kernel process cleanup; handlers never live
in shared mutable globals. The fatal policy is deliberately consumer-owned.

0.79.39 integrates these owners into R4GL. Its product path covers EGL/Softpipe
pbuffer and WINSVC windows, resize/fullscreen and quiescent process finish.
Native fixtures complement the product SMP4 evidence; they are not independent
hardware or API-conformance certification.

sort.c supplies allocation-free heapsort with caller-stack comparator context,
plain qsort and binary search. Nested calls and parallel callers share no
scratch pointers or sort state. R4VK keeps a thin include wrapper; native Mesa
uses this implementation instead of util/u_qsort.cpp and its TLS comparator.
The algorithms are unchanged from the established R4VK implementation.

numeric.c owns C-locale C11/C17 strtol/strtoll/strtoul/strtoull. It consumes
all valid digits after overflow, reports ERANGE with the appropriate limit,
preserves errno on successful or empty conversions and returns the original
end pointer when no digits match. Invalid bases return zero/EINVAL and the
original pointer. Binary prefixes from C23 are not part of this profile.
R4VK selects its existing compiler-job error owner with R4NATIVE_ERRNO_LOCATION;
ordinary native consumers use errno.c and map their private errno macro to
r4native_errno_location. Compile errno.c with emulated TLS: storage then belongs
to the exact current thread of the consuming R4L and starts at zero, including
after explicit raw TLS release. It is not a shared process error or a public
cross-R4L libc ABI.

Scan/Build.ps1 provides strtof/strtod from checksum-pinned original musl
C units and the R4OS conversion adapter. A private string cursor replaces the
foreign FILE dependency. The internal accumulator uses musl's supported
binary64 long-double configuration and SSE/MXCSR rounding; internal helper and
long-double conversion names are private, with no public strtold ABI. Consumers
also link the native math scalbn provider and Zig compiler-rt fmod.
The adapter preserves the parsed sign for zero after hexadecimal underflow and
reports ERANGE for inexact subnormal results. It distinguishes this call's
inexact status from a prior sticky flag and preserves their union. Decimal/hex
grammar, end-pointer rollback and special values belong to the original scanner;
no conversion returns zero/EINVAL. NaN payload/sign follow the provider, and
only the C numeric locale is supported.

The same archive provides sscanf/vsscanf for Mesa's private narrow C-locale
profile, using an adapted musl format parser and original integer scanner.
Each call owns its read-only cursor and va_list copy. Field widths, suppression,
scansets, character/string fields, integer length modifiers, float/double and
character counts are supported; numbered arguments1..9 and narrow %m allocation
follow the selected provider. Width/growth overflow and allocation failure are
checked. OOM frees an unpublished partial string; successful %m storage belongs
to the caller. Unsupported wide-character or long-double layouts and invalid
format/length combinations return a format error/EINVAL before writing that
destination. This is not a full public C/POSIX scanf or FILE ABI. Incomplete
numeric input items follow scanf matching failure, unlike strto* rollback;
float conversions share the zero-sign/range/sticky-status adapter above.
FILE-based fscanf is not supplied; native fread/fgets belong to the optional
stdio profile described above.

string.c also supplies strrchr/strspn and reentrant strtok_r with caller-owned
cursor storage. tokenize.c provides strtok with an emulated TLS cursor; nested
parsers use strtok_r, and the input buffer must stay alive until tokenization
finishes. Raw TLS release resets the cursor. errno.c returns immutable C-locale
strerror text for the private runtime's admitted error codes and a stable
unknown-code message without changing errno or allocating memory.

random.zig provides the private rand/srand state: default seed 1, deterministic
31-bit nonnegative results, and one atomic sequence per calling process.
Concurrent calls and reseeding linearize at their atomic state changes; thread
scheduling determines which caller receives each result. The consuming C
adapter handles an unavailable process owner explicitly. This is a simple
noncryptographic cache-selection generator, not an OS entropy interface or a
promise to reproduce another libc's sequence.

time.zig owns the common Mesa monotonic clock, absolute deadlines, sleep and
atomic-zero waits previously in R4VK. It uses R4SYS's nanosecond clock and
actual event-frequency ratio; each sleep rechecks the absolute time after wake.
R4VK retains only its Vulkan-specific deadline/tick adapters.

wall_clock.zig adds time/timespec_get and UTC cnd_timedwait. Consumers bind the
normal R4SYS table and provide ZIG_MODULE=r4native_date pointing to the existing
R4STD/Source/date.zig provider source. Calendar conversion remains owned by
R4STD, without retaining an application's runtime binding. UTC currently has
one-second calendar resolution; nanoseconds are zero, never guessed from boot
uptime. Missing/invalid UTC returns failure. UTC condition waits use bounded
monotonic slices, reread UTC after timeout and reacquire the mutex, including
an already expired deadline. Signalling retains ordinary predicate-loop rules.
Invalid timespec fractions fail without releasing the caller's mutex.

system_info.zig binds the immutable R4DEV table and reads actual memory-pressure
snapshots. Total memory is managed physical RAM; available memory is a
conservative minimum of application-available RAM and commit headroom, preserving
the system reserve. This advisory value neither reserves memory nor guarantees
future allocation success. Missing/invalid snapshots return failure without
writing output. The page size is the existing x86_64 R4SYS 4-KiB contract.

window.zig owns process-bound WINSVC query/request/wait and service-generation
checks shared by native graphics libraries. Each call closes its independent
endpoint; it retains no caller Bundle or mutable connection. Query validates
the exact process/window/service incarnation. Mutation serials, unknown-reply
retries, buffer loans and retirement remain in each graphics producer. Calls
use finite IPC deadlines; wait slices are capped at 25 ms. R4VK retains only
its private exported C names as thin wrappers.

c_runtime.h and c11_threads.h own the private native C declarations shared by
R4GL, R4VIDEO and R4ENC. R4GL retains thin include wrappers at its
existing paths. The declarations were moved byte-for-byte in 0.79.40; native
consumers still select and bind their own implementations and process owners.

calendar.zig is a private UTC C adapter over R4STD date arithmetic. gmtime_r /
localtime_r use caller storage; mktime normalizes calendar fields within years
1..9999. No host timezone or shared tm object is introduced. The bounded
strftime adapter supports the numeric UTC log formats Y/y/m/d/H/M/S/j, z/Z,
percent, newline and tab; unsupported directives or insufficient storage
return zero. It is not a full locale/POSIX libc. R4VIDEO consumes it together
with R4SYS wall/monotonic time. R4VIDEO keeps its concurrent allocation budget
outside memory.Runtime's isolated compiler-job Scope.

budget.zig/budgeted_allocation.zig hold finite atomic leaf/aggregate limits and
allocation headers carrying the original owner across worker free/realloc.
budgeted_memory.Runtime(Policy, Allocation) binds those algorithms to the
calling program's VM heap. R4VIDEO and R4ENC select their stream through Policy;
they retain the budget until all allocations, workers and BO loans retire.
This is the existing decoder accounting moved into the shared owner in 0.79.41,
not a second allocator implementation or a new public API.

gpu_resources.zig is the common single-worker GPU BO/VA/queue owner used by
R4VIDEO and the R4ENC native session. native_allocation is the shared budget
module identity. Device.queryFor selects decode, encode or validated GR packet classes and
engine masks, preserving the driver's actual channel admission. Timeout retains
the fence and physical resource loans; CPU access/reuse is forbidden until
completion, and BO/VA budgets survive delayed retirement. Tests/gpu_model.zig
provides the common SDK-dispatch fixture inside the existing codec cases.
Codec-specific parameter/status inspection remains in each library's tests.
Borrowed resources own only their VA, with no duplicate budget charge or
reference release. Their retained input/session owner must survive physical
retirement. An optional shared job deadline bounds preparation and encoding.
