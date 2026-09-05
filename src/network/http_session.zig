const std = @import("std");

const Io = std.Io;

pub const Handler = *const fn (ctx: *anyopaque, io: Io, allocator: std.mem.Allocator, req: *std.http.Server.Request) anyerror!void;

pub const ConnHandler = struct {
    ctx: *anyopaque,
    init: *const fn (ctx: *anyopaque, allocator: std.mem.Allocator) anyerror!*anyopaque,
    handle: Handler,
    deinit: *const fn (ctx: *anyopaque) void,
};

pub const HttpSession = struct {
    io: Io,
    server: Io.net.Server,
    allocator: std.mem.Allocator,
    conn_handler: ConnHandler,
    max_connections: usize,
    conn_slots: Io.Semaphore = .{ .permits = 0 },

    pub fn init(
        io: Io,
        addr: Io.net.IpAddress,
        allocator: std.mem.Allocator,
        conn_handler: ConnHandler,
        max_connections: usize,
    ) !HttpSession {
        const limit = @max(max_connections, 1);
        return .{
            .io = io,
            .server = try addr.listen(io, .{ .reuse_address = true }),
            .allocator = allocator,
            .conn_handler = conn_handler,
            .max_connections = limit,
            .conn_slots = .{ .permits = limit },
        };
    }

    pub fn deinit(self: *HttpSession) void {
        self.server.deinit(self.io);
        self.* = undefined;
    }

    pub fn run(self: *HttpSession) !void {
        while (true) {
            Io.Semaphore.waitUncancelable(&self.conn_slots, self.io);

            const stream = self.server.accept(self.io) catch |err| {
                Io.Semaphore.post(&self.conn_slots, self.io);
                std.log.err("accept error err={}", .{err});
                continue;
            };

            self.spawnConnection(stream) catch |err| {
                Io.Semaphore.post(&self.conn_slots, self.io);
                stream.close(self.io);
                std.log.err("failed to spawn connection thread err={}", .{err});
            };
        }
    }

    fn spawnConnection(self: *HttpSession, stream: Io.net.Stream) !void {
        const thread = try std.Thread.spawn(.{}, connectionThread, .{
            self.io,
            self.allocator,
            self.conn_handler,
            stream,
            &self.conn_slots,
        });
        thread.detach();
    }

    fn connectionThread(io: Io, allocator: std.mem.Allocator, conn_handler: ConnHandler, stream: Io.net.Stream, slots: *Io.Semaphore) void {
        defer Io.Semaphore.post(slots, io);
        handleConn(io, allocator, conn_handler, stream) catch |err| {
            std.log.err("http conn error err={}", .{err});
        };
    }

    fn handleConn(io: Io, allocator: std.mem.Allocator, conn_handler: ConnHandler, stream: Io.net.Stream) !void {
        defer stream.close(io);

        const ctx = try conn_handler.init(conn_handler.ctx, allocator);
        defer conn_handler.deinit(ctx);

        var read_buffer: [4096]u8 = undefined;
        var reader_impl = stream.reader(io, &read_buffer);
        var write_buffer: [4096]u8 = undefined;
        var writer_impl = stream.writer(io, &write_buffer);

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

            conn_handler.handle(ctx, io, allocator, &req) catch |err| {
                std.log.err("http handler error err={}", .{err});
                return;
            };

            if (req.server.reader.state != .ready) return;
        }
    }
};
