---@meta

---@class HttpRequestHeader
---@field [string] string Value for the specified HTTP header.

---@class HttpRequest
---@field path string The requested path (e.g., "index.lua" , "login.lua").
---@field method "GET" | "POST" | "PUT" | "DELETE" | "PATCH" | "HEAD" | "OPTIONS" | string The HTTP request method.
---@field ip string The client IP address (e.g., "192.168.1.1").
---@field header HttpRequestHeader Table containing HTTP request headers.

---Global request object available in the runtime environment without requiring a module.
---@type HttpRequest
http_request = {}
