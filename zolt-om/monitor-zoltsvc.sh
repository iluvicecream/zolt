#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "usage: $0 <ssh-host>"
    exit 1
fi

host="$1"

out=$(ssh -o ConnectTimeout=10 "$host" "systemctl list-units 'zoltsvc-*.service' --all --no-pager --plain" || true)

if [ -z "$out" ]; then
    echo "error: could not query $host" >&2
    exit 1
fi

if [[ "$out" == *"0 loaded units"* ]]; then
    echo "no zoltsvc services found on $host"
    exit 0
fi

echo "$out" | sed 's/^zoltsvc-//'
