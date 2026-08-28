local render = require("../../render")

render.turbo_frame_rsp_start("doc-content")

    render.h1("response.status", "doc-header")

    echo("<h2>signature</h2>")

    echo("<pre><code>response.status(code: number)</code></pre>")

    echo("<h2>description</h2>")

    echo("<p>sets the http status code for the response. the default is <code>200</code>; call this when you want something else, like a <code>404</code> for a missing page or a <code>500</code> for an error.</p>")

    echo("<p>the code must be a whole number between <code>100</code> and <code>599</code>, and it must be a status zolt recognizes. anything else raises a runtime error.</p>")

    echo("<p>it returns nothing.</p>")

    echo("<h2>examples</h2>")

    echo("<p>a missing page:</p>")

    echo("<pre><code>response.status(404);\necho(\"page not found\");</code></pre>")

    echo("<p>a redirect:</p>")

    echo("<pre><code>response.status(302);\nresponse.header(\"location\", \"/home\");\necho(\"moving you along...\");</code></pre>")

    echo("<h2>notes</h2>")

    echo("<p>output is buffered until the route finishes, so you can set the status before or after echoing.</p>")

    echo("<p>see also <a href=\"/doc/ref/header.luau\">response.header</a>.</p>")

render.turbo_frame_rsp_end()
