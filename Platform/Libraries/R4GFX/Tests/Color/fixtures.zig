//! Original synthetic ICC fixtures, reproduced by GenerateFixtures.ps1.
pub const lut = @embedFile("Fixtures/lut-display.icc");
pub const calibrated = @embedFile("Fixtures/vcgt-display.icc");
pub const descending = @embedFile("Fixtures/vcgt-descending.icc");
