# Responses

Zolt scripts build the HTTP response with three host functions: `echo` for the
body, `status` for the status code, and `header` for response headers. They all
operate on the same response object the server sends.

## echo

`echo` appends text to the response body. It can be called with or without
parentheses:

```luau
echo "Hello";
echo("Hello");
echo("a" .. " " .. "b");
```

When a script writes a body, the response defaults to `200 OK` with
`content-type: text/html; charset=utf-8` unless the script sets its own
`content-type` header.

## status

`status(code)` sets the HTTP status code. Any standard code in 100-599 is
accepted:

```luau
status(201);
status(404);
status(500);
```

The status code must be an integer in the supported HTTP range; anything else
raises an error.

## header

`header(name, value)` adds a response header:

```luau
header("content-type", "text/plain");
header("X-Powered-By", "zolt");
header("Set-Cookie", "session=abc123; HttpOnly");
```

Header names are case-insensitive. Each request supports up to 8 headers.

## Example

```luau
status(201);
header("content-type", "application/json");
echo('{"ok": true}');
```

Response:

```text
HTTP/1.1 201 Created
content-type: application/json
content-length: 14
```
