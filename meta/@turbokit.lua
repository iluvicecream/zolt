---@meta

local turbo = {}

---Creates a Hotwire Turbo frame with the given ID.
---@param id string
---@param ... OptionalNodeChild
---@return Node
function turbo.frame(id, ...) end

---Creates a lazy-loading Hotwire Turbo frame with the given ID and source.
---@param id string
---@param src string
---@param ... OptionalNodeChild
---@return Node
function turbo.lazy_frame(id, src, ...) end

return turbo
