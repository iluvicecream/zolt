local htmlkit = require("@htmlkit")
local sidebar = require('component/sidebar')

local page = htmlkit.document()
    :title("Zolt Documentation")
    :css("public/css/index.css")
    :css("https://fonts.googleapis.com/css2?family=Geist+Mono:ital,wght@0,100..900;1,100..900&family=Geist:ital,wght@0,100..900;1,100..900&display=swap")
    :turbo()
    :body(
        htmlkit.el("h1"):text("hi"),
        sidebar.render_sidebar()
)

echo(page:render())