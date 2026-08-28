local render = require("../../render")

render.turbo_frame_rsp_start("doc-content")

    render.h1("response.header", "doc-header")

    echo("<h2>signature</h2>")

    echo("<pre><code>response.header(name: string, value: string)</code></pre>")

    echo("<h2>description</h2>")

    echo("<p>adds a response header. call it once per header you want to send; repeating the same name just adds another header line.</p>")

    echo("<p>header names and values must be valid, and the response is limited to 8 headers with 1 kb of total header storage. if a name or value is invalid, or the limits are hit, zolt raises a runtime error.</p>")

    echo("<p>it returns nothing.</p>")

    echo("<h2>examples</h2>")

    echo("<p>serve json:</p>")

    echo("<pre><code>response.header(\"content-type\", \"application/json\");\necho(\"{\\\"ok\\\": true}\");</code></pre>")

    echo("<p>custom headers:</p>")

    echo("<pre><code>response.header(\"x-powered-by\", \"zolt\");\nresponse.header(\"cache-control\", \"no-store\");</code></pre>")

    echo("<h2>notes</h2>")

    echo("<p>when the route finishes without setting a content type, zolt sends <code>text/html; charset=utf-8</code>.</p>")

    echo("<p>output is buffered until the route finishes, so you can set headers before or after echoing.</p>")

    echo("<p>see also <a href=\"/doc/ref/status.luau\">response.status</a>.</p>")

render.turbo_frame_rsp_end()
