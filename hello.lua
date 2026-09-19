local utils = require("utils")

http_status(200)
http_content_type("text/zoltd")
http_header_add("PoweredBy","ZOLT")
echo("<h1>hello</h1>")