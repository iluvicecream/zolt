local render = require("../../render")

render.turbo_frame_rsp_start("doc-content")

    render.h1("echo", "doc-header")

    echo("<h2>signature</h2>")

    echo("<pre><code>echo(content: any)</code></pre>")

    echo("<h2>description</h2>")

    echo("<p>appends strings to the response body, in the order you pass them. call it as many times as you like; each call adds to what the browser receives when the route finishes.</p>")

    echo("<p>it returns nothing.</p>")

    echo("<h2>examples</h2>")

    echo("<p>a plain text page:</p>")

    echo("<pre><code>echo(\"Hello, world!\");</code></pre>")

    echo("<p>html is just text too:</p>")

    echo("<pre><code>echo(\"&lt;h1&gt;hello from zolt!&lt;/h1&gt;\");</code></pre>")

    echo("<p>multiple values are written one after another, handy for mixing variables in:</p>")

    echo("<pre><code>local name = \"zolt\"\necho(\"&lt;h1&gt;hello, \" .. name .. \"!&lt;/h1&gt;\");</code></pre>")

    echo("<h2>notes</h2>")

    echo("<p>the response body is limited to 16 kb. if a route writes more than that, zolt responds with an error instead of serving a truncated page.</p>")

    echo("<p>when the route is done, zolt sends the body as <code>text/html; charset=utf-8</code> unless you set another content type with <code>header()</code>.</p>")

    echo("<p>output is buffered until the route finishes, so you can set the <code>status()</code> or <code>header()</code> after echoing.</p>")

render.turbo_frame_rsp_end()
