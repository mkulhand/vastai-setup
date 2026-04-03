#!/bin/bash

source /venv/main/bin/activate
if ! command -v uv >/dev/null 2>&1; then
    printf '%s\n' "uv is required (Vast base images ship it as /usr/local/bin/uv)." >&2
    exit 1
fi
COMFYUI_DIR=${WORKSPACE}/ComfyUI

wget https://raw.githubusercontent.com/mkulhand/vastai-setup/refs/heads/main/comfy.sh -O /opt/supervisor-scripts/comfy.sh
wget https://raw.githubusercontent.com/mkulhand/vastai-setup/refs/heads/main/comfy.conf -O /etc/supervisor/conf.d/comfy.conf

chmod +x /opt/supervisor-scripts/comfy.sh
ln -s /bin/python3 /bin/python
mkdir /workspace/outputs

# Install system dependencies
apt-get update && apt-get install -y \
    python3 python3-pip python3-venv python3-dev \
    git curl wget unzip ninja-build cmake build-essential \
    && rm -rf /var/lib/apt/lists/*

# AWS CLI v2
_arch="$(uname -m)"
case "${_arch}" in
    x86_64) _aws_zip="awscli-exe-linux-x86_64.zip" ;;
    aarch64) _aws_zip="awscli-exe-linux-aarch64.zip" ;;
    *) _aws_zip="awscli-exe-linux-x86_64.zip" ;;
esac
curl -fsSL "https://awscli.amazonaws.com/${_aws_zip}" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install --update -i /usr/local/aws-cli -b /usr/local/bin
rm -rf /tmp/aws /tmp/awscliv2.zip

# MinIO / S3-compatible — default AWS CLI config (only backend we use here).
# Env: S3_ENDPOINT or MINIO_ENDPOINT (e.g. http://host:9000), AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY.
# Region / addressing_style fixed for MinIO + SigV4 (no extra env vars needed).
_minio_endpoint="${S3_ENDPOINT:-${MINIO_ENDPOINT:-}}"
_minio_key="${AWS_ACCESS_KEY_ID:-}"
_minio_secret="${AWS_SECRET_ACCESS_KEY:-}"
if [[ -n "${_minio_endpoint}" && -n "${_minio_key}" && -n "${_minio_secret}" ]]; then
    aws configure set aws_access_key_id "${_minio_key}"
    aws configure set aws_secret_access_key "${_minio_secret}"
    aws configure set region us-east-1
    aws configure set output json
    aws configure set s3.endpoint_url "${_minio_endpoint}"
    aws configure set s3.signature_version s3v4
    aws configure set s3.addressing_style path
fi

# Clone ComfyUI
git clone https://github.com/comfyanonymous/ComfyUI.git
cd ${COMFYUI_DIR}
#git checkout v0.3.44

# Install Python packages (uv pip targets the active /venv/main)
uv pip install --upgrade pip \
    && uv pip install \
        torch --index-url https://download.pytorch.org/whl/cu128 \
    && uv pip install \
        torchaudio \
        torchvision \
        --index-url https://download.pytorch.org/whl/cu128 \
    && uv pip install -U --pre triton \
    && uv pip install sageattention==1.0.6

# Install additional libs
apt-get update && apt-get install -y libgl1 libglib2.0-0

# Install ComfyUI requirements
uv pip install -r $COMFYUI_DIR/requirements.txt
uv pip install sageattention onnx onnxruntime

# Install custom nodes
rm -rf ${COMFYUI_DIR}/custom_nodes/*
cd ${COMFYUI_DIR}/custom_nodes


# GITHUB_TOKEN: PAT with read access to ghazette/ComfyUI-Yamete-Pack
if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    printf '%s\n' "GITHUB_TOKEN is required to clone ComfyUI-Yamete-Pack (private repo)." >&2
    exit 1
fi

git clone "https://oauth2:${GITHUB_TOKEN}@github.com/ghazette/ComfyUI-Yamete-Pack.git" \
    && git clone https://github.com/ltdrdata/ComfyUI-Manager \
    && git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite \
    && git clone https://github.com/kijai/ComfyUI-KJNodes \
    && git clone https://github.com/cubiq/ComfyUI_essentials \
    && git clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation \
    && git clone https://github.com/pollockjj/ComfyUI-MultiGPU \
    && git clone https://github.com/asagi4/ComfyUI-Adaptive-Guidance \
    && git clone https://github.com/city96/ComfyUI-GGUF \
    && git clone https://github.com/kijai/ComfyUI-WanVideoWrapper \
    && git clone https://github.com/princepainter/ComfyUI-PainterI2V \
    && git clone https://github.com/filliptm/ComfyUI_Fill-Nodes \
    && git clone https://github.com/HenkDz/rgthree-comfy \
    && git clone https://github.com/ashtar1984/comfyui-find-perfect-resolution \
    && git clone https://github.com/ClownsharkBatwing/RES4LYF \
    && git clone https://github.com/ghazette/ComfyUI-WD14-Tagger \
    && git clone https://github.com/ssitu/ComfyUI_UltimateSDUpscale \
    && git clone https://github.com/ltdrdata/ComfyUI-Impact-Subpack \
    && git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack
    

cd $WORKSPACE
uv pip install -r ${COMFYUI_DIR}/custom_nodes/ComfyUI-Manager/requirements.txt \
    && uv pip install -r ${COMFYUI_DIR}/custom_nodes/ComfyUI-VideoHelperSuite/requirements.txt \
    && uv pip install -r ${COMFYUI_DIR}/custom_nodes/ComfyUI-KJNodes/requirements.txt \
    && uv pip install -r ${COMFYUI_DIR}/custom_nodes/ComfyUI_essentials/requirements.txt \
    && uv pip install -r ${COMFYUI_DIR}/custom_nodes/ComfyUI-Frame-Interpolation/requirements-no-cupy.txt \
    && uv pip install -r ${COMFYUI_DIR}/custom_nodes/ComfyUI-GGUF/requirements.txt \
    && uv pip install -r ${COMFYUI_DIR}/custom_nodes/ComfyUI-WanVideoWrapper/requirements.txt \
    && uv pip install -r ${COMFYUI_DIR}/custom_nodes/ComfyUI_Fill-Nodes/requirements.txt \
    && uv pip install -r ${COMFYUI_DIR}/custom_nodes/rgthree-comfy/requirements.txt \
    && uv pip install -r ${COMFYUI_DIR}/custom_nodes/RES4LYF/requirements.txt \
    && uv pip install -r ${COMFYUI_DIR}/custom_nodes/ComfyUI-WD14-Tagger/requirements.txt \
    && uv pip install -r ${COMFYUI_DIR}/custom_nodes/ComfyUI-Yamete-Pack/requirements.txt \
    && uv pip install -r ${COMFYUI_DIR}/custom_nodes/ComfyUI-Impact-Pack/requirements.txt \
    && uv pip install -r ${COMFYUI_DIR}/custom_nodes/ComfyUI-Impact-Subpack/requirements.txt
# Build xformers
git clone https://github.com/facebookresearch/xformers.git \
    && cd xformers \
    && uv pip install -r requirements.txt \
    && uv pip install ninja wheel cmake \
    && git submodule update --init --recursive \
    && FORCE_CUDA=1 uv pip install -e .

declare -a _minio_model_sync=(
    loraswan22:loras/video
    loras:loras/image
    textencoders:text_encoders
    vae:vae
    clipvision:clip_vision
    diffusionmodels:diffusion_models
    checkpoints:checkpoints
    esrgan:upscale_models
)
for _pair in "${_minio_model_sync[@]}"; do
    _bucket="${_pair%%:*}"
    _subdir="${_pair#*:}"
    mkdir -p "${COMFYUI_DIR}/models/${_subdir}"
    aws s3 sync "s3://${_bucket}/" "${COMFYUI_DIR}/models/${_subdir}/"
done

cd "${WORKSPACE}"

wget https://github.com/SaladTechnologies/comfyui-api/releases/download/1.17.1/comfyui-api

chmod +x comfyui-api

supervisorctl reread
supervisorctl update

# Packages are installed after nodes so we can fix them...

APT_PACKAGES=(
    #"package-1"
    #"package-2"
)

PIP_PACKAGES=(
    #"package-1"
    #"package-2"
)

NODES=(
    #"https://github.com/ltdrdata/ComfyUI-Manager"
    #"https://github.com/cubiq/ComfyUI_essentials"
)

WORKFLOWS=(

)

CHECKPOINT_MODELS=(
    
)

UNET_MODELS=(
)

LORA_MODELS=(
)

VAE_MODELS=(
)

ESRGAN_MODELS=(
)

CONTROLNET_MODELS=(
)

### DO NOT EDIT BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING ###

function provisioning_start() {
    provisioning_print_header
    provisioning_get_apt_packages
    provisioning_get_nodes
    provisioning_get_pip_packages
    provisioning_get_files \
        "${COMFYUI_DIR}/models/checkpoints" \
        "${CHECKPOINT_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/unet" \
        "${UNET_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/lora" \
        "${LORA_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/controlnet" \
        "${CONTROLNET_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/vae" \
        "${VAE_MODELS[@]}"
    provisioning_get_files \
        "${COMFYUI_DIR}/models/esrgan" \
        "${ESRGAN_MODELS[@]}"
    provisioning_print_end
}

function provisioning_get_apt_packages() {
    if [[ -n $APT_PACKAGES ]]; then
            sudo $APT_INSTALL ${APT_PACKAGES[@]}
    fi
}

function provisioning_get_pip_packages() {
    if [[ -n $PIP_PACKAGES ]]; then
            uv pip install --no-cache ${PIP_PACKAGES[@]}
    fi
}

function provisioning_get_nodes() {
    for repo in "${NODES[@]}"; do
        dir="${repo##*/}"
        path="${COMFYUI_DIR}custom_nodes/${dir}"
        requirements="${path}/requirements.txt"
        if [[ -d $path ]]; then
            if [[ ${AUTO_UPDATE,,} != "false" ]]; then
                printf "Updating node: %s...\n" "${repo}"
                ( cd "$path" && git pull )
                if [[ -e $requirements ]]; then
                   uv pip install --no-cache -r "$requirements"
                fi
            fi
        else
            printf "Downloading node: %s...\n" "${repo}"
            git clone "${repo}" "${path}" --recursive
            if [[ -e $requirements ]]; then
                uv pip install --no-cache -r "${requirements}"
            fi
        fi
    done
}

