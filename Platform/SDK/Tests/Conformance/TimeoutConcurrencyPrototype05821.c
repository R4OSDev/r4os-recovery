#include <r4os/r4os.h>

int main(void) {
    uint64_t ticks = 99u;
    R4Timeout poll = r4_timeout_poll();
    R4Timeout finite = r4_timeout_finite((R4Duration){10u});
    R4Timeout forever = r4_timeout_forever();
    if (r4_timeout_to_ticks(poll, 1000u, &ticks) != R4OS_OK || ticks != 0u) return 1;
    if (r4_timeout_to_ticks(finite, 1000u, &ticks) != R4OS_OK || ticks != 1u) return 2;
    if (r4_timeout_to_ticks(forever, 1000u, &ticks) != R4OS_OK || ticks != R4OS_IO_WAIT_FOREVER) return 3;
    R4Deadline deadline; int is_forever = 0;
    if (r4_timeout_deadline(finite, (R4MonotonicInstant){100u}, &deadline, &is_forever) != R4OS_OK || is_forever || deadline.nanoseconds != 110u) return 4;
    if (r4_remaining_ticks(deadline, (R4MonotonicInstant){110u}, 1000u, &ticks) != R4OS_OK || ticks != 0u) return 5;
    R4StopFlag stop;
    r4_stop_flag_init(&stop);
    if (r4_stop_flag_requested(&stop)) return 6;
    r4_stop_flag_request(&stop);
    if (!r4_stop_flag_requested(&stop)) return 7;
    if (r4_wait_classify(-8, -8, -9, -10) != R4_WAIT_TIMED_OUT) return 8;
    if (R4_SERVICE_STOP_KILL_AFTER_GRACE != R4OS_SERVICE_STOP_POLICY_KILL_AFTER_GRACE) return 9;
    R4Desk desk = {0};
    uint64_t generation = 99u;
    if (r4desk_console_input_wait(&desk, 7u, 0u, &generation) != R4OS_CONSOLE_INPUT_WAIT_ERROR_UNSUPPORTED || generation != 7u) return 10;
    return 0;
}
