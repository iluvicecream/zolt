--!strict

local types = require("@hol-internal/types")
local escape = require("@hol-internal/escape")

local NodeClass = {} :: any
NodeClass.__index = NodeClass

local function el(tag: string): types.Node
    local self = setmetatable({}, NodeClass)
    self.tag_name = string.lower(tag)
    self.attributes = {}
    self.classes = {}
    self.children_list = {}
    return (self :: any) :: types.Node
end

function NodeClass:id(val: string): types.Node
    self.attributes["id"] = val
    return self
end

function NodeClass:class(...: string?): types.Node
    for i = 1, select("#", ...) do
        local class_name = select(i, ...)
        if type(class_name) == "string" and class_name ~= "" then
            table.insert(self.classes, class_name)
        end
    end
    return self
end

function NodeClass:attr(key: string, value: (string | boolean)?): types.Node
    if value ~= nil and value ~= false then
        self.attributes[key] = if value == true then key else value
    end
    return self
end

function NodeClass:style(styles: types.StyleTable | string): types.Node
    if type(styles) == "table" then
        local parts = {}
        for key, value in styles do
            table.insert(parts, key .. ":" .. value)
        end
        self.attributes["style"] = table.concat(parts, ";")
    elseif type(styles) == "string" then
        self.attributes["style"] = styles
    end
    return self
end

function NodeClass:text(value: (string | number)?): types.Node
    if value ~= nil then
        table.insert(self.children_list, escape.escape(value))
    end
    return self
end

function NodeClass:raw(raw_html: string?): types.Node
    if raw_html ~= nil then
        table.insert(self.children_list, tostring(raw_html))
    end
    return self
end

function NodeClass:child(...: types.OptionalNodeChild): types.Node
    for i = 1, select("#", ...) do
        local item = select(i, ...)
        if item and item ~= true and item ~= false then
            if type(item) == "table" and (item :: any).render then
                table.insert(self.children_list, item)
            elseif type(item) == "string" or type(item) == "number" then
                table.insert(self.children_list, escape.escape(item))
            end
        end
    end
    return self
end

function NodeClass:when(condition: any, callback: (node: types.Node) -> ()): types.Node
    if condition then
        callback(self)
    end
    return self
end

function NodeClass:each<T>(list: { T }?, callback: (item: T, index: number) -> types.OptionalNodeChild): types.Node
    if type(list) == "table" then
        for index, item in list do
            local result = callback(item, index)
            if result then
                self:child(result)
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
        table.insert(buf, ' class="' .. escape.escape(joined_classes) .. '"')
    end

    for key, value in self.attributes do
        if value == key or value == true then
            table.insert(buf, " " .. key)
        else
            table.insert(buf, ' ' .. key .. '="' .. escape.escape(value) .. '"')
        end
    end

    if escape.isVoidTag(self.tag_name) then
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

return {
    el = el,
}
