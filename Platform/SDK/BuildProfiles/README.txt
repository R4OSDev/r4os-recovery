R4OS SDK Build Profiles
=======================

These files describe installable build profiles for R4OS-internal tools such
as R4CODE and R4BUILD.

Profiles are not a second ABI definition. They point to the installed SDK and
Contract under C:/R4OS/SDK; the separate Contract repository remains the API
and ABI source of truth.

Current internal C profiles include:

  R4X_C_Console
  R4X_C_Desktop_OK

R4X_C_Desktop_OK builds a GUI R4X with R4SYS, R4DESK, and R4DRAW imports and
AppClass gui. R4X_C remains readable for external R4CodePad compatibility,
while internal builds use the more precise profiles.

AVX2 is part of the standard SIMD profile for R4X, R4D, and R4P artifacts
when R4OS enables the x87, SSE, and YMM XSAVE state. These profiles do not
provide an SSE-only or soft-float fallback.
