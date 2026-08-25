const std = @import("std");
const http = std.http;

pub const HttpRsp = struct {
    content: []const u8,
    status: http.Status = .ok,
    reason: ?[]const u8 = null,
    extra_headers: []const http.Header = &.{},

    pub fn toContent(self: HttpRsp) []const u8 {
        return self.content;
    }

    pub fn toRespondOptions(self: HttpRsp) http.Server.Request.RespondOptions {
        return .{
            .status = self.status,
            .reason = self.reason,
            .extra_headers = self.extra_headers,
        };
    }
};
