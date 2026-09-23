local htmlkit = require('@htmlkit')
local code_block = require('component/code-block')

local data = {}

data.name = 'Request'

function data.render()
    return htmlkit.el('div'):class("max-w-3xl"):child(
        htmlkit.el('h1'):class("text-3xl font-bold text-olive-950 mb-3"):text('Request'),
        htmlkit.el('code'):class("block font-mono text-sm bg-olive-50 border border-olive-200 rounded-lg px-3 py-2 mb-2 text-olive-900"):text('http_request'),
        htmlkit.el('p'):class("text-olive-800 leading-relaxed"):text(
            'A global table describing the current request. Header and query values are strings when there is one value, and arrays when the client sent several.'
        ),
        htmlkit.el('div'):class("my-4 overflow-x-auto"):child(
            htmlkit.el('table'):class("w-full text-sm border-collapse"):child(
                htmlkit.el('thead'):child(
                    htmlkit.el('tr'):class("text-left text-olive-600 border-b border-olive-300"):child(
                        htmlkit.el('th'):class("py-2 pr-4 font-semibold"):text('Field'),
                        htmlkit.el('th'):class("py-2 pr-4 font-semibold"):text('Type'),
                        htmlkit.el('th'):class("py-2 font-semibold"):text('Description')
                    )
                ):each({
                    { 'path', 'string', 'The requested path relative to the app root.' },
                    { 'method', 'string', 'The HTTP method, e.g. GET or POST.' },
                    { 'ip', 'string', 'The client address, including port.' },
                    { 'header', 'table', 'Request headers. Keys use Go canonical casing, e.g. User-Agent.' },
                    { 'query', 'table', 'URL query parameters.' },
                    { 'form', 'table', 'Submitted form data from the request body. Available for form requests, such as POST.' },
                }, function(field)
                    return htmlkit.el('tr'):class("border-b border-olive-200"):child(
                        htmlkit.el('td'):class("py-2 pr-4 font-mono text-olive-900"):text(field[1]),
                        htmlkit.el('td'):class("py-2 pr-4 text-olive-700"):text(field[2]),
                        htmlkit.el('td'):class("py-2 text-olive-800"):text(field[3])
                    )
                end)
            )
        ),
        code_block.render('local user_agent = http_request.header["User-Agent"]\nlocal tag = http_request.query["tag"]\nlocal email = http_request.form["email"]')
    )
end

return data
