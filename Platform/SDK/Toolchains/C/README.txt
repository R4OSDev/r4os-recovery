R4OS SDK C Toolchain
====================

The native R4OS C toolchain is installed at

    C:/R4OS/SDK/Toolchains/C

R4CC.R4X is installed under bin. R4CC is an R4OS bootstrap compiler. The
native path uses the shared R4CC and R4Pack cores pinned by R4BUILD.

The R4MF v2 C application subset uses R4App2 and the SDK templates under
Templates/R4OS. The console template uses R4SdkStdio2 and an explicit
R4SdkStdioWrite loop with confirmed byte counts, WouldBlock and Close.

R4CC emits raw text-section bytes for R4XStart2 and Query2. R4BUILD uses
the R4Pack core to create an R4M0 .R4X in the project's out directory.
Console projects declare R4SYS:Query2:2 and R4DESK:Query2:2. GUI projects
also declare R4DRAW:Query2:2 and use the existing facade and activity loop.

The native profiles are R4X_C2_Console and R4X_C2_Desktop_OK. The shared
capability query admits one C source and the supported console/GUI subset.
Other languages, entry modes and module roles report their capability result.

R4CC.STATUS records installed toolchain capabilities for R4BUILD. Worker
builds execute the shared compiler and packer logic in their own process.

The bin directory contains executable toolchain programs. The lib and
include-extra directories provide the established locations for runtime
objects and toolchain-specific headers.
