const std = @import("std");

const Io = std.Io;

pub const Handler = *const fn (req: *std.http.Server.Request) anyerror!void;

pub const HttpSession = struct {
    io: Io,
    server: Io.net.Server,
    handler: Handler,

    pub fn init(io: Io, addr: Io.net.IpAddress, handler: Handler) !HttpSession {
        return .{
            .io = io,
            .server = try addr.listen(io, .{}),
            .handler = handler,
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
        var req = try http_server.receiveHead();
        std.log.debug("http received request method={} target={s}", .{ req.head.method, req.head.target });

        try self.handler(&req);
    }
};
