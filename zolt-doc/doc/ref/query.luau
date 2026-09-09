HOL = require("@hol");
H = HOL.el;

local content =
        H("turbo-frame")
            :id("doc-content")
            :child(
                H("h1"):class("doc-header"):child("request.query"),
                H("h2"):child("signature"),
                H("pre"):child(H("code"):child("request.query(field: string) -> string?")),
                H("h2"):child("description"),
                H("p"):child("returns the value of the named query parameter from the current request url, or ", H("code"):child("nil"), " when that parameter is not present."),
                H("p"):child("keys and values are decoded the way url query strings normally are: ", H("code"):child("%20"), " becomes a space, ", H("code"):child("+"), " also becomes a space, and percent escapes become the bytes they represent. a parameter without ", H("code"):child("="), ", like ", H("code"):child("?flag"), ", returns an empty string."),
                H("p"):child("it is available in every route."),
                H("h2"):child("examples"),
                H("pre"):child(H("code"):child("echo(\"hello, \" .. request.query(\"name\") .. \"!\");")),
                H("p"):child("for a request to ", H("code"):child("/hello.luau?name=zolt"), ", that prints ", H("code"):child("hello, zolt!"), ". to default a missing value:"),
                H("pre"):child(H("code"):child("local name = request.query(\"name\") or \"friend\"\necho(\"hello, \" .. name .. \"!\");")),
                H("p"):child("a few more examples:"),
                H("pre"):child(H("code"):child("request                  request.query(\"x\")\n/hello.luau?x=1             \"1\"\n/hello.luau?x=hello+world  \"hello world\"\n/hello.luau?flag           \"\"\n/hello.luau?y=2            nil")),
                H("h2"):child("notes"),
                H("p"):child("if the same field appears more than once, the first value is returned."),
                H("p"):child("see also ", H("a"):attr("href", "/doc/ref/request.luau"):child("request.path"), ".")
            )

echo(content:render())
