#!/bin/bash
# Build-time install: mirrors comfyUI_AIO.sh (ComfyUI, nodes, xformers). No MinIO sync (runtime entrypoint).
set -euo pipefail
source /venv/main/bin/activate

: "${WORKSPACE:=/workspace}"
COMFYUI_DIR="${WORKSPACE}/ComfyUI"

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    printf '%s\n' "GITHUB_TOKEN is required (private ComfyUI-Yamete-Pack)." >&2
    exit 1
fi

mkdir -p "${WORKSPACE}/outputs"

cd "${WORKSPACE}"
git clone https://github.com/comfyanonymous/ComfyUI.git
cd "${COMFYUI_DIR}"

uv pip install --upgrade pip \
    && uv pip install \
        torch --index-url https://download.pytorch.org/whl/cu128 \
    && uv pip install \
        torchaudio \
        torchvision \
        --index-url https://download.pytorch.org/whl/cu128 \
    && uv pip install -U --pre triton \
    && uv pip install onnxruntime-gpu==1.23.2

uv pip install -r "${COMFYUI_DIR}/requirements.txt"

rm -rf "${COMFYUI_DIR}/custom_nodes"/*
mkdir -p "${COMFYUI_DIR}/custom_nodes"
cd "${COMFYUI_DIR}/custom_nodes"

git clone "https://oauth2:${GITHUB_TOKEN}@github.com/ghazette/ComfyUI-Yamete-Pack.git" \
    && git clone https://github.com/ltdrdata/ComfyUI-Manager \
    && git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite \
    && git clone https://github.com/kijai/ComfyUI-KJNodes \
    && git clone https://github.com/cubiq/ComfyUI_essentials \
    && git clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation \
    && git clone https://github.com/asagi4/ComfyUI-Adaptive-Guidance \
    && git clone https://github.com/city96/ComfyUI-GGUF \
    && git clone https://github.com/kijai/ComfyUI-WanVideoWrapper \
    && git clone https://github.com/princepainter/ComfyUI-PainterI2V \
    && git clone https://github.com/filliptm/ComfyUI_Fill-Nodes \
    && git clone https://github.com/HenkDz/rgthree-comfy \
    && git clone https://github.com/ashtar1984/comfyui-find-perfect-resolution \
    && git clone https://github.com/ClownsharkBatwing/RES4LYF \
    && git clone https://github.com/ghazette/ComfyUI-WD14-Tagger \
    && git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack \
    && git clone https://github.com/ltdrdata/ComfyUI-Impact-Subpack \
    && git clone https://github.com/ssitu/ComfyUI_UltimateSDUpscale

cd "${WORKSPACE}"
uv pip install -r "${COMFYUI_DIR}/custom_nodes/ComfyUI-Manager/requirements.txt" \
    && uv pip install -r "${COMFYUI_DIR}/custom_nodes/ComfyUI-VideoHelperSuite/requirements.txt" \
    && uv pip install -r "${COMFYUI_DIR}/custom_nodes/ComfyUI-KJNodes/requirements.txt" \
    && uv pip install -r "${COMFYUI_DIR}/custom_nodes/ComfyUI_essentials/requirements.txt" \
    && uv pip install -r "${COMFYUI_DIR}/custom_nodes/ComfyUI-Frame-Interpolation/requirements-no-cupy.txt" \
    && uv pip install -r "${COMFYUI_DIR}/custom_nodes/ComfyUI-GGUF/requirements.txt" \
    && uv pip install -r "${COMFYUI_DIR}/custom_nodes/ComfyUI-WanVideoWrapper/requirements.txt" \
    && uv pip install -r "${COMFYUI_DIR}/custom_nodes/ComfyUI_Fill-Nodes/requirements.txt" \
    && uv pip install -r "${COMFYUI_DIR}/custom_nodes/rgthree-comfy/requirements.txt" \
    && uv pip install -r "${COMFYUI_DIR}/custom_nodes/RES4LYF/requirements.txt" \
    && uv pip install -r "${COMFYUI_DIR}/custom_nodes/ComfyUI-WD14-Tagger/requirements.txt" \
    && uv pip install -r "${COMFYUI_DIR}/custom_nodes/ComfyUI-Yamete-Pack/requirements.txt" \
    && uv pip install -r "${COMFYUI_DIR}/custom_nodes/ComfyUI-Impact-Pack/requirements.txt" \
    && uv pip install -r "${COMFYUI_DIR}/custom_nodes/ComfyUI-Impact-Subpack/requirements.txt"

cd "${WORKSPACE}"
uv pip install numpy
git clone https://github.com/facebookresearch/xformers.git \
    && cd xformers \
    && uv pip install -r requirements.txt \
    && uv pip install ninja wheel cmake \
    && git submodule update --init --recursive \
    && uv pip install -e .
