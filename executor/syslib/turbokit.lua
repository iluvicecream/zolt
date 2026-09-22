local HTML = require("@htmlkit")

local Turbo = {}

---@param id string
---@param ... OptionalNodeChild
---@return Node
function Turbo.frame(id, ...)
    local node = HTML.el("turbo-frame"):id(id)
    return node:child(...)
end

---@param id string
---@param src string
---@param ... OptionalNodeChild
---@return Node
function Turbo.lazy_frame(id, src, ...)
    local node = Turbo.frame(id, ...):attr("src", src):attr("loading", "lazy")
    return node
end

return Turbo
