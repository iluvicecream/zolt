local render = require("../../render")

render.turbo_frame_rsp_start("doc-content")

    render.h1("request.query", "doc-header")

    echo("<h2>signature</h2>")

    echo("<pre><code>request.query(field: string) -&gt; string?</code></pre>")

    echo("<h2>description</h2>")

    echo("<p>returns the value of the named query parameter from the current request url, or <code>nil</code> when that parameter is not present.</p>")

    echo("<p>keys and values are decoded the way url query strings normally are: <code>%20</code> becomes a space, <code>+</code> also becomes a space, and percent escapes become the bytes they represent. a parameter without <code>=</code>, like <code>?flag</code>, returns an empty string.</p>")

    echo("<p>it is available in every route.</p>")

    echo("<h2>examples</h2>")

    echo("<pre><code>echo(\"hello, \" .. request.query(\"name\") .. \"!\");</code></pre>")

    echo("<p>for a request to <code>/hello.luau?name=zolt</code>, that prints <code>hello, zolt!</code>. to default a missing value:</p>")

    echo("<pre><code>local name = request.query(\"name\") or \"friend\"\necho(\"hello, \" .. name .. \"!\");</code></pre>")

    echo("<p>a few more examples:</p>")

    echo("<pre><code>request                  request.query(\"x\")\n/hello.luau?x=1             \"1\"\n/hello.luau?x=hello+world  \"hello world\"\n/hello.luau?flag           \"\"\n/hello.luau?y=2            nil</code></pre>")

    echo("<h2>notes</h2>")

    echo("<p>if the same field appears more than once, the first value is returned.</p>")

    echo("<p>see also <a href=\"/doc/ref/request.luau\">request.path</a>.</p>")

render.turbo_frame_rsp_end()
