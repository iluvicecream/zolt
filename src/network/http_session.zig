const std = @import("std");

const Io = std.Io;

pub const Handler = *const fn (ctx: *anyopaque, io: Io, allocator: std.mem.Allocator, req: *std.http.Server.Request) anyerror!void;

pub const HttpSession = struct {
    io: Io,
    server: Io.net.Server,
    ctx: *anyopaque,
    handler: Handler,
    allocator: std.mem.Allocator,

    pub fn init(io: Io, addr: Io.net.IpAddress, allocator: std.mem.Allocator, ctx: *anyopaque, handler: Handler) !HttpSession {
        return .{
            .io = io,
            .server = try addr.listen(io, .{}),
            .ctx = ctx,
            .handler = handler,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *HttpSession) void {
        self.server.deinit(self.io);
        self.* = undefined;
    }

    pub fn run(self: *HttpSession) !void {
        while (true) {
            const stream = try self.server.accept(self.io);
            self.handleConn(stream) catch |err| {
                std.log.err("http conn error err={}", .{err});
            };
        }
    }

    fn handleConn(self: *HttpSession, stream: Io.net.Stream) !void {
        defer stream.close(self.io);

        var read_buffer: [4096]u8 = undefined;
        var reader_impl = stream.reader(self.io, &read_buffer);
        var write_buffer: [4096]u8 = undefined;
        var writer_impl = stream.writer(self.io, &write_buffer);

        var http_server = std.http.Server.init(&reader_impl.interface, &writer_impl.interface);

        while (true) {
            var req = http_server.receiveHead() catch |err| switch (err) {
                error.HttpConnectionClosing => return,
                else => {
                    std.log.debug("http receive head error err={}", .{err});
                    return;
                },
            };
            std.log.debug("http received request method={} target={s}", .{ req.head.method, req.head.target });

            self.handler(self.ctx, self.io, self.allocator, &req) catch |err| {
                std.log.err("http handler error err={}", .{err});
                return;
            };

            if (req.server.reader.state != .ready) return;
        }
    }
};
