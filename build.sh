#!/usr/bin/env bash
# Build the ComfyUI Docker image (BuildKit secret for GITHUB_TOKEN — not stored in layers).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

_saved_github_token="${GITHUB_TOKEN-}"
if [[ -f "${ROOT}/.env" ]]; then
    set -a
    # shellcheck disable=SC1091
    source "${ROOT}/.env"
    set +a
fi
if [[ -n "${_saved_github_token}" ]]; then
    export GITHUB_TOKEN="${_saved_github_token}"
fi

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    printf '%s\n' "GITHUB_TOKEN is required (export it or set it in .env)." >&2
    exit 1
fi

export DOCKER_BUILDKIT=1
IMAGE_TAG="${IMAGE_TAG:-comfy-aio:cuda128}"

docker build \
    --secret id=github_token,env=GITHUB_TOKEN \
    -t "${IMAGE_TAG}" \
    "$@" \
    .

printf '%s\n' "Built ${IMAGE_TAG}"
