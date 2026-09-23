local htmlkit = require('@htmlkit')
local code_block = require('component/code-block')

local data = {}

data.name = 'Header Add'

function data.render()
    return htmlkit.el('div'):class("max-w-3xl"):child(
        htmlkit.el('h1'):class("text-3xl font-bold text-olive-950 mb-3"):text('Header Add'),
        htmlkit.el('code'):class("block font-mono text-sm bg-olive-50 border border-olive-200 rounded-lg px-3 py-2 mb-2 text-olive-900"):text('http_header_add(key, value, ...)'),
        htmlkit.el('p'):class("text-olive-800 leading-relaxed"):text(
            'Adds one or more values for a response header. Repeated values for the same key are appended.'
        ),
        code_block.render('http_header_add("Set-Cookie", "session=abc123")')
    )
end

return data
