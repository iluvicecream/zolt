local htmlkit = require('@htmlkit')
local code_block = require('component/code-block')

local data = {}

data.name = 'Set Status'

function data.render()
    return htmlkit.el('div'):class("max-w-3xl"):child(
        htmlkit.el('h1'):class("text-3xl font-bold text-olive-950 mb-3"):text('Set Status'),
        htmlkit.el('code'):class("block font-mono text-sm bg-olive-50 border border-olive-200 rounded-lg px-3 py-2 mb-2 text-olive-900"):text('http_set_status(status)'),
        htmlkit.el('p'):class("text-olive-800 leading-relaxed"):text(
            'Sets the response status code. Defaults to 200. Accepts any HTTP status code, for example 201, 301, 404 or 500.'
        ),
        code_block.render('http_set_status(404)')
    )
end

return data
