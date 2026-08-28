#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "usage: $0 <ssh-host> <folder>"
    echo "example: $0 user@example.com todo-list"
    exit 1
fi

host="$1"
folder="$2"
zip_file="$2.zip"

trap 'rm -f "$zip_file"' EXIT

echo "zipping $folder ..."
if ! zip -rq "$zip_file" $folder; then
    echo "error: zip failed" >&2
    exit 1
fi

echo "uploading $zip_file to $host:/home ..."
out=$(cat "$zip_file" | ssh -o ConnectTimeout=10 "$host" "cat > /home/$zip_file && echo UPLOADED" || true)
if [[ "$out" != *UPLOADED* ]]; then
    echo "error: upload to $host failed" >&2
    exit 1
fi

echo "unzipping on $host ..."
out=$(ssh -o ConnectTimeout=10 "$host" "cd /home && unzip -o $zip_file && rm -f $zip_file && echo UNZIPPED" || true)
if [[ "$out" != *UNZIPPED* ]]; then
    echo "error: unzip on $host failed (is unzip installed there?)" >&2
    exit 1
fi

echo "done: $folder is at /home/$folder on $host (temporary zip removed)"
