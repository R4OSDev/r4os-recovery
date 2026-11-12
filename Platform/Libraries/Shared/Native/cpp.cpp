// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
#include <new>
#include <mutex>
#include <__verbose_abort>
#include "cpp_runtime.h"

// No shared process handler or fixed-capacity exit list. Immutable library
// keys address process-owned state; notifications retire with that process.
struct State { std::mutex gate; std::new_handler handler; };
static const char state_key = 0;
static void initialize(void *data) { new(data) State{}; }
static State &state() {
   void *value = r4native_cpp_state(&state_key, sizeof(State), alignof(State), initialize);
   if (!value) r4native_fatal("C++ process state unavailable");
   return *static_cast<State *>(value);
}
extern "C" int atexit(void (*callback)()) { return r4native_register_finalizer(callback); }
namespace std {
new_handler get_new_handler() noexcept {
   auto &s = state(); std::lock_guard<std::mutex> lock(s.gate); return s.handler;
}
new_handler set_new_handler(new_handler next) noexcept {
   auto &s = state(); std::lock_guard<std::mutex> lock(s.gate);
   auto old = s.handler; s.handler = next; return old;
}
}
_LIBCPP_BEGIN_NAMESPACE_STD
[[noreturn]] void __libcpp_verbose_abort(const char *message, ...) noexcept { r4native_fatal(message); }
[[noreturn]] void __throw_system_error(int, const char *message) { r4native_fatal(message); }
_LIBCPP_END_NAMESPACE_STD
extern "C" [[noreturn]] void __cxa_pure_virtual() { r4native_fatal("pure virtual call"); }
