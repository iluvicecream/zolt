local slug = http_request.query["slug"] or "welcome"
if slug == "get-started" then
    slug = "get-started/getting-started"
end
local htmlkit = require('@htmlkit')
local version = require('@version')
local sidebar = require('component/sidebar')
local content = require('component/content')

local data = require('shared/doc/' .. slug)
local page = htmlkit.document()
        :title(data.name .. " | Zolt Documentation")
        :css("https://fonts.googleapis.com/css2?family=Geist+Mono:ital,wght@0,100..900;1,100..900&family=Geist:ital,wght@0,100..900;1,100..900&display=swap")
        :css("public/css/bundle.css")
        :body(
            htmlkit.el("div"):class("min-h-screen flex flex-col font-[Geist_Mono]")
                :child(
                    htmlkit.el("div"):class("flex-1 flex gap-8 px-6 py-8"):child(
                        htmlkit.el("aside"):class("w-56 shrink-0 sticky top-8 self-start"):child(sidebar.render_sidebar()),
                        htmlkit.el("main"):class("flex-1 bg-olive-50 border border-olive-200 rounded-2xl shadow-sm p-8"):child(content.render(slug))
                    ),
                    htmlkit.el("footer"):class("px-6 py-5 border-t border-olive-200 text-sm text-olive-700"):child(
                        htmlkit.el("span"):text("Zolt version " .. version.version)
                    )
                )
        )
echo(page:render())
