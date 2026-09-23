local htmlkit = require("@htmlkit")
local version = require("@version")
local el = htmlkit.el

local page = htmlkit.document()
                    :title("Test")
                    :body(
        el("h1"):text("hello world"),
        el("p"):text("your are requesting from user agent : " .. http_request.header["User-Agent"]),
        el("p"):text("current version : " .. version.version),
        el("p"):text("current request path : " .. http_request.path),
        el("p"):text("current request method : " .. http_request.method),
        el("p"):text("your ip address is : " .. http_request.ip),
        el("p"):text("test query : " .. (http_request.query["test"] or "no test query") ),
        el("form"):attr("action","/"):attr("method","POST"):child(
            el("input")
                    :attr("type","text")
                    :attr("id","name")
                    :attr("name","user"),
            el("button")
                :attr("type","submit")
                :child("greet")
        )
)

http_content_type("text/html")
http_set_status(200)
http_header_add("TestKey","TestValue")
if http_request.method == "POST" then
    echo("hello ".. http_request.form["user"].." welcome to your world!")
else
    echo(page:render())
end
