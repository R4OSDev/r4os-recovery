R4OS SDK Linux Host Profile
===========================

This directory defines the external Linux build wrapper for the shared SDK
core. Linux does not receive a separate ABI layer. Only tool paths, script
names, runners, and packaging may differ; R4XStart, R4L, R4M0, linker
profiles, headers, and Zig bindings remain identical across hosts.
