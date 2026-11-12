#include "graph.h"
extern uint64_t r4_graph_second(uint64_t);
uint64_t r4_graph_mix(uint64_t value) {
    return r4_graph_second(value) + R4_GRAPH_BIAS;
}
