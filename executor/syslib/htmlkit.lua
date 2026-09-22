local HTML = {}

---@alias Attributes table<string, string|boolean>
---@alias StyleTable table<string, string>

---@alias PrimitiveChild string|number|boolean
---@alias NodeChild Node|PrimitiveChild
---@alias OptionalNodeChild NodeChild|boolean|nil

---@class Node
---@field tag_name string
---@field attributes Attributes
---@field classes string[]
---@field children_list (Node|PrimitiveChild)[]
local NodeClass = {}
NodeClass.__index = NodeClass

---@class Document
---@field private _lang string
---@field private _title string
---@field private _metas Attributes[]
---@field private _styles string[]
---@field private _scripts Attributes[]
---@field private _body Node
local DocClass = {}
DocClass.__index = DocClass

local ESCAPE_MAP = {
    ["&"] = "&amp;",
    ["<"] = "&lt;",
    [">"] = "&gt;",
    ['"'] = "&quot;",
    ["'"] = "&#39;"
}

---@param val any
---@return string
local function escape_html(val)
    return (string.gsub(tostring(val or ""), '[&<>"\']', ESCAPE_MAP))
end

local VOID_TAGS = {
    meta=true, link=true, img=true, input=true, br=true, hr=true,
    area=true, base=true, col=true, embed=true, param=true, source=true, track=true, wbr=true
}

---@param tag string
---@return Node
function HTML.el(tag)
    local self = setmetatable({}, NodeClass)
    self.tag_name = string.lower(tag)
    self.attributes = {}
    self.classes = {}
    self.children_list = {}
    return self
end

---@param val string
---@return Node
function NodeClass:id(val)
    self.attributes["id"] = val
    return self
end

---@param ... string|nil
---@return Node
function NodeClass:class(...)
    for i = 1, select("#", ...) do
        local c = select(i, ...)
        if type(c) == "string" and c ~= "" then
            table.insert(self.classes, c)
        end
    end
    return self
end

---@param key string
---@param value? string|boolean
---@return Node
function NodeClass:attr(key, value)
    if value ~= nil and value ~= false then
        self.attributes[key] = (value == true) and key or value
    end
    return self
end

---@param styles StyleTable|string
---@return Node
function NodeClass:style(styles)
    if type(styles) == "table" then
        local parts = {}
        for k, v in pairs(styles) do
            table.insert(parts, k .. ":" .. v)
        end
        self.attributes["style"] = table.concat(parts, ";")
    elseif type(styles) == "string" then
        self.attributes["style"] = styles
    end
    return self
end

---@param val? string|number
---@return Node
function NodeClass:text(val)
    if val ~= nil then
        table.insert(self.children_list, escape_html(val))
    end
    return self
end

---@param raw_html? string
---@return Node
function NodeClass:raw(raw_html)
    if raw_html ~= nil then
        table.insert(self.children_list, tostring(raw_html))
    end
    return self
end

---@param ... OptionalNodeChild
---@return Node
function NodeClass:child(...)
    for i = 1, select("#", ...) do
        local item = select(i, ...)
        if item and item ~= true and item ~= false then
            if type(item) == "table" and item.render then
                table.insert(self.children_list, item)
            elseif type(item) == "string" or type(item) == "number" then
                table.insert(self.children_list, escape_html(item))
            end
        end
    end
    return self
end

---@param condition any
---@param callback fun(node: Node)
---@return Node
function NodeClass:when(condition, callback)
    if condition then
        callback(self)
    end
    return self
end

---@generic T
---@param list? T[]
---@param callback fun(item: T, index: number): OptionalNodeChild
---@return Node
function NodeClass:each(list, callback)
    if type(list) == "table" then
        for i, item in ipairs(list) do
            local res = callback(item, i)
            if res then
                self:child(res)
            end
        end
    end
    return self
end

---@return string
function NodeClass:render()
    local buf = {}
    table.insert(buf, "<" .. self.tag_name)

    if #self.classes > 0 then
        local joined_classes = table.concat(self.classes, " ")
        table.insert(buf, ' class="' .. escape_html(joined_classes) .. '"')
    end

    for k, v in pairs(self.attributes) do
        if v == k or v == true then
            table.insert(buf, " " .. k)
        else
            table.insert(buf, ' ' .. k .. '="' .. escape_html(v) .. '"')
        end
    end

    if VOID_TAGS[self.tag_name] then
        table.insert(buf, " />")
        return table.concat(buf)
    end

    table.insert(buf, ">")

    for _, child in ipairs(self.children_list) do
        if type(child) == "table" and child.render then
            table.insert(buf, child:render())
        else
            table.insert(buf, tostring(child))
        end
    end

    table.insert(buf, "</" .. self.tag_name .. ">")
    return table.concat(buf)
end

---@return Document
function HTML.document()
    local self = setmetatable({}, DocClass)
    self._lang = "en"
    self._title = "Untitled Page"
    self._metas = {}
    self._styles = {}
    self._scripts = {}
    self._body = HTML.el("body")
    return self
end

---@param l string
---@return Document
function DocClass:lang(l)
    self._lang = l
    return self
end

---@param t string
---@return Document
function DocClass:title(t)
    self._title = t
    return self
end

---@param attrs Attributes
---@return Document
function DocClass:meta(attrs)
    table.insert(self._metas, attrs)
    return self
end

---@param href string
---@return Document
function DocClass:css(href)
    table.insert(self._styles, href)
    return self
end

---@param src string
---@param attrs? Attributes
---@return Document
function DocClass:js(src, attrs)
    ---@type Attributes
    local props = { src = src }
    if attrs then
        for k, v in pairs(attrs) do
            props[k] = v
        end
    end
    table.insert(self._scripts, props)
    return self
end

---@param attrs? Attributes
---@return Document
function DocClass:turbo(attrs)
    if self._turbo then
        return self
    end
    self._turbo = true
    ---@type Attributes
    local props = {
        src = "https://cdn.jsdelivr.net/npm/@hotwired/turbo@latest/dist/turbo.es2017-esm.min.js",
        type = "module",
    }
    if attrs then
        for k, v in pairs(attrs) do
            props[k] = v
        end
    end
    return self:js(props.src, props)
end

---@param ... OptionalNodeChild
---@return Document
function DocClass:body(...)
    self._body:child(...)
    return self
end

---@return string
function DocClass:render()
    local head = HTML.el("head")
                     :child(HTML.el("title"):text(self._title))

    for _, meta_attrs in ipairs(self._metas) do
        local m = HTML.el("meta")
        for k, v in pairs(meta_attrs) do
            m:attr(k, v)
        end
        head:child(m)
    end

    for _, href in ipairs(self._styles) do
        head:child(HTML.el("link"):attr("rel", "stylesheet"):attr("href", href))
    end

    for _, script_attrs in ipairs(self._scripts) do
        local s = HTML.el("script")
        for k, v in pairs(script_attrs) do
            s:attr(k, v)
        end
        head:child(s)
    end

    local html = HTML.el("html")
                     :attr("lang", self._lang)
                     :child(head)
                     :child(self._body)

    return "<!DOCTYPE html>\n" .. html:render()
end

return HTML
