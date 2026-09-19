local htmlkit = require("@htmlkit")
local el = htmlkit.el

local page = htmlkit.document()
    :title("Test")
    :body(
        el("h1"):text("hello world")
    )

echo(page:render())