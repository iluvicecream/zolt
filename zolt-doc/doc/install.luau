local render = require("../render")

render.turbo_frame_rsp_start("doc-content")

    render.h1("how to install zolt", "doc-header")

    echo("<p>getting zolt running takes about a minute. the fastest way is the install script: it grabs a ready-made binary for your operating system and architecture, puts it on your path, and keeps it up to date. terminal is all you need.</p>")

    echo("<h2>one-liner</h2>")

    echo("<p>if you have <code>curl</code> (you do), run this:</p>")

    echo("<pre><code>curl -fsSL https://zolt-doc.perr.dev/asset/install-zolt.sh | bash</code></pre>")

    echo("<p>that's it. <code>zoltd</code> lands in <code>~/.local/bin</code> and that folder gets added to your path. restart your shell (or run <code>source ~/.zshrc</code> / <code>source ~/.bashrc</code>) and you're ready to go.</p>")

    echo("<h2>options</h2>")

    echo("<pre><code>./zolt-doc/asset/install-zolt.sh                 # latest, ~/.local/bin\n./zolt-doc/asset/install-zolt.sh --dir ~/bin    # different install folder\n./zolt-doc/asset/install-zolt.sh --version v0.1.0  # pin a specific release\n./zolt-doc/asset/install-zolt.sh --no-path        # skip editing your shell rc</code></pre>")

    echo("<p>on linux and macos zolt supports <code>x86_64</code> and <code>aarch64</code>. if your machine isn't one of those, sad.</p>")

    echo("<h2>manual install</h2>")

    echo("<p>no script? fine. grab the right file from the <a href=\"https://github.com/iluvicecream/zolt/releases\">releases page</a>, then:</p>")

    echo("<pre><code>chmod +x zoltd-x86_64-linux\nmv zoltd-x86_64-linux ~/.local/bin/zoltd</code></pre>")

    echo("<p>make sure <code>~/.local/bin</code> is in your path, or drop the binary somewhere else that already is.</p>")

    echo("<h2>build from source</h2>")

    echo("<p>want to build it yourself? you'll need <a href=\"https://ziglang.org/download/\">zig</a> 0.16.0. the first build downloads luau automatically, so it needs internet just that once:</p>")

    echo("<pre><code>git clone https://github.com/iluvicecream/zolt\ncd zolt\nzig build</code></pre>")

    echo("<p>when it finishes, you'll have the server at <code>zig-out/bin/zoltd</code>.</p>")

render.turbo_frame_rsp_end()
