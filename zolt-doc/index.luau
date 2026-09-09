HOL = require("@hol");
H = HOL.el;

function NavLink(name:string,href: string,turbo_frame_id: string,class: string)
    return H("a")
        :attr("href", href)
        :class(class)
        :text(name)
        :attr("data-turbo-frame", turbo_frame_id)
        :attr("data-sidebar-target", "link")
        :attr("data-action", "sidebar#activate")
end

response.status(200);

local page = HOL.document()
    :title("Home | Zolt Documentation")
    :js("https://cdn.jsdelivr.net/npm/@hotwired/turbo@latest/dist/turbo.es2017-esm.min.js",{ type = "module" })
    :js("https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/dist/stimulus.js", { type = "module" })
    :js("/asset/js/application.js", { type = "module" })
    :css("asset/css/font.css")
    :css("asset/css/index.css")
    :css("asset/css/doc.css")
    :body(
        H("div")
            :class("flex-page")
            :child(
                H("div")
                    :class("sidebar")
                    :child(
                        H("div")
                            :class("sidebar-header")
                            :child(
                                H("h1"):text("Zolt"),
                                H("div")
                                    :class("sidebar-links")
                                    :attr("data-controller", "sidebar")
                                    :child(
                                        H("p"):class("group-sidebar"):text("get started"),
                                        NavLink("Introduction","/doc/intro.luau","doc-content","nav-link"),
                                        NavLink("Installation","/doc/install.luau","doc-content","nav-link"),
                                        NavLink("First web","/doc/firstweb.luau","doc-content","nav-link"),
                                        H("p"):class("group-sidebar"):text("reference"),
                                        NavLink("echo","/doc/ref/echo.luau","doc-content","nav-link"),
                                        NavLink("request.path","/doc/ref/request.luau","doc-content","nav-link"),
                                        NavLink("request.query","/doc/ref/query.luau","doc-content","nav-link"),
                                        NavLink("response.status","/doc/ref/status.luau","doc-content","nav-link"),
                                        NavLink("response.header","/doc/ref/header.luau","doc-content","nav-link"),
                                        H("p"):class("group-sidebar"):text("advanced"),
                                        NavLink("zolt-om","/doc/advance/","doc-content","nav-link")
                                    )
                            )
                    ),
                H("div")
                    :class("content")
                    :attr("data-controller", "page")
                    :child(
                        H("turbo-frame")
                            :attr("id", "doc-content")
                    )
            )
    )

echo(page:render())
