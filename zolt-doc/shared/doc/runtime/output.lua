local htmlkit = require('@htmlkit')
local code_block = require('component/code-block')

local data = {}

data.name = 'Output'

local function signature(name)
    return htmlkit.el('code')
        :class("block font-mono text-sm bg-olive-50 border border-olive-200 rounded-lg px-3 py-2 mb-2 text-olive-900")
        :text(name)
end

function data.render()
    return htmlkit.el('div'):class("max-w-3xl"):child(
        htmlkit.el('h1'):class("text-3xl font-bold text-olive-950 mb-3"):text('Output'),
        htmlkit.el('h2'):class("text-xl font-semibold text-olive-950 mt-8 mb-2"):text('echo'),
        signature('echo(value, ...)'),
        htmlkit.el('p'):class("text-olive-800 leading-relaxed"):text(
            'Writes one or more values to the response body. Multiple arguments are concatenated. Values are converted with tostring.'
        ),
        code_block.render('echo("Hello, world!")'),
        htmlkit.el('h2'):class("text-xl font-semibold text-olive-950 mt-8 mb-2"):text('print'),
        signature('print(value, ...)'),
        htmlkit.el('p'):class("text-olive-800 leading-relaxed"):text(
            'Logs to the server log instead of the response. Arguments are tab-separated and the log line includes the source location of the call.'
        ),
        code_block.render('print("request handled", http_request.path)')
    )
end

return data
