#!/usr/bin/env bash

set -euo pipefail

usage() {
    echo "usage: $0 <ssh-host> <config-path> <zoltd-binary-path> <svc-name>"
    echo "example: $0 user@example.com /home/myapp/config.luau /home/myapp/zoltd my-service"
}

if [ "$#" -ne 4 ]; then
    usage
    exit 1
fi

host="$1"
config_path="$2"
bin_path="$3"
name="$4"

case "$name" in
    "" | *[!a-zA-Z0-9_.-]* | -*)
        echo "error: invalid service name: $name" >&2
        exit 1
        ;;
esac

case "$name" in
    zoltsvc-*) svc="$name" ;;
    *) svc="zoltsvc-$name" ;;
esac

remote_unit="/etc/systemd/system/$svc.service"
work_dir=$(dirname "$config_path")

echo "checking remote files on $host ..."
out=$(ssh -o ConnectTimeout=10 "$host" "test -f '$config_path' && test -f '$bin_path' && echo FILES_OK" || true)
if [[ "$out" != *FILES_OK* ]]; then
    echo "error: config or binary not found on $host ($config_path, $bin_path)" >&2
    exit 1
fi

echo "writing systemd unit ..."
unit=$(
    printf '[Unit]\nDescription=zolt service: %s\nAfter=network.target\n\n' "$name"
    printf '[Service]\nType=simple\nWorkingDirectory=%s\nExecStart=%s %s\nRestart=on-failure\nRestartSec=3\n\n' "$work_dir" "$bin_path" "$config_path"
    printf '[Install]\nWantedBy=multi-user.target\n'
)
out=$(printf '%s' "$unit" | ssh -o ConnectTimeout=10 "$host" "systemctl stop '$svc' 2>/dev/null || true; cat > '$remote_unit' && echo UNIT_OK" || true)
if [[ "$out" != *UNIT_OK* ]]; then
    echo "error: could not write unit file" >&2
    exit 1
fi

echo "reloading systemd and starting service ..."
out=$(ssh -o ConnectTimeout=10 "$host" "systemctl daemon-reload && systemctl enable '$svc' >/dev/null 2>&1 && systemctl restart '$svc' && sleep 1 && systemctl is-active '$svc'" || true)
if [[ "$out" != *active* ]]; then
    echo "error: service did not start (status: ${out:-unknown})" >&2
    exit 1
fi

echo "done: service '$name' is active on $host (unit: $remote_unit)"

out=$(ssh -o ConnectTimeout=10 "$host" "file '$bin_path'" || true)
case "$out" in
    *ELF*) ;;
    *)
        echo "note: '$bin_path' does not look like a Linux ELF binary ($out). It may fail to run on this host." >&2
        ;;
esac
