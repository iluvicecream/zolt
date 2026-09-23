local htmlkit = require('@htmlkit')
local code_block = require('component/code-block')

local data = {}

data.name = 'turbokit'

local function api_row(name, signature_text, description)
    return htmlkit.el('tr'):class("border-b border-olive-200 align-top"):child(
        htmlkit.el('td'):class("py-2 pr-4 font-mono text-olive-900 whitespace-nowrap"):text(name),
        htmlkit.el('td'):class("py-2 pr-4 font-mono text-xs text-olive-600 whitespace-nowrap"):text(signature_text),
        htmlkit.el('td'):class("py-2 text-olive-800"):text(description)
    )
end

function data.render()
    return htmlkit.el('div'):class("max-w-3xl"):child(
        htmlkit.el('h1'):class("text-3xl font-bold text-olive-950 mb-3"):text('@turbokit'),
        htmlkit.el('p'):class("text-olive-800 leading-relaxed"):text(
            'Helpers for Hotwire Turbo frames. Pair them with document():turbo() to load the Turbo runtime.'
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
                api_row('frame', 'frame(id, ...)', 'Create a Turbo frame with the given id.'),
                api_row('lazy_frame', 'lazy_frame(id, src, ...)', 'Create a lazy-loading Turbo frame with a source URL.')
            )
        ),
        code_block.render('local turbokit = require("@turbokit")\nlocal frame = turbokit.frame("comments", htmlkit.el("p"):text("Loading..."))')
    )
end

return data
