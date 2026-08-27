local render = require("../render")

render.turbo_frame_rsp_start("doc-content")

    render.h1("how to install zolt", "doc-header")

    echo("<p>getting zolt running takes about a minute. the fastest way is to grab a ready-made binary, <s>attention</s> terminal is all you need.</p>")

    echo("<h2>a. prebuilt binary</h2>")

    echo("<p>download the latest release from <a href=\"https://github.com/iluvicecream/zolt/releases\">GitHub</a>. no build step needed just download it and run <code>./zoltd</code>.</p>")


    echo("<h2>b. build from source</h2>")

    echo("<p>just why? but well. you will need zig. zolt is built with <a href=\"https://ziglang.org/download/\">Zig</a> 0.16 or newer. On macOS, the easiest way to install Homebrew:</p>")

    echo("<pre><code>brew install zig</code></pre>")

    echo("<p>on other systems, grab the installer from the <a href=\"https://ziglang.org/download/\">zig download page</a>.</p>")

    echo("<h2>clone the thing</h2>")

    echo("<pre><code>git clone https://github.com/iluvicecream/zolt.git\ncd zolt</code></pre>")

    echo("<h2>build!!</h2>")

    echo("<p>run this inside the zolt folder the first build downloads Luau automatically, so it needs internet just that once:</p>")

    echo("<pre><code>zig build</code></pre>")

    echo("<p>when it finishes, you'll have the server at <code>zig-out/bin/zoltd</code>.</p>")

    echo("<h2 id=\"runit\">run it</h2>")

    echo("<pre><code>zig build run</code></pre>")

    echo("<p>then open <a href=\"http://127.0.0.1:8080\">http://127.0.0.1:8080</a> in your browser you should see demo page. that it!</p>")

    echo("<p>you can also run the binary directly. it reads <code>config.luau</code> from the folder you're in:</p>")

    echo("<pre><code>./zig-out/bin/zoltd</code></pre>")

    echo("<h2>profit :)</h2>")
    echo("<p>sky the limit now. so just follow the documentation here and you'll be fineeee <:")

render.turbo_frame_rsp_end()
