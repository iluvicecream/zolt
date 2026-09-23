local htmlkit = require('@htmlkit')
local code_block = require('component/code-block')

local data = {}

data.name = 'Getting Started'

function data.render()
    return htmlkit.el('div'):class("max-w-3xl"):child(
        htmlkit.el('h1'):class("text-3xl font-bold text-olive-950 mb-3"):text('Getting Started'),
        htmlkit.el('p'):class("text-olive-800 leading-relaxed"):text(
            "Zolt is a tiny Go web server that runs Lua scripts. Each .lua file is a page: read the request, build a response, echo it back. No build step, no framework, no boilerplate."
        ),
        htmlkit.el('h2'):class("text-xl font-semibold text-olive-950 mt-8 mb-2"):text('Your first page'),
        htmlkit.el('p'):class("text-olive-800 leading-relaxed"):text(
            'Create a folder for your app'
        ),
        code_block.render('mkdir myapp\ncd myapp'),
        htmlkit.el('p'):class("text-olive-800 leading-relaxed"):text(
            'Add an index.lua file. Zolt runs index.lua when someone visits the root path.'
        ),
        code_block.render('echo("hello, world")'),
        htmlkit.el('p'):class("text-olive-800 leading-relaxed"):text(
            'Now start the server in that folder and open http://127.0.0.1:8080.'
        ),
        code_block.render('zoltd', 'terminal'),
        htmlkit.el('h2'):class("text-xl font-semibold text-olive-950 mt-8 mb-2"):text('Reading the request'),
        htmlkit.el('p'):class("text-olive-800 leading-relaxed"):text(
            'The global http_request table gives you the path, method, client IP, headers, and query parameters for the current request.'
        ),
        code_block.render('echo("path: " .. http_request.path .. "\\n")\necho("method: " .. http_request.method .. "\\n")\necho("name: " .. (http_request.query["name"] or "stranger"))'),
        htmlkit.el('h2'):class("text-xl font-semibold text-olive-950 mt-8 mb-2"):text('Returning HTML'),
        htmlkit.el('p'):class("text-olive-800 leading-relaxed"):text(
            'echo writes raw bytes to the response body. You can echo plain strings, or build HTML with the @htmlkit module.'
        ),
        code_block.render(
            'local htmlkit = require("@htmlkit")\n\nlocal page = htmlkit.document()\n    :title("My app")\n    :body(\n        htmlkit.el("h1"):text("Hello"),\n        htmlkit.el("p"):text("Built with Zolt")\n    )\n\nhttp_content_type("text/html")\necho(page:render())'
        ),
        htmlkit.el('h2'):class("text-xl font-semibold text-olive-950 mt-8 mb-2"):text('Routing'),
        htmlkit.el('p'):class("text-olive-800 leading-relaxed"):text(
            'Every .lua file in your app folder is a route. login.lua is served at /login.lua. Anything under public/ is served as a static file. Requests that do not match a script or static file return 404.'
        )
    )
end

return data
