local render = require("../render")

render.turbo_frame_rsp_start("doc-content")

    render.h1("your first web page", "doc-header")

    echo("<p>ok, zolt is installed. time to make something appear in the browser. you'll have a working hello world in about thirty seconds. (jk prob gonna take longer than that)</p>")

    echo("<h2>make an app folder</h2>")

    echo("<p>everything a zolt app needs lives in one folder. make one and step inside:</p>")

    echo("<pre><code>mkdir myapp\ncd myapp</code></pre>")

    echo("<h2>tell zolt where to listen</h2>")

    echo("<p>create <code>config.luau</code> with the address you want the server to listen on:</p>")

    echo("<pre><code>return {\n    host = \"127.0.0.1:8080\",\n}</code></pre>")

    echo("<p>that's a plain lua file, so you can change the port anytime. <code>127.0.0.1:8080</code> is a great default for local development.</p>")

    echo("<h2>write your first page</h2>")

    echo("<p>now create <code>index.luau</code> in the same folder. requests to <code>/</code> run this file:</p>")

    echo("<pre><code>echo(\"Hello, world!\");</code></pre>")

    echo("<p>that's the whole app. <code>echo</code> sends text back to the browser, just like <code>print</code> in other languages.</p>")

    echo("<h2>run it</h2>")

    echo("<p>start the server from your app folder:</p>")

    echo("<pre><code>zoltd</code></pre>")

    echo("<p>zolt reads <code>config.luau</code> from the folder you're in and serves that folder as the webroot. you can also point it at a config anywhere:</p>")

    echo("<pre><code>zoltd /path/to/myapp/config.luau</code></pre>")

    echo("<p>now open <a href=\"http://127.0.0.1:8080\">http://127.0.0.1:8080</a> in your browser. hello, world! welcome to zolt.</p>")

    echo("<h2>make it a bit more interesting</h2>")

    echo("<p>every <code>.luau</code> file is its own route. add a <code>hello.luau</code>:</p>")

    echo("<pre><code>echo(\"&lt;h1&gt;hello from zolt!&lt;/h1&gt;\");\necho(\"&lt;p&gt;you are at \" .. request.path() .. \"&lt;/p&gt;\");</code></pre>")

    echo("<p>save it and visit <a href=\"http://127.0.0.1:8080/hello.luau\">http://127.0.0.1:8080/hello.luau</a>. the <code>request</code> tells your route about the incoming request, starting with <code>path()</code>.</p>")

    echo("<p>everything else in your folder is served as a static file automatically, so css, images, and javascript just work next to your routes.</p>")

    echo("<p>that's the tour. check out the <a href=\"/doc/intro.luau\">introduction</a> or the <a href=\"/doc/install.luau\">install guide</a> if you skipped ahead, then go build something :)</p>")

render.turbo_frame_rsp_end()
