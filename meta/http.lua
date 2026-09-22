---@meta

---Sets the HTTP content type header for the current context.
---@param type "application/json" | "text/html" | "text/plain" | "application/x-www-form-urlencoded" | "multipart/form-data" | string The MIME content type.
function http_content_type(type) end

---@alias HttpStatusCode
---| 100 # Continue
---| 101 # Switching Protocols
---| 200 # OK
---| 201 # Created
---| 202 # Accepted
---| 204 # No Content
---| 301 # Moved Permanently
---| 302 # Found
---| 304 # Not Modified
---| 400 # Bad Request
---| 401 # Unauthorized
---| 403 # Forbidden
---| 404 # Not Found
---| 405 # Method Not Allowed
---| 408 # Request Timeout
---| 409 # Conflict
---| 422 # Unprocessable Entity
---| 429 # Too Many Requests
---| 500 # Internal Server Error
---| 502 # Bad Gateway
---| 503 # Service Unavailable
---| 504 # Gateway Timeout
---| integer

---Sets the HTTP response status code.
---@param status HttpStatusCode The HTTP status code to set.
function http_set_status(status) end

---Adds one or more header values for a specified HTTP header key.
---@param key string The HTTP header name (e.g., "Set-Cookie", "Accept").
---@param ... string One or more header values to attach to the key.
function http_header_add(key, ...) end