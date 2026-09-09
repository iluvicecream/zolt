HOL = require("@hol");
H = HOL.el;

local content =
        H("turbo-frame")
            :id("doc-content")
            :child(
                H("h1"):class("doc-header"):child("request.path"),
                H("h2"):child("signature"),
                H("pre"):child(H("code"):child("request.path() -> string")),
                H("h2"):child("description"),
                H("p"):child("returns the url path of the current request, without the query string or fragment. the value always starts with a slash and is available in every route."),
                H("h2"):child("examples"),
                H("pre"):child(H("code"):child("echo(\"you are at \" .. request.path());")),
                H("p"):child("for a request to ", H("code"):child("/hello.luau?name=zolt"), ", that prints ", H("code"):child("you are at /hello.luau"), ". a few more:"),
                H("pre"):child(H("code"):child("request              request.path()\n/                    /\n/hello.luau          /hello.luau\n/hello.luau?x=1     /hello.luau\n/sub/                /sub/")),
                H("p"):child("use it to branch on which page is being requested:"),
                H("pre"):child(H("code"):child("if request.path() == \"/\" then\n    echo(\"home\")\nelse\n    echo(\"somewhere else\")\nend")),
                H("h2"):child("notes"),
                H("p"):child("it returns a string, never ", H("code"):child("nil"), ". call it as many times as you like."),
                H("p"):child("see also ", H("a"):attr("href", "/doc/ref/query.luau"):child("request.query"), ".")
            )

echo(content:render())
