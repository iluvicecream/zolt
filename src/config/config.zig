const std = @import("std");

const Io = std.Io;
const Dir = Io.Dir;

pub const Config = struct {
    content: []const u8,

    pub const max_content_size = 16 * 1024;

    pub fn load(io: Io, allocator: std.mem.Allocator) !Config {
        const content = try Dir.readFileAlloc(.cwd(), io, "config.lua", allocator, .limited(max_content_size));
        std.log.info("config.lua loaded len={d}", .{content.len});
        return .{ .content = content };
    }

    pub fn deinit(self: *Config, allocator: std.mem.Allocator) void {
        allocator.free(self.content);
        self.* = undefined;
    }
};
