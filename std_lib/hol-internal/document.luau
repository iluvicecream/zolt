--!strict

local types = require("@hol-internal/types")
local element = require("@hol-internal/element")

local DocClass = {} :: any
DocClass.__index = DocClass

local function document(): types.Document
    local self = setmetatable({}, DocClass)
    self._lang = "en"
    self._title = "Untitled Page"
    self._metas = {}
    self._styles = {}
    self._scripts = {}
    self._body = element.el("body")
    return (self :: any) :: types.Document
end

function DocClass:lang(value: string): types.Document
    self._lang = value
    return self
end

function DocClass:title(value: string): types.Document
    self._title = value
    return self
end

function DocClass:meta(attrs: types.Attributes): types.Document
    table.insert(self._metas, attrs)
    return self
end

function DocClass:css(href: string): types.Document
    table.insert(self._styles, href)
    return self
end

function DocClass:js(src: string, attrs: types.Attributes?): types.Document
    local props: types.Attributes = { src = src }
    if attrs then
        for key, value in attrs do
            props[key] = value
        end
    end
    table.insert(self._scripts, props)
    return self
end

function DocClass:body(...: types.OptionalNodeChild): types.Document
    self._body:child(...)
    return self
end

function DocClass:render(): string
    local head = element.el("head")
        :child(element.el("title"):text(self._title))

    for _, meta_attrs in self._metas do
        local meta = element.el("meta")
        for key, value in meta_attrs do
            meta:attr(key, value)
        end
        head:child(meta)
    end

    for _, href in self._styles do
        head:child(element.el("link"):attr("rel", "stylesheet"):attr("href", href))
    end

    for _, script_attrs in self._scripts do
        local script = element.el("script")
        for key, value in script_attrs do
            script:attr(key, value)
        end
        head:child(script)
    end

    local html = element.el("html")
        :attr("lang", self._lang)
        :child(head)
        :child(self._body)

    return "<!DOCTYPE html>\n" .. html:render()
end

return {
    document = document,
}

