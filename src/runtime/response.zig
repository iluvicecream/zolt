const std = @import("std");

pub const max_size = 16 * 1024;

pub const Response = struct {
    buf: [max_size]u8 = undefined,
    len: usize = 0,
    used: bool = false,
    overflowed: bool = false,

    pub fn reset(self: *Response) void {
        self.len = 0;
        self.used = false;
        self.overflowed = false;
    }

    pub fn append(self: *Response, s: []const u8) void {
        self.used = true;
        if (self.overflowed or s.len > self.buf.len - self.len) {
            self.overflowed = true;
            return;
        }
        @memcpy(self.buf[self.len..][0..s.len], s);
        self.len += s.len;
    }

    pub fn slice(self: *const Response) []const u8 {
        return self.buf[0..self.len];
    }
};
