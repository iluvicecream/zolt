HOL = require("@hol");
H = HOL.el;

local content =
        H("turbo-frame")
            :id("doc-content")
            :child(
                H("h1"):class("doc-header"):child("response.header"),
                H("h2"):child("signature"),
                H("pre"):child(H("code"):child("response.header(name: string, value: string)")),
                H("h2"):child("description"),
                H("p"):child("adds a response header. call it once per header you want to send; repeating the same name just adds another header line."),
                H("p"):child("header names and values must be valid, and the response is limited to 8 headers with 1 kb of total header storage. if a name or value is invalid, or the limits are hit, zolt raises a runtime error."),
                H("p"):child("it returns nothing."),
                H("h2"):child("examples"),
                H("p"):child("serve json:"),
                H("pre"):child(H("code"):child("response.header(\"content-type\", \"application/json\");\necho(\"{\\\"ok\\\": true}\");")),
                H("p"):child("custom headers:"),
                H("pre"):child(H("code"):child("response.header(\"x-powered-by\", \"zolt\");\nresponse.header(\"cache-control\", \"no-store\");")),
                H("h2"):child("notes"),
                H("p"):child("when the route finishes without setting a content type, zolt sends ", H("code"):child("text/html; charset=utf-8"), "."),
                H("p"):child("output is buffered until the route finishes, so you can set headers before or after echoing."),
                H("p"):child("see also ", H("a"):attr("href", "/doc/ref/status.luau"):child("response.status"), ".")
            )

echo(content:render())
