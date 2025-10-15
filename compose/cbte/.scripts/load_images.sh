#!/usr/bin/env sh

## This script loads all images saved by save_images.sh. It assumes that
## the .tar.gz files are in the same directory as this script.

# alias docker=podman

script_dir="$(realpath "$(dirname "$0")")"
for image in "$script_dir"/*.tar.gz; do
    echo "Loading $image"
    docker load < "$image"
done
