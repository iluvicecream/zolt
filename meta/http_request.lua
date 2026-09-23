---@meta

---@class HttpUrlValuePair
---@field [string] string The request parameter's name or URL value.

---@class HttpRequest
---@field path string The requested path (e.g., "index.lua" , "login.lua").
---@field method "GET" | "POST" | "PUT" | "DELETE" | "PATCH" | "HEAD" | "OPTIONS" | string The HTTP request method.
---@field ip string The client IP address (e.g., "192.168.1.1").
---@field header HttpUrlValuePair Table containing HTTP request headers.
---@field query HttpUrlValuePair The URL query parameters if present.
---@field form HttpUrlValuePair The form data in the request body (when method is POST or PUT).

---Global request object available in the runtime environment without requiring a module.
---@type HttpRequest
http_request = {}
