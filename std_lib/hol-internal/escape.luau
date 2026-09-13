--!strict

local ESCAPE_MAP = {
    ["&"] = "&amp;",
    ["<"] = "&lt;",
    [">"] = "&gt;",
    ['"'] = "&quot;",
    ["'"] = "&#39;",
}

export type Escape = {
    escape: (value: any) -> string,
    isVoidTag: (tag: string) -> boolean,
}

local escape = {}

function escape.escape(value: any): string
    return (string.gsub(tostring(value or ""), '[&<>"\']', ESCAPE_MAP))
end

local VOID_TAGS = {
    meta = true, link = true, img = true, input = true, br = true, hr = true,
    area = true, base = true, col = true, embed = true, param = true,
    source = true, track = true, wbr = true,
}

function escape.isVoidTag(tag: string): boolean
    return VOID_TAGS[tag] == true
end

return escape

