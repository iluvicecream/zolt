---@meta

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
local Node = {}

---Sets the ID attribute of the node.
---@param val string
---@return Node
function Node:id(val) end

---Adds CSS class names to the node.
---@param ... string|nil
---@return Node
function Node:class(...) end

---Sets an attribute key and value on the node.
---@param key string
---@param value? string|boolean
---@return Node
function Node:attr(key, value) end

---Sets inline CSS styles on the node.
---@param styles StyleTable|string
---@return Node
function Node:style(styles) end

---Appends escaped text content to the node.
---@param val? string|number
---@return Node
function Node:text(val) end

---Appends unescaped raw HTML to the node.
---@param raw_html? string
---@return Node
function Node:raw(raw_html) end

---Appends one or more child nodes or primitive values.
---@param ... OptionalNodeChild
---@return Node
function Node:child(...) end

---Conditionally applies a mutation function to the node if condition is truthy.
---@param condition any
---@param callback fun(node: Node)
---@return Node
function Node:when(condition, callback) end

---Iterates over a table array and appends the returned children.
---@generic T
---@param list? T[]
---@param callback fun(item: T, index: number): OptionalNodeChild
---@return Node
function Node:each(list, callback) end

---Renders the node and its children into an HTML string.
---@return string
function Node:render() end


---@class Document
---@field private _lang string
---@field private _title string
---@field private _metas Attributes[]
---@field private _styles string[]
---@field private _scripts Attributes[]
---@field private _body Node
local Document = {}

---Sets the language attribute on the html tag.
---@param l string
---@return Document
function Document:lang(l) end

---Sets the page title tag.
---@param t string
---@return Document
function Document:title(t) end

---Adds a meta tag to the page head.
---@param attrs Attributes
---@return Document
function Document:meta(attrs) end

---Links a CSS stylesheet in the head.
---@param href string
---@return Document
function Document:css(href) end

---Includes a JavaScript file in the head.
---@param src string
---@param attrs? Attributes
---@return Document
function Document:js(src, attrs) end

---Injects the Hotwire Turbo script into the head .
---@param attrs? Attributes
---@return Document
function Document:turbo(attrs) end

---Appends child nodes directly to the document body.
---@param ... OptionalNodeChild
---@return Document
function Document:body(...) end

---Renders the complete HTML document starting with DOCTYPE.
---@return string
function Document:render() end


---@class HtmlKit
local HTML = {}

---Creates a new HTML Element Node.
---@param tag string
---@return Node
function HTML.el(tag) end

---Creates a new HTML Document builder.
---@return Document
function HTML.document() end

return HTML
