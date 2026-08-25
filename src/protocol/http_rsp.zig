const std = @import("std");
const http = std.http;

pub const HttpRsp = struct {
    content: []const u8,
    status: http.Status,
    reason: ?[]const u8 = null,

    pub fn toContent(self: *HttpRsp) []const u8 {
        return self.content;
    }

    pub fn toRespondOptions(self: *HttpRsp) http.Server.Request.RespondOptions {
        const ret: http.Server.Request.RespondOptions = .{ .status = self.status, .reason = self.reason };

        return ret;
    }
};
