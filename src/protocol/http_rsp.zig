const std = @import("std");
const http = std.http;

pub const max_body_size = 16 * 1024;
pub const max_headers = 8;
pub const max_header_storage = 1024;

pub const HttpRsp = struct {
    body: [max_body_size]u8 = undefined,
    body_len: usize = 0,
    body_used: bool = false,
    body_overflowed: bool = false,

    status: http.Status = .ok,
    reason: ?[]const u8 = null,

    headers: [max_headers]http.Header = undefined,
    header_count: usize = 0,
    header_storage: [max_header_storage]u8 = undefined,
    header_storage_len: usize = 0,

    pub fn reset(self: *HttpRsp) void {
        self.body_len = 0;
        self.body_used = false;
        self.body_overflowed = false;
        self.status = .ok;
        self.reason = null;
        self.header_count = 0;
        self.header_storage_len = 0;
    }

    pub fn append(self: *HttpRsp, s: []const u8) void {
        self.body_used = true;
        if (self.body_overflowed or s.len > max_body_size - self.body_len) {
            self.body_overflowed = true;
            return;
        }
        @memcpy(self.body[self.body_len..][0..s.len], s);
        self.body_len += s.len;
    }

    pub fn setStatus(self: *HttpRsp, status: http.Status, reason: ?[]const u8) void {
        self.status = status;
        self.reason = reason;
    }

    pub fn setHeader(self: *HttpRsp, name: []const u8, value: []const u8) bool {
        if (!isValidHeaderName(name) or !isValidHeaderValue(value)) return false;
        if (self.header_count >= self.headers.len) return false;
        const name_copy = self.storeHeaderString(name) orelse return false;
        const value_copy = self.storeHeaderString(value) orelse return false;
        self.headers[self.header_count] = .{ .name = name_copy, .value = value_copy };
        self.header_count += 1;
        return true;
    }

    pub fn hasHeader(self: *const HttpRsp, name: []const u8) bool {
        for (self.headers[0..self.header_count]) |h| {
            if (std.ascii.eqlIgnoreCase(h.name, name)) return true;
        }
        return false;
    }

    pub fn toContent(self: *const HttpRsp) []const u8 {
        return self.body[0..self.body_len];
    }

    pub fn toRespondOptions(self: *const HttpRsp) http.Server.Request.RespondOptions {
        return .{
            .status = self.status,
            .reason = self.reason,
            .extra_headers = self.headers[0..self.header_count],
        };
    }

    fn storeHeaderString(self: *HttpRsp, s: []const u8) ?[]const u8 {
        if (s.len > max_header_storage - self.header_storage_len) return null;
        const start = self.header_storage_len;
        @memcpy(self.header_storage[start..][0..s.len], s);
        self.header_storage_len += s.len;
        return self.header_storage[start..self.header_storage_len];
    }

    pub fn isValidHeaderName(name: []const u8) bool {
        if (name.len == 0) return false;
        for (name) |c| {
            if (!isTokenChar(c)) return false;
        }
        return true;
    }

    pub fn isValidHeaderValue(value: []const u8) bool {
        for (value) |c| {
            if (c == 0x09) continue; // HTAB
            if (c < 0x20 or c == 0x7f) return false; // CTLs
        }
        return true;
    }

    fn isTokenChar(c: u8) bool {
        return switch (c) {
            'a'...'z',
            'A'...'Z',
            '0'...'9',
            '!',
            '#',
            '$',
            '%',
            '&',
            '\'',
            '*',
            '+',
            '-',
            '.',
            '^',
            '_',
            '`',
            '|',
            '~',
            => true,
            else => false,
        };
    }
};
