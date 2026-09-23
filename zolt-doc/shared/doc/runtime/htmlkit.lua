local htmlkit = require('@htmlkit')
local code_block = require('component/code-block')

local data = {}

data.name = 'htmlkit'

local function api_row(name, signature_text, description)
    return htmlkit.el('tr'):class("border-b border-olive-200 align-top"):child(
        htmlkit.el('td'):class("py-2 pr-4 font-mono text-olive-900 whitespace-nowrap"):text(name),
        htmlkit.el('td'):class("py-2 pr-4 font-mono text-xs text-olive-600 whitespace-nowrap"):text(signature_text),
        htmlkit.el('td'):class("py-2 text-olive-800"):text(description)
    )
end

function data.render()
    return htmlkit.el('div'):class("max-w-3xl"):child(
        htmlkit.el('h1'):class("text-3xl font-bold text-olive-950 mb-3"):text('@htmlkit'),
        htmlkit.el('p'):class("text-olive-800 leading-relaxed"):text(
            'A builder library for HTML. htmlkit.el(tag) returns a chainable Node; htmlkit.document() returns a chainable full-page builder. All methods return the node so calls can be chained.'
        ),
        htmlkit.el('div'):class("my-4 overflow-x-auto"):child(
            htmlkit.el('table'):class("w-full text-sm border-collapse"):child(
                htmlkit.el('thead'):child(
                    htmlkit.el('tr'):class("text-left text-olive-600 border-b border-olive-300"):child(
                        htmlkit.el('th'):class("py-2 pr-4 font-semibold"):text('Function'),
                        htmlkit.el('th'):class("py-2 pr-4 font-semibold"):text('Signature'),
                        htmlkit.el('th'):class("py-2 font-semibold"):text('Description')
                    )
                ),
                api_row('el', 'el(tag)', 'Create a new HTML element node.'),
                api_row('document', 'document()', 'Create a complete HTML document builder.'),
                api_row('Node:id', ':id(value)', 'Set the element id.'),
                api_row('Node:class', ':class(...)', 'Add one or more CSS class names.'),
                api_row('Node:attr', ':attr(key, value)', 'Set an attribute. Value may be a string or boolean.'),
                api_row('Node:style', ':style(styles)', 'Set inline styles from a table or string.'),
                api_row('Node:text', ':text(value)', 'Append escaped text content.'),
                api_row('Node:raw', ':raw(html)', 'Append unescaped raw HTML.'),
                api_row('Node:child', ':child(...)', 'Append nodes or primitive values.'),
                api_row('Node:when', ':when(condition, fn)', 'Apply fn(node) only when condition is truthy.'),
                api_row('Node:each', ':each(list, fn)', 'Append fn(item, index) results for every list item.'),
                api_row('Node:render', ':render()', 'Render the node tree to an HTML string.'),
                api_row('Document:lang', ':lang(value)', 'Set the html lang attribute.'),
                api_row('Document:title', ':title(value)', 'Set the page title.'),
                api_row('Document:meta', ':meta(attrs)', 'Add a meta tag.'),
                api_row('Document:css', ':css(href)', 'Link a stylesheet.'),
                api_row('Document:js', ':js(src, attrs)', 'Include a JavaScript file.'),
                api_row('Document:turbo', ':turbo(attrs)', 'Include the Hotwire Turbo script.'),
                api_row('Document:body', ':body(...)', 'Append children to the document body.'),
                api_row('Document:render', ':render()', 'Render the full document with DOCTYPE.')
            )
        ),
        code_block.render(
            'local htmlkit = require("@htmlkit")\n\nlocal page = htmlkit.document()\n    :title("Home")\n    :body(htmlkit.el("h1"):text("Welcome"))\n\necho(page:render())'
        )
    )
end

return data
