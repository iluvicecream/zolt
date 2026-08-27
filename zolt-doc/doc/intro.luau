local render = require("../render")

render.turbo_frame_rsp_start("doc-content")

    render.h1("what is zolt?", "doc-header")

    echo("<p>zolt is a tiny web server that speaks your language. you write your pages in <strong>luau</strong> a friendly, fast version of lua and zolt runs them for you. no build step, no framework, no fuss.</p>")

    echo("<p>it's a bit like php, but with lua instead. a request for <code>/hello.luau</code> simply runs the file <code>hello.luau</code> in your project folder and sends whatever it outputs back to the browser.</p>")

    echo("<p>here's the smallest zolt app you can write :) </p>")

    echo("<pre><code>echo(\"Hello, world!\");</code></pre>")

    echo("<p>that's it. save the file, visit it in your browser, and you have a working web page.</p>")

    echo("<p>everything else in your folder css, images, javascript is served as static files automatically. and since zolt is written in <strong>zig</strong>, it's small, fast, and starts up in the blink of an eye.</p>")

    echo("<p>in fact this documentation page is also powered by zolt as well.</p>")
render.turbo_frame_rsp_end()
