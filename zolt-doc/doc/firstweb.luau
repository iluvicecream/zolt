HOL = require("@hol");
H = HOL.el;

local content =
        H("turbo-frame")
            :id("doc-content")
            :child(
                H("h1"):class("doc-header"):child("your first web page"),
                H("p"):child("ok, zolt is installed. time to make something appear in the browser. you'll have a working hello world in about thirty seconds. (jk prob gonna take longer than that)"),
                H("h2"):child("make an app folder"),
                H("p"):child("everything a zolt app needs lives in one folder. make one and step inside:"),
                H("pre"):child(H("code"):child("mkdir myapp\ncd myapp")),
                H("h2"):child("tell zolt where to listen"),
                H("p"):child("create ", H("code"):child("config.luau"), " with the address you want the server to listen on:"),
                H("pre"):child(H("code"):child("return {\n    host = \"127.0.0.1:8080\",\n}")),
                H("p"):child("that's a plain lua file, so you can change the port anytime. ", H("code"):child("127.0.0.1:8080"), " is a great default for local development."),
                H("h2"):child("write your first page"),
                H("p"):child("now create ", H("code"):child("index.luau"), " in the same folder. requests to ", H("code"):child("/"), " run this file:"),
                H("pre"):child(H("code"):child("echo(\"Hello, world!\");")),
                H("p"):child("that's the whole app. ", H("code"):child("echo"), " sends text back to the browser, just like ", H("code"):child("print"), " in other languages."),
                H("h2"):child("run it"),
                H("p"):child("start the server from your app folder:"),
                H("pre"):child(H("code"):child("zoltd")),
                H("p"):child("zolt reads ", H("code"):child("config.luau"), " from the folder you're in and serves that folder as the webroot. you can also point it at a config anywhere:"),
                H("pre"):child(H("code"):child("zoltd /path/to/myapp/config.luau")),
                H("p"):child("now open ", H("a"):attr("href", "http://127.0.0.1:8080"):child("http://127.0.0.1:8080"), " in your browser. hello, world! welcome to zolt."),
                H("h2"):child("make it a bit more interesting"),
                H("p"):child("every ", H("code"):child(".luau"), " file is its own route. add a ", H("code"):child("hello.luau"), ":"),
                H("pre"):child(H("code"):child("echo(\"<h1>hello from zolt!</h1>\");\necho(\"<p>you are at \" .. request.path() .. \"</p>\");")),
                H("p"):child("save it and visit ", H("a"):attr("href", "http://127.0.0.1:8080/hello.luau"):child("http://127.0.0.1:8080/hello.luau"), ". the ", H("code"):child("request"), " tells your route about the incoming request, starting with ", H("code"):child("path()"), "."),
                H("p"):child("everything else in your folder is served as a static file automatically, so css, images, and javascript just work next to your routes."),
                H("p"):child("that's the tour. check out the ", H("a"):attr("href", "/doc/intro.luau"):child("introduction"), " or the ", H("a"):attr("href", "/doc/install.luau"):child("install guide"), " if you skipped ahead, then go build something :)")
            )

echo(content:render())
