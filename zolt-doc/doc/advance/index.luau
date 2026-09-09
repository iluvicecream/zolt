HOL = require("@hol");
H = HOL.el;

local content =
        H("turbo-frame")
            :id("doc-content")
            :child(
                H("h1"):class("doc-header"):child("zolt-om"),
                H("p"):child("zolt-om is a small set of operations scripts for running zolt as a real service on a linux server. they manage ", H("code"):child("systemd"), " units over ssh, so your app stays up, restarts on failure, and starts on boot."),
                H("h2"):child("requirements"),
                H("p"):child("you need ", H("code"):child("bash"), " and ", H("code"):child("ssh"), " locally, and the target server needs ", H("code"):child("systemd"), ". the zoltd binary and a config file must already be on the server."),
                H("h2"):child("create a service"),
                H("pre"):child(H("code"):child("./zolt-om/create-zoltsvc.sh user@example.com /home/myapp/config.luau /home/myapp/zoltd my-service")),
                H("p"):child("this checks that the config and binary exist on the server, writes a systemd unit, enables it, and starts it. services are named ", H("code"):child("zoltsvc-<name>"), ", so ", H("code"):child("my-service"), " becomes ", H("code"):child("zoltsvc-my-service"), "."),
                H("p"):child("the unit runs ", H("code"):child("zoltd /home/myapp/config.luau"), " from the config's folder, restarts automatically if it crashes, and starts on boot."),
                H("h2"):child("control a service"),
                H("p"):child("start, stop, or restart a service from your machine:"),
                H("pre"):child(H("code"):child("./zolt-om/start-zoltsvc.sh user@example.com my-service\n./zolt-om/stop-zoltsvc.sh user@example.com my-service\n./zolt-om/restart-zoltsvc.sh user@example.com my-service")),
                H("p"):child("you can pass the full unit name (", H("code"):child("zoltsvc-my-service"), ") or just the short name; the scripts handle both."),
                H("h2"):child("monitor services"),
                H("p"):child("list every zolt service on a server and its status:"),
                H("pre"):child(H("code"):child("./zolt-om/monitor-zoltsvc.sh user@example.com")),
                H("h2"):child("delete a service"),
                H("p"):child("stop and remove a service, including its systemd unit:"),
                H("pre"):child(H("code"):child("./zolt-om/delete-zoltsvc.sh user@example.com my-service")),
                H("h2"):child("notes"),
                H("p"):child("each script fails loudly with a clear error instead of pretending things worked, and every command runs over ssh with a 10 second connect timeout."),
                H("p"):child("the scripts live in ", H("code"):child("zolt-om/"), " in the repo: ", H("code"):child("create"), ", ", H("code"):child("start"), ", ", H("code"):child("stop"), ", ", H("code"):child("restart"), ", ", H("code"):child("monitor"), ", and ", H("code"):child("delete"), ".")
            )

echo(content:render())
