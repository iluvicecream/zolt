HOL = require("@hol");
H = HOL.el;

local content =
        H("turbo-frame")
            :id("doc-content")
            :child(
                H("h1"):class("doc-header"):child("echo"),
                H("h2"):child("signature"),
                H("pre"):child(H("code"):child("echo(content: any)")),
                H("h2"):child("description"),
                H("p"):child("appends strings to the response body, in the order you pass them. call it as many times as you like; each call adds to what the browser receives when the route finishes."),
                H("p"):child("it returns nothing."),
                H("h2"):child("examples"),
                H("p"):child("a plain text page:"),
                H("pre"):child(H("code"):child("echo(\"Hello, world!\");")),
                H("p"):child("html is just text too:"),
                H("pre"):child(H("code"):child("echo(\"<h1>hello from zolt!</h1>\");")),
                H("p"):child("multiple values are written one after another, handy for mixing variables in:"),
                H("pre"):child(H("code"):child("local name = \"zolt\"\necho(\"<h1>hello, \" .. name .. \"!</h1>\");")),
                H("h2"):child("notes"),
                H("p"):child("the response body is limited to 16 kb. if a route writes more than that, zolt responds with an error instead of serving a truncated page."),
                H("p"):child("when the route is done, zolt sends the body as ", H("code"):child("text/html; charset=utf-8"), " unless you set another content type with ", H("code"):child("response.header()"), "."),
                H("p"):child("output is buffered until the route finishes, so you can set ", H("code"):child("response.status()"), " or ", H("code"):child("response.header()"), " after echoing."),
                H("p"):child("next up: ", H("a"):attr("href", "/doc/ref/request.luau"):child("request.path"), ", ", H("a"):attr("href", "/doc/ref/query.luau"):child("request.query"), ", ", H("a"):attr("href", "/doc/ref/status.luau"):child("response.status"), ", and ", H("a"):attr("href", "/doc/ref/header.luau"):child("response.header"), ".")
            )

echo(content:render())
