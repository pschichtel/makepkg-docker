#!/usr/bin/env bash

set -euo pipefail

repo_name="ghcr.io/pschichtel/makepkg"
tmp_image_name="$repo_name:latest"

podman build --pull=always --iidfile "makepkg.iid" -t "$tmp_image_name" .
if [ -n "${GITHUB_DEFAULT_BRANCH:-}" ] && [ "${GITHUB_REF:-}" = "refs/heads/${GITHUB_DEFAULT_BRANCH}" ]
then
  version="$(podman run --rm "$tmp_image_name" yay --version | cut -d' ' -f2)"
  major_version="$(echo "$version" | cut -d'.' -f1)"
  podman tag "$tmp_image_name" "$repo_name:$version" "$repo_name:$major_version"
  podman push --digestfile "makepkg.latest.digest" "$(< "makepkg.iid")" "docker://$tmp_image_name"
  podman push --digestfile "makepkg.version.digest" "$(< "makepkg.iid")" "docker://$repo_name:$version"
  podman push --digestfile "makepkg.major-version.digest" "$(< "makepkg.iid")" "docker://$repo_name:$major_version"
fi

local_makepkg="$repo_name@$(podman inspect --format '{{.Digest}}' "$(< makepkg.iid)")"
sandbox_repo_name="ghcr.io/pschichtel/ai-sandbox"
sandbox_tmp_image_name="$sandbox_repo_name:latest"

podman build --iidfile ai-sandbox.iid --build-arg "BASE_IMAGE=$local_makepkg" -t "$sandbox_tmp_image_name" -f Dockerfile.ai-sandbox .
if [ -n "${GITHUB_DEFAULT_BRANCH:-}" ] && [ "${GITHUB_REF:-}" = "refs/heads/${GITHUB_DEFAULT_BRANCH}" ]
then
  sandbox_version="$(podman run --rm "$sandbox_tmp_image_name" yay --version | cut -d' ' -f2)"
  sandbox_major_version="$(echo "$version" | cut -d'.' -f1)"
  podman tag "$tmp_image_name" "$repo_name:$version" "$repo_name:$major_version"
  podman push "$(< "ai-sandbox.iid")" "docker://$sandbox_tmp_image_name"
  podman push "$(< "ai-sandbox.iid")" "docker://$sandbox_repo_name:$sandbox_version"
  podman push "$(< "ai-sandbox.iid")" "docker://$sandbox_repo_name:$sandbox_major_version"
fi


