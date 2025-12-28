#!/bin/bash

source /venv/main/bin/activate
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

# Clone ComfyUI
git clone https://github.com/comfyanonymous/ComfyUI.git
cd ${COMFYUI_DIR}
#git checkout v0.3.44

# Install Python packages
python3 -m pip install --upgrade pip \
    && python3 -m pip install \
        torch==2.8.0.dev20250317+cu128 \
        --index-url https://download.pytorch.org/whl/nightly/cu128 \
    && python3 -m pip install \
        torchaudio \
        torchvision \
        --index-url https://download.pytorch.org/whl/nightly/cu128 \
    && python3 -m pip install -U --pre triton \
    && python3 -m pip install sageattention==1.0.6

# Install additional libs
apt-get update && apt-get install -y libgl1 libglib2.0-0

# Install ComfyUI requirements
python3 -m pip install -r $COMFYUI_DIR/requirements.txt

# Install custom nodes
rm -rf ${COMFYUI_DIR}/custom_nodes/*
cd ${COMFYUI_DIR}/custom_nodes
git clone https://github.com/ltdrdata/ComfyUI-Manager comfyui-manager \
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
    && git clone https://github.com/ashtar1984/comfyui-find-perfect-resolution
    #&& git clone https://github.com/rgthree/rgthree-comfy.git \
    

cd $WORKSPACE
python3 -m pip install -r ${COMFYUI_DIR}/custom_nodes/comfyui-manager/requirements.txt \
    && python3 -m pip install -r ${COMFYUI_DIR}/custom_nodes/ComfyUI-VideoHelperSuite/requirements.txt \
    && python3 -m pip install -r ${COMFYUI_DIR}/custom_nodes/ComfyUI-KJNodes/requirements.txt \
    && python3 -m pip install -r ${COMFYUI_DIR}/custom_nodes/ComfyUI_essentials/requirements.txt \
    && python3 -m pip install -r ${COMFYUI_DIR}/custom_nodes/ComfyUI-Frame-Interpolation/requirements-no-cupy.txt \
    && python3 -m pip install -r ${COMFYUI_DIR}/custom_nodes/ComfyUI-GGUF/requirements.txt \
    && python3 -m pip install -r ${COMFYUI_DIR}/custom_nodes/ComfyUI-WanVideoWrapper/requirements.txt \
    && python3 -m pip install -r ${COMFYUI_DIR}/custom_nodes/ComfyUI_Fill-Nodes/requirements.txt \
    && python3 -m pip install -r ${COMFYUI_DIR}/custom_nodes/rgthree-comfy/requirements.txt

# Build xformers
git clone https://github.com/facebookresearch/xformers.git \
    && cd xformers \
    && pip install -r requirements.txt \
    && pip install ninja wheel cmake \
    && git submodule update --init --recursive \
    && FORCE_CUDA=1 pip install -e .

wget "https://github.com/Backblaze/B2_Command_Line_Tool/releases/latest/download/b2-linux" -O b2-linux
chmod +x b2-linux

./b2-linux sync --threads 25 b2://stable-models/comfy/loras ${COMFYUI_DIR}/models/loras/

cd ${COMFYUI_DIR}/models/diffusion_models/
wget https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp16.safetensors
wget https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp16.safetensors

cd ${COMFYUI_DIR}/models/loras
wget https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan21_T2V_14B_lightx2v_cfg_step_distill_lora_rank32.safetensors

cd ${COMFYUI_DIR}/models/text_encoders
wget https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors

cd ${COMFYUI_DIR}/models/clip_vision/
wget https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors

cd ${COMFYUI_DIR}/models/vae/
wget https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors

cd $WORKSPACE
wget https://github.com/SaladTechnologies/comfyui-api/releases/download/1.9.1/comfyui-api
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
            pip install --no-cache-dir ${PIP_PACKAGES[@]}
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
                   pip install --no-cache-dir -r "$requirements"
                fi
            fi
        else
            printf "Downloading node: %s...\n" "${repo}"
            git clone "${repo}" "${path}" --recursive
            if [[ -e $requirements ]]; then
                pip install --no-cache-dir -r "${requirements}"
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
