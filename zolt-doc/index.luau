local render = require("./render");

function NavLink(name:string,href: string,turbo_frame_id: string,class: string)
    echo("<a href=\"" .. href .. "\" data-turbo-frame=\"" .. turbo_frame_id .. "\" class=\"" .. class .. "\" data-sidebar-target=\"link\" data-action=\"sidebar#activate\" >" .. name .. "</a>");
end

status(200);

render.html_start();

    render.head_start();

        render.title("Zolt Documentation");
        render.head_scripts();
        render.link_css("asset/css/font.css");
        render.link_css("asset/css/index.css");
        render.link_css("asset/css/doc.css");

    render.head_end();

    render.body_start();

        echo("<div class=\"flex-page\">");

            echo("<div class=\"sidebar\">");
                render.h1("Zolt","sidebar-header");
                echo("<div data-controller=\"sidebar\" class=\"sidebar-links\">");
                    echo("<p class=\"group-sidebar\" >get started</p>")
                    NavLink("Introduction","/doc/intro.luau","doc-content","nav-link");
                    NavLink("Installation","/doc/install.luau","doc-content","nav-link");
                    NavLink("First web","/doc/firstweb.luau","doc-content","nav-link");
                    echo("<p class=\"group-sidebar\">reference</p>")
                    NavLink("echo","/doc/ref/echo.luau","doc-content","nav-link");
                echo("</div>");
            echo("</div>");

            echo("<div class=\"content\" data-controller=\"page\">");
               render.turbo_frame("doc-content");
            echo("</div>");

        echo("</div>");

    render.body_end();

render.html_end();
