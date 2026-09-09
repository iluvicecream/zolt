HOL = require("hol_dev");
local H = HOL.el

local page = HOL.document()
    :title("Home | My Luau Site")
    :body(
        H("header"):child(
            H("h1"):text("Welcome to My Website")
        ),
        H("main"):class("container"):child(
            H("p"):text("This HTML was generated cleanly with zero pre-parsers!")
        )
    )

echo(page:render())
