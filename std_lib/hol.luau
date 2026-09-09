--!strict

local HTML = {}

export type Attributes = { [string]: string | boolean }
export type StyleTable = { [string]: string }

export type PrimitiveChild = string | number | boolean
export type NodeChild = Node | PrimitiveChild
export type OptionalNodeChild = NodeChild | nil

export type Node = {
    tag_name: string,
    attributes: Attributes,
    classes: { string },
    children_list: { any },

    id: (self: Node, val: string) -> Node,
    class: (self: Node, ...string?) -> Node,
    attr: (self: Node, key: string, value: (string | boolean)?) -> Node,
    style: (self: Node, styles: StyleTable | string) -> Node,
    text: (self: Node, val: (string | number)?) -> Node,
    raw: (self: Node, raw_html: string?) -> Node,
    child: (self: Node, ...OptionalNodeChild) -> Node,
    when: (self: Node, condition: any, callback: (node: Node) -> ()) -> Node,
    each: <T>(self: Node, list: { T }?, callback: (item: T, index: number) -> OptionalNodeChild) -> Node,
    render: (self: Node) -> string,
}

export type Document = {
    lang: (self: Document, l: string) -> Document,
    title: (self: Document, t: string) -> Document,
    meta: (self: Document, attrs: Attributes) -> Document,
    css: (self: Document, href: string) -> Document,
    js: (self: Document, src: string, attrs: Attributes?) -> Document,
    body: (self: Document, ...OptionalNodeChild) -> Document,
    render: (self: Document) -> string,
}

local ESCAPE_MAP = {
    ["&"] = "&amp;",
    ["<"] = "&lt;",
    [">"] = "&gt;",
    ['"'] = "&quot;",
    ["'"] = "&#39;"
}

local function escape_html(val: any): string
    return (string.gsub(tostring(val or ""), '[&<>"\']', ESCAPE_MAP))
end

local VOID_TAGS = {
    meta=true, link=true, img=true, input=true, br=true, hr=true,
    area=true, base=true, col=true, embed=true, param=true, source=true, track=true, wbr=true
}

local NodeClass = {} :: any
NodeClass.__index = NodeClass

function HTML.el(tag: string): Node
    local self = setmetatable({}, NodeClass)
    self.tag_name = string.lower(tag)
    self.attributes = {}
    self.classes = {}
    self.children_list = {}
    return (self :: any) :: Node
end

function NodeClass:id(val: string): Node
    self.attributes["id"] = val
    return self
end

function NodeClass:class(...: string?): Node
    for i = 1, select("#", ...) do
        local c = select(i, ...)
        if type(c) == "string" and c ~= "" then
            table.insert(self.classes, c)
        end
    end
    return self
end

function NodeClass:attr(key: string, value: (string | boolean)?): Node
    if value ~= nil and value ~= false then
        self.attributes[key] = if value == true then key else value
    end
    return self
end

function NodeClass:style(styles: StyleTable | string): Node
    if type(styles) == "table" then
        local parts = {}
        for k, v in styles do
            table.insert(parts, k .. ":" .. v)
        end
        self.attributes["style"] = table.concat(parts, ";")
    elseif type(styles) == "string" then
        self.attributes["style"] = styles
    end
    return self
end

function NodeClass:text(val: (string | number)?): Node
    if val ~= nil then
        table.insert(self.children_list, escape_html(val))
    end
    return self
end

function NodeClass:raw(raw_html: string?): Node
    if raw_html ~= nil then
        table.insert(self.children_list, tostring(raw_html))
    end
    return self
end

function NodeClass:child(...: OptionalNodeChild): Node
    for i = 1, select("#", ...) do
        local item = select(i, ...)
        if item and item ~= true and item ~= false then
            if type(item) == "table" and (item :: any).render then
                table.insert(self.children_list, item)
            elseif type(item) == "string" or type(item) == "number" then
                table.insert(self.children_list, escape_html(item))
            end
        end
    end
    return self
end

function NodeClass:when(condition: any, callback: (node: Node) -> ()): Node
    if condition then
        callback(self)
    end
    return self
end

function NodeClass:each<T>(list: { T }?, callback: (item: T, index: number) -> OptionalNodeChild): Node
    if type(list) == "table" then
        for i, item in list do
            local res = callback(item, i)
            if res then
                self:child(res)
            end
        end
    end
    return self
end

function NodeClass:render(): string
    local buf = {}
    table.insert(buf, "<" .. self.tag_name)

    if #self.classes > 0 then
        local joined_classes = table.concat(self.classes, " ")
        table.insert(buf, ' class="' .. escape_html(joined_classes) .. '"')
    end

    for k, v in self.attributes do
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

    for _, child in self.children_list do
        if type(child) == "table" and (child :: any).render then
            table.insert(buf, (child :: any):render())
        else
            table.insert(buf, tostring(child))
        end
    end

    table.insert(buf, "</" .. self.tag_name .. ">")
    return table.concat(buf)
end

local DocClass = {} :: any
DocClass.__index = DocClass

function HTML.document(): Document
    local self = setmetatable({}, DocClass)
    self._lang = "en"
    self._title = "Untitled Page"
    self._metas = {}
    self._styles = {}
    self._scripts = {}
    self._body = HTML.el("body")
    return (self :: any) :: Document
end

function DocClass:lang(l: string): Document self._lang = l; return self end
function DocClass:title(t: string): Document self._title = t; return self end

function DocClass:meta(attrs: Attributes): Document
    table.insert(self._metas, attrs)
    return self
end

function DocClass:css(href: string): Document
    table.insert(self._styles, href)
    return self
end

function DocClass:js(src: string, attrs: Attributes?): Document
    local props: Attributes = { src = src }
    if attrs then
        for k, v in attrs do
            props[k] = v
        end
    end
    table.insert(self._scripts, props)
    return self
end

function DocClass:body(...: OptionalNodeChild): Document
    self._body:child(...)
    return self
end

function DocClass:render(): string
    local head = HTML.el("head")
        :child(HTML.el("title"):text(self._title))

    for _, meta_attrs in self._metas do
        local m = HTML.el("meta")
        for k, v in meta_attrs do m:attr(k, v) end
        head:child(m)
    end

    for _, href in self._styles do
        head:child(HTML.el("link"):attr("rel", "stylesheet"):attr("href", href))
    end

    for _, script_attrs in self._scripts do
        local s = HTML.el("script")
        for k, v in script_attrs do s:attr(k, v) end
        head:child(s)
    end

    local html = HTML.el("html")
        :attr("lang", self._lang)
        :child(head)
        :child(self._body)

    return "<!DOCTYPE html>\n" .. html:render()
end

return HTML
