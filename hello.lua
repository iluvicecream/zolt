local htmlkit = require("@htmlkit")
local version = require("@version")
local el = htmlkit.el

local page = htmlkit.document()
    :title("Test")
    :body(
        el("h1"):text("hello world"),
        el("p"):text("current version : " .. version.version),
        el("p"):text("current request path : " .. http_request.path)
    )

http_content_type("text/html")
http_set_status(200)
http_header_add("TestKey","TestValue")
echo(page:render())
