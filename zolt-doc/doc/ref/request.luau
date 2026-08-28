local render = require("../../render")

render.turbo_frame_rsp_start("doc-content")

    render.h1("request.path", "doc-header")

    echo("<h2>signature</h2>")

    echo("<pre><code>request.path() -&gt; string</code></pre>")

    echo("<h2>description</h2>")

    echo("<p>returns the url path of the current request, without the query string or fragment. the value always starts with a slash and is available in every route.</p>")

    echo("<h2>examples</h2>")

    echo("<pre><code>echo(\"you are at \" .. request.path());</code></pre>")

    echo("<p>for a request to <code>/hello.luau?name=zolt</code>, that prints <code>you are at /hello.luau</code>. a few more:</p>")

    echo("<pre><code>request              request.path()\n/                    /\n/hello.luau          /hello.luau\n/hello.luau?x=1     /hello.luau\n/sub/                /sub/</code></pre>")

    echo("<p>use it to branch on which page is being requested:</p>")

    echo("<pre><code>if request.path() == \"/\" then\n    echo(\"home\")\nelse\n    echo(\"somewhere else\")\nend</code></pre>")

    echo("<h2>notes</h2>")

    echo("<p>it returns a string, never <code>nil</code>. call it as many times as you like.</p>")

    echo("<p>see also <a href=\"/doc/ref/echo.luau\">echo</a>.</p>")

render.turbo_frame_rsp_end()
