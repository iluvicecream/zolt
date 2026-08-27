#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "usage: $0 <ssh-host> <zoltsvc-name>"
    exit 1
fi

host="$1"
name="$2"

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

out=$(ssh -o ConnectTimeout=10 "$host" "systemctl start '$svc' && echo STARTED" || true)
if [[ "$out" != *STARTED* ]]; then
    echo "error: failed to start '$name' on $host" >&2
    exit 1
fi

echo "started '$name' on $host"
