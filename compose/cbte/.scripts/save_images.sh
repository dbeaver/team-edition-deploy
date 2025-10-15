#!/usr/bin/env sh

# alias docker=podman

script_dir="$(realpath "$(dirname "$0")")"
compose_file="$script_dir/../docker-compose.yml"
# shellcheck disable=SC2016
images=$(grep 'image:' "$compose_file" \
    | awk '{print $2}' \
    | sed 's/${IMAGE_SOURCE:-dbeaver}/dbeaver/g' \
    | sed 's/${CLOUDBEAVER_VERSION_TAG}/25.2.0/g' \
    | sed 's/${PROXY_TYPE:-nginx}/nginx/g'
)
for image in $images; do
    docker pull "$image"
    file_name="$(echo "$image" | sed 's|^dbeaver/||' | tr '.' '_').tar.gz"
    echo "Saving $image to $file_name"
    docker save "$image" | gzip > "$file_name"
done
