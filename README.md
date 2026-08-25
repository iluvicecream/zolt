# zolt

A minimal HTTP application server written in Zig with Luau as the scripting
language. Routes are plain `.lua` files: a request for `/hello.lua` reads
`./hello.lua`, executes it, and serves its output. Think "PHP but Lua".

## Requirements

- [Zig](https://ziglang.org/) 0.16.0 (see `build.zig.zon`)
- Luau is pulled in as a build dependency and fetched automatically on the
  first `zig build` (network required once; already fetched in `zig-pkg/`)

## Build and run

```sh
zig build          # build ./zig-out/bin/zoltd
zig build run      # build and run
```

The server binds to the host configured in `config.lua` (default `127.0.0.1:8081`), then serves requests until stopped.

## Configuration

`config.lua` in the working directory is loaded once at startup and must
return a table with a `host` field:

```lua
return {
    host = "127.0.0.1:8081",
}
```

## Writing handlers

Handlers are Luau scripts in the working directory. Two output styles are
supported.

Return a table with a `response` field:

```lua
return {
    response = "hello from lua!",
}
```

Or build the body with `echo` — the echo style may be all the script does:

```lua
local name = "zolt"
echo("The value of name is: ", name)
```

If a script calls `echo`, its output is the response body; otherwise the
returned table's `response` field is used. Scripts run in Luau's typed mode,
so Luau's type annotations work too.

## Runtime API

The host exposes a small runtime to handler scripts, registered into each
request's sandbox environment:

- `echo(...)` — appends each stringifiable argument to the response body.
  Numbers are converted to strings; values that cannot be stringified are
  skipped. Returns nothing.

## Limits

- Handler source: 16 KB per file (`max_content_size`)
- `echo` output: 16 KB per request
- HTTP request headers must fit in the 4 KB read buffer
- The server is single-threaded: connections are handled one at a time,
  though each connection serves multiple keep-alive requests

## Project layout

```text
src/
├── main.zig               # entry point: config, route handler, server setup
├── root.zig               # package root exposing zolt modules
├── route.zig              # route resolution, sandbox environments, runtime API
├── config/config.zig      # config.lua loading
├── luau/luau.zig          # Luau C API bindings
├── network/http_session.zig # accept loop, keep-alive connection handling
└── protocol/http_rsp.zig  # response model
```

