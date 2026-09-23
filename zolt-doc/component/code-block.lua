local htmlkit = require('@htmlkit')

local M = {}

function M.render(code, language)
    return htmlkit.el('div')
        :class("my-4 overflow-x-auto rounded-xl border border-olive-200 bg-olive-50 p-4 shadow-sm")
        :child(
            htmlkit.el('pre'):class("font-mono text-sm leading-relaxed text-olive-950"):text(code)
        )
end

return M
