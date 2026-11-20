#!/usr/bin/env bash

# Locate the microsandbox CA (<msb_runtime mount>/tls/ca.pem), install it as a system trust
# anchor and run update-ca-trust. Idempotent: does nothing if already installed.
set -euo pipefail

destination='/etc/ca-certificates/trust-source/anchors/microsandbox.crt'

# The CA lives on the virtiofs mount tagged "msb_runtime"; its mountpoint is not
# stable, so look it up by source name instead of scanning the filesystem.
mnt="$(findmnt -n -r -o TARGET -S msb_runtime | head -n1)"
if [[ -z "$mnt" ]]
then
    echo "no msb_runtime mount found" >&2
    exit 1
fi

src="$mnt/tls/ca.pem"
if [ ! -f "$src" ]
then
    echo "$src does not exist" >&2
    exit 1
fi
echo "found $src"

# Sanity checks: this file becomes a system-wide trust root.
openssl x509 -in "$src" -noout >/dev/null
subject=$(openssl x509 -in "$src" -noout -subject)
if ! [[ "$subject" == *microsandbox* ]]
then
    echo "refusing: unexpected subject: $subject" >&2
    exit 1
fi

if ! openssl x509 -in "$src" -noout -text | grep -q 'CA:TRUE'
then
    echo "refusing: certificate is not a CA" >&2
    exit 1
fi

if [ -f "$destination" ] && cmp -s "$src" "$destination"
then
    echo "already installed and up to date"
    exit 0
fi

install -D -m 0644 -o root -g root "$src" "$destination"

update-ca-trust
echo "installed $destination and ran update-ca-trust"

