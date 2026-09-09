HOL = require("@hol");
H = HOL.el;

local content =
        H("turbo-frame")
            :id("doc-content")
            :child(
                H("h1"):class("doc-header"):child("how to install zolt"),
                H("p"):child("getting zolt running takes about a minute. the fastest way is the install script: it grabs a ready-made binary for your operating system and architecture, puts it on your path, and keeps it up to date. terminal is all you need."),
                H("h2"):child("one-liner"),
                H("p"):child("if you have ", H("code"):child("curl"), " (you do), run this:"),
                H("pre"):child(H("code"):child("curl -fsSL https://zolt-doc.perr.dev/asset/install-zolt.sh | bash")),
                H("p"):child("that's it. ", H("code"):child("zoltd"), " lands in ", H("code"):child("~/.local/bin"), " and that folder gets added to your path. restart your shell (or run ", H("code"):child("source ~/.zshrc"), " / ", H("code"):child("source ~/.bashrc"), ") and you're ready to go."),
                H("h2"):child("options"),
                H("pre"):child(H("code"):child("./zolt-doc/asset/install-zolt.sh                 # latest, ~/.local/bin\n./zolt-doc/asset/install-zolt.sh --dir ~/bin    # different install folder\n./zolt-doc/asset/install-zolt.sh --version v0.1.0  # pin a specific release\n./zolt-doc/asset/install-zolt.sh --no-path        # skip editing your shell rc")),
                H("p"):child("on linux and macos zolt supports ", H("code"):child("x86_64"), " and ", H("code"):child("aarch64"), ". if your machine isn't one of those, sad."),
                H("h2"):child("manual install"),
                H("p"):child("no script? fine. grab the right file from the ", H("a"):attr("href", "https://github.com/iluvicecream/zolt/releases"):child("releases page"), ", then:"),
                H("pre"):child(H("code"):child("chmod +x zoltd-x86_64-linux\nmv zoltd-x86_64-linux ~/.local/bin/zoltd")),
                H("p"):child("make sure ", H("code"):child("~/.local/bin"), " is in your path, or drop the binary somewhere else that already is."),
                H("h2"):child("build from source"),
                H("p"):child("want to build it yourself? you'll need ", H("a"):attr("href", "https://ziglang.org/download/"):child("zig"), " 0.16.0. the first build downloads luau automatically, so it needs internet just that once:"),
                H("pre"):child(H("code"):child("git clone https://github.com/iluvicecream/zolt\ncd zolt\nzig build")),
                H("p"):child("when it finishes, you'll have the server at ", H("code"):child("zig-out/bin/zoltd"), ".")
            )

echo(content:render())
