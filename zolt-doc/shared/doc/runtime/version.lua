local htmlkit = require('@htmlkit')
local code_block = require('component/code-block')

local data = {}

data.name = 'version'

function data.render()
    return htmlkit.el('div'):class("max-w-3xl"):child(
        htmlkit.el('h1'):class("text-3xl font-bold text-olive-950 mb-3"):text('@version'),
        htmlkit.el('p'):class("text-olive-800 leading-relaxed"):text(
            'Exposes the running Zolt version. The module table has a single field, version.'
        ),
        code_block.render('local version = require("@version")\necho("Zolt " .. version.version)')
    )
end

return data
