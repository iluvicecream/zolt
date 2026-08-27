# Request

The `request` table exposes information about the current HTTP request.

## path

`request.path()` returns the path portion of the requested URL, without the
query string or fragment:

```luau
echo(request.path());
```

```text
GET /hello.luau       -> "/hello.luau"
GET /hello.luau?x=1   -> "/hello.luau"
GET /sub/             -> "/sub/"
GET /                 -> "/"
```
