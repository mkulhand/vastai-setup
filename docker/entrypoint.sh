#!/bin/bash
# Runtime: optional MinIO/S3 model sync, then supervisord.
# MINIO_SYNC=0|false|no|off → skip sync (models on volume or sync done elsewhere).
# When enabled, aws s3 sync is incremental (only new/changed objects).
set -euo pipefail

: "${WORKSPACE:=/workspace}"
COMFYUI_DIR="${WORKSPACE}/ComfyUI"
export PATH="/venv/main/bin:${PATH}"

_minio_endpoint="${S3_ENDPOINT:-${MINIO_ENDPOINT:-}}"
_minio_key="${AWS_ACCESS_KEY_ID:-}"
_minio_secret="${AWS_SECRET_ACCESS_KEY:-}"

_run_sync=1
_msync="${MINIO_SYNC:-1}"
if [[ "${_msync}" == "0" || "${_msync,,}" == "false" || "${_msync,,}" == "no" || "${_msync,,}" == "off" ]]; then
    _run_sync=0
fi

if [[ -n "${_minio_endpoint}" && -n "${_minio_key}" && -n "${_minio_secret}" && "${_run_sync}" -eq 1 ]]; then
    aws configure set aws_access_key_id "${_minio_key}"
    aws configure set aws_secret_access_key "${_minio_secret}"
    aws configure set region us-east-1
    aws configure set output json
    aws configure set s3.endpoint_url "${_minio_endpoint}"
    aws configure set s3.signature_version s3v4
    aws configure set s3.addressing_style path
    export AWS_ENDPOINT_URL_S3="${_minio_endpoint}"

    declare -a _minio_model_sync=(
        loraswan22:loras/video
        loras:loras/image
        textencoders:text_encoders
        vae:vae
        clipvision:clip_vision
        diffusionmodels:diffusion_models
        checkpoints:checkpoints
        esrgan:upscale_models
        ultralytics:ultralytics
        sams:sams
    )
    for _pair in "${_minio_model_sync[@]}"; do
        _bucket="${_pair%%:*}"
        _subdir="${_pair#*:}"
        mkdir -p "${COMFYUI_DIR}/models/${_subdir}"
        aws s3 sync --endpoint-url "${_minio_endpoint}" "s3://${_bucket}/" "${COMFYUI_DIR}/models/${_subdir}/"
    done
elif [[ -n "${_minio_endpoint}" && -n "${_minio_key}" && -n "${_minio_secret}" && "${_run_sync}" -eq 0 ]]; then
    printf '%s\n' "MINIO_SYNC disabled: skipping S3 sync (expect models under ${COMFYUI_DIR}/models)." >&2
fi

exec supervisord -n -c /etc/supervisor/supervisord.conf
