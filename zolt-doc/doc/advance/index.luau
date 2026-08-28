local render = require("../../render")

render.turbo_frame_rsp_start("doc-content")

    render.h1("zolt-om", "doc-header")

    echo("<p>zolt-om is a small set of operations scripts for running zolt as a real service on a linux server. they manage <code>systemd</code> units over ssh, so your app stays up, restarts on failure, and starts on boot.</p>")

    echo("<h2>requirements</h2>")

    echo("<p>you need <code>bash</code> and <code>ssh</code> locally, and the target server needs <code>systemd</code>. the zoltd binary and a config file must already be on the server.</p>")

    echo("<h2>create a service</h2>")

    echo("<pre><code>./zolt-om/create-zoltsvc.sh user@example.com /home/myapp/config.luau /home/myapp/zoltd my-service</code></pre>")

    echo("<p>this checks that the config and binary exist on the server, writes a systemd unit, enables it, and starts it. services are named <code>zoltsvc-&lt;name&gt;</code>, so <code>my-service</code> becomes <code>zoltsvc-my-service</code>.</p>")

    echo("<p>the unit runs <code>zoltd /home/myapp/config.luau</code> from the config's folder, restarts automatically if it crashes, and starts on boot.</p>")

    echo("<h2>control a service</h2>")

    echo("<p>start, stop, or restart a service from your machine:</p>")

    echo("<pre><code>./zolt-om/start-zoltsvc.sh user@example.com my-service\n./zolt-om/stop-zoltsvc.sh user@example.com my-service\n./zolt-om/restart-zoltsvc.sh user@example.com my-service</code></pre>")

    echo("<p>you can pass the full unit name (<code>zoltsvc-my-service</code>) or just the short name; the scripts handle both.</p>")

    echo("<h2>monitor services</h2>")

    echo("<p>list every zolt service on a server and its status:</p>")

    echo("<pre><code>./zolt-om/monitor-zoltsvc.sh user@example.com</code></pre>")

    echo("<h2>delete a service</h2>")

    echo("<p>stop and remove a service, including its systemd unit:</p>")

    echo("<pre><code>./zolt-om/delete-zoltsvc.sh user@example.com my-service</code></pre>")

    echo("<h2>notes</h2>")

    echo("<p>each script fails loudly with a clear error instead of pretending things worked, and every command runs over ssh with a 10 second connect timeout.</p>")

    echo("<p>the scripts live in <code>zolt-om/</code> in the repo: <code>create</code>, <code>start</code>, <code>stop</code>, <code>restart</code>, <code>monitor</code>, and <code>delete</code>.</p>")

render.turbo_frame_rsp_end()
