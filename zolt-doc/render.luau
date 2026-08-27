local M = {}

function M.html_start()
    echo("<!DOCTYPE html>");
    echo("<html>")
end

function M.html_end()
    echo("</html>")
end

function M.head_start()
    echo("<head>")
end

function M.head_scripts()
    echo("<script type=\"module\" src=\"https://cdn.jsdelivr.net/npm/@hotwired/turbo@latest/dist/turbo.es2017-esm.min.js\"></script>")
    echo("<script type=\"module\" src=\"https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/dist/stimulus.js\"></script>")
    echo("<script type=\"module\" src=\"/asset/js/application.js\"></script>")
end

function M.link_css(href: string)
    echo("<link rel=\"stylesheet\" href=\"" .. href .. "\">")
end

function M.head_end()
    echo("</head>")
end

function M.body_start()
    echo("<body>")
end

function M.body_end()
    echo("</body>")
end

function M.title(title: string)
    echo("<title>" .. title .. "</title>")
end

function M.h1(content: string)
    echo("<h1>".. content .. "</h1>")
end

function M.h1(content: string, class: string)
    echo("<h1 class=\"" .. class .. "\">".. content .. "</h1>")
end


function M.turbo_frame(id: string)
    echo("<turbo-frame id=\"" .. id .. "\">")
    echo("</turbo-frame>")
end

function M.turbo_frame_rsp_start(id: string)
    echo("<turbo-frame id=\"" .. id .. "\">")
end

function M.turbo_frame_rsp_end()
    echo("</turbo-frame>")
end

return M;
