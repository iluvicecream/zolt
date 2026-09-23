local htmlkit = require('@htmlkit')
local code_block = require('component/code-block')

local data = {}

data.name = 'Content Type'

function data.render()
    return htmlkit.el('div'):class("max-w-3xl"):child(
        htmlkit.el('h1'):class("text-3xl font-bold text-olive-950 mb-3"):text('Content Type'),
        htmlkit.el('code'):class("block font-mono text-sm bg-olive-50 border border-olive-200 rounded-lg px-3 py-2 mb-2 text-olive-900"):text('http_content_type(content_type)'),
        htmlkit.el('p'):class("text-olive-800 leading-relaxed"):text(
            'Sets the response Content-Type. Set it explicitly for HTML, JSON or any other MIME type you return.'
        ),
        code_block.render('http_content_type("text/html")')
    )
end

return data
