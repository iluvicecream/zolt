# Require

Zolt supports splitting your app into modules with the `require` function.
Modules are plain `.luau` or `.lua` files that return their exports.

## Basic usage

`math.luau`:

```luau
local M = {}

function M.add(a: number, b: number): number
    return a + b
end

return M
```

`index.luau`:

```luau
local math = require("./math");
echo(math.add(5, 10));
```

The path is resolved relative to the file calling `require`, so `require("./math")`
inside `sub/route.luau` looks for `sub/math.luau`, and `require("../lib/util")`
looks for `lib/util.luau`.

## Path rules

- Paths must stay inside the working directory. Absolute paths and `..`
  segments that escape the working directory are rejected.
- If the path has no extension, Zolt tries the exact name, then `.luau`, then
  `.lua`. `require("./math")` and `require("./math.luau")` are equivalent when
  `math.luau` exists.

## Module semantics

- A module must return its exports. `return {}` is the common pattern; a module
  that returns nothing (or `nil`) raises an error.
- Modules are cached per request. Requiring the same file twice in one request
  returns the same table, and the module body only runs once per request.
- Modules are executed again on every request, so they do not hold state
  between requests.
- Cyclic requires are detected and raise an error:

  ```luau
  -- a.luau
  local b = require("./b")

  -- b.luau
  local a = require("./a") -- error: cyclic dependency
  ```

- Modules run in the same sandbox as routes, so `echo`, `require`, and other
  host functions are available inside them.
