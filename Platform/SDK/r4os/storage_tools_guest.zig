//! Guest adapter: every physical write remains within a live R4SYS claim.
const storage = @import("storage.zig");
const abi = @import("r4os_contract").abi;
const block = @import("storage_tools/io.zig");

pub const Target = struct {
    storage: storage.Context,
    target: abi.StorageTarget,
    claim: u64 = 0,

    pub fn acquire(self: *Target) i32 {
        if (self.claim != 0) return abi.storage_error_busy;
        return self.storage.claimBegin(&self.target, &self.claim);
    }

    pub fn release(self: *Target, keep_unmounted: bool) i32 {
        if (self.claim == 0) return abi.storage_result_ok;
        return self.storage.claimEnd(&self.claim, keep_unmounted);
    }

    pub fn device(self: *Target, progress: ?*block.Progress) block.Device {
        return .{
            .context = self,
            .sectors = self.target.sector_count,
            .exclusive = self.claim != 0,
            .read_fn = read,
            .write_fn = write,
            .flush_fn = flush,
            .progress = progress,
        };
    }

    fn read(raw: *anyopaque, lba: u64, bytes: []u8) i32 {
        const self: *Target = @ptrCast(@alignCast(raw));
        if (self.claim != 0) return self.storage.claimRead(self.claim, lba, bytes);
        return self.storage.read(&self.target, lba, bytes);
    }

    fn write(raw: *anyopaque, lba: u64, bytes: []const u8) i32 {
        const self: *Target = @ptrCast(@alignCast(raw));
        if (self.claim == 0) return abi.storage_error_owner;
        return self.storage.claimWrite(self.claim, lba, bytes);
    }

    fn flush(raw: *anyopaque) i32 {
        const self: *Target = @ptrCast(@alignCast(raw));
        if (self.claim == 0) return abi.storage_error_owner;
        return self.storage.claimFlush(self.claim);
    }
};
