HOL = require("@hol");
H = HOL.el;

local content =
        H("turbo-frame")
            :id("doc-content")
            :child(
                H("h1"):class("doc-header"):child("what is zolt?"),
                H("p"):child("zolt is a tiny web server that speaks your language. you write your pages in ", H("strong"):child("luau"), " a friendly, fast version of lua and zolt runs them for you. no build step, no framework, no fuss."),
                H("p"):child("it's a bit like php, but with lua instead. a request for " , H("code"):child("/hello.luau") , " simply runs the file " , H("code"):child("hello.luau") , " in your project folder and sends whatever it outputs back to the browser."),
                H("p"):child("here's the smallest zolt app you can write :)"),
                H("pre"):child(H("code"):child("echo(\"Hello, world!\");")),
                H("p"):child("that's it. save the file, visit it in your browser, and you have a working web page."),
                H("p"):child("everything else in your folder css, images, javascript is served as static files automatically. and since zolt is written in " , H("strong"):child("zig") , ", it's small, fast, and starts up in the blink of an eye."),
                H("p"):child("in fact this documentation page is also powered by zolt as well.")
            )

echo(content:render())
