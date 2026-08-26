# zolt

A minimal application server written in Zig with Luau as the scripting
language. Routes are plain `.luau` files: a request for `/hello.luau` reads
`./hello.luau`, executes it, and serves its output. Think "PHP but Lua".

## Requirements

- [Zig](https://ziglang.org/) 0.16.0 (see `build.zig.zon`)
- Luau is pulled in as a build dependency and fetched automatically on the
  first `zig build` (network required once; already fetched in `zig-pkg/`)

## Build and run

```sh
zig build          # build ./zig-out/bin/zoltd
zig build run      # build and run
```

The server reads its configuration from the first command-line argument , falling back to `config.luau` in
the working directory when no argument is given:

```sh
./zoltd {path_to_config}
```

## Get Started

Learn how to use zolt to build simple web app at /zolt-doc

## Configuration

loaded once at startup and must return a table with a `host` field:

```lua
return {
    host = "127.0.0.1:8081",
    -- isShowRuntimeError = true, -- display trace for error in response or not
    -- maxConnections = 64,       -- concurrent connections
}
```

## Project layout

```text
src/
├── main.zig                 # entry point: config, per-connection route handler factory
├── root.zig                 # package root exposing zolt modules
├── route.zig                # route resolution, script cache, response wiring
├── config/config.zig        # config.lua loading
├── runtime/
│   ├── runtime.zig          # Lua runtime: VM, sandbox environments, script execution
│   ├── luau.zig             # Luau C API bindings
│   └── packages/
│       ├── echo.zig         # `echo` host function package
│       ├── response.zig     # `status`/`header` response control package
│       └── require.zig      # `require` module loader package
├── network/http_session.zig # accept loop, thread-per-connection dispatch
└── protocol/http_rsp.zig    # response model
```
