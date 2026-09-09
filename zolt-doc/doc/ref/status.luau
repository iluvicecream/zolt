HOL = require("@hol");
H = HOL.el;

local content =
        H("turbo-frame")
            :id("doc-content")
            :child(
                H("h1"):class("doc-header"):child("response.status"),
                H("h2"):child("signature"),
                H("pre"):child(H("code"):child("response.status(code: number)")),
                H("h2"):child("description"),
                H("p"):child("sets the http status code for the response. the default is ", H("code"):child("200"), "; call this when you want something else, like a ", H("code"):child("404"), " for a missing page or a ", H("code"):child("500"), " for an error."),
                H("p"):child("the code must be a whole number between ", H("code"):child("100"), " and ", H("code"):child("599"), ", and it must be a status zolt recognizes. anything else raises a runtime error."),
                H("p"):child("it returns nothing."),
                H("h2"):child("examples"),
                H("p"):child("a missing page:"),
                H("pre"):child(H("code"):child("response.status(404);\necho(\"page not found\");")),
                H("p"):child("a redirect:"),
                H("pre"):child(H("code"):child("response.status(302);\nresponse.header(\"location\", \"/home\");\necho(\"moving you along...\");")),
                H("h2"):child("notes"),
                H("p"):child("output is buffered until the route finishes, so you can set the status before or after echoing."),
                H("p"):child("see also ", H("a"):attr("href", "/doc/ref/header.luau"):child("response.header"), ".")
            )

echo(content:render())