function provisioning_get_files() {
    if [[ -z $2 ]]; then return 1; fi
    
    dir="$1"
    mkdir -p "$dir"
    shift
    arr=("$@")
    printf "Downloading %s model(s) to %s...\n" "${#arr[@]}" "$dir"
    for url in "${arr[@]}"; do
        printf "Downloading: %s\n" "${url}"
        provisioning_download "${url}" "${dir}"
        printf "\n"
    done
}

function provisioning_print_header() {
    printf "\n##############################################\n#                                            #\n#          Provisioning container            #\n#                                            #\n#         This will take some time           #\n#                                            #\n# Your container will be ready on completion #\n#                                            #\n##############################################\n\n"
}

function provisioning_print_end() {
    printf "\nProvisioning complete:  Application will start now\n\n"
}

function provisioning_has_valid_hf_token() {
    [[ -n "$HF_TOKEN" ]] || return 1
    url="https://huggingface.co/api/whoami-v2"

    response=$(curl -o /dev/null -s -w "%{http_code}" -X GET "$url" \
        -H "Authorization: Bearer $HF_TOKEN" \
        -H "Content-Type: application/json")

    # Check if the token is valid
    if [ "$response" -eq 200 ]; then
        return 0
    else
        return 1
    fi
}

function provisioning_has_valid_civitai_token() {
    [[ -n "$CIVITAI_TOKEN" ]] || return 1
    url="https://civitai.com/api/v1/models?hidden=1&limit=1"

    response=$(curl -o /dev/null -s -w "%{http_code}" -X GET "$url" \
        -H "Authorization: Bearer $CIVITAI_TOKEN" \
        -H "Content-Type: application/json")

    # Check if the token is valid
    if [ "$response" -eq 200 ]; then
        return 0
    else
        return 1
    fi
}

# Download from $1 URL to $2 file path
function provisioning_download() {
    if [[ -n $HF_TOKEN && $1 =~ ^https://([a-zA-Z0-9_-]+\.)?huggingface\.co(/|$|\?) ]]; then
        auth_token="$HF_TOKEN"
    elif 
        [[ -n $CIVITAI_TOKEN && $1 =~ ^https://([a-zA-Z0-9_-]+\.)?civitai\.com(/|$|\?) ]]; then
        auth_token="$CIVITAI_TOKEN"
    fi
    if [[ -n $auth_token ]];then
        wget --header="Authorization: Bearer $auth_token" -qnc --content-disposition --show-progress -e dotbytes="${3:-4M}" -P "$2" "$1"
    else
        wget -qnc --content-disposition --show-progress -e dotbytes="${3:-4M}" -P "$2" "$1"
    fi
}

# Allow user to disable provisioning if they started with a script they didn't want
if [[ ! -f /.noprovisioning ]]; then
    provisioning_start
fi
