//! Compiler-free R4MF planning checks only declared files. Cargo itself owns
//! TOML, crate identities, features and dependency resolution in the builder.
//! Host build steps remain explicit SDK operations, never ambient build.rs.
pub const forbidden_inputs = [_][]const u8{ "build.rs", ".cargo/config", ".cargo/config.toml", "rust-toolchain", "rust-toolchain.toml", "src/main.rs", "src/bin", "examples", "tests", "benches" };
