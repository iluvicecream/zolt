local utils = require("utils")
local version = require("@version")

http_status(200)
http_header_add("PoweredBy","ZOLT")
echo("<h1>hello</h1>")
echo("<p>current version = " .. version.version .. "</p>")
