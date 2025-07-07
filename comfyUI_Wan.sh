#!/bin/bash

source /venv/main/bin/activate
COMFYUI_DIR=${WORKSPACE}/ComfyUI

wget "https://huggingface.co/city96/Wan2.1-I2V-14B-480P-gguf/resolve/main/wan2.1-i2v-14b-480p-Q8_0.gguf" -O $COMFYUI_DIR/models/diffusion_models/wan2.1-i2v-14b-480p-Q8_0.gguf
wget "https://huggingface.co/city96/Wan2.1-I2V-14B-720P-gguf/resolve/main/wan2.1-i2v-14b-720p-Q8_0.gguf" -O $COMFYUI_DIR/models/diffusion_models/wan2.1-i2v-14b-720p-Q8_0.gguf
wget "https://huggingface.co/city96/Wan2.1-T2V-14B-gguf/resolve/main/wan2.1-t2v-14b-Q8_0.gguf" -O $COMFYUI_DIR/models/diffusion_models/wan2.1-t2v-14b-Q8_0.gguf
wget "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp16.safetensors" -O $COMFYUI_DIR/models/text_encoders/umt5_xxl_fp16.safetensors
wget "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors" -O $COMFYUI_DIR/models/clip_vision/clip_vision_h.safetensors
wget "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors" -O $COMFYUI_DIR/models/vae/wan_2.1_vae.safetensors


echo "Sage, Triton and Pytorch Auto-Installer."

INCLUDE_LIBS_URL="https://github.com/woct0rdho/triton-windows/releases/download/v3.0.0-windows.post1/python_3.12.7_include_libs.zip"

export PYTHONUTF8=1
export PYTHONIOENCODING=utf-8
PYTHON="python3"

echo "Installing Visual Studio Build Tools - skipped on Linux/macOS"

echo "Installing Triton"
$PYTHON -s -m pip install -U --pre triton

FILE_NAME=$(basename "$INCLUDE_LIBS_URL")

echo "Downloading Python include/libs from URL"
curl -L -o "$FILE_NAME" "$INCLUDE_LIBS_URL"

echo "Extracting Python include/libs using unzip"
unzip -o "$FILE_NAME" -d python_embeded

echo "Installing SageAttention"
$PYTHON -s -m pip install sageattention==1.0.6


echo "Installing Custom Extensions"
$COMFYUI_DIR ComfyUI/custom_nodes || exit 1
git clone https://github.com/ltdrdata/ComfyUI-Manager comfyui-manager
git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite
git clone https://github.com/kijai/ComfyUI-KJNodes
git clone https://github.com/cubiq/ComfyUI_essentials
git clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation
git clone https://github.com/pollockjj/ComfyUI-MultiGPU
git clone https://github.com/asagi4/ComfyUI-Adaptive-Guidance
git clone https://github.com/city96/ComfyUI-GGUF
git clone https://github.com/kijai/ComfyUI-WanVideoWrapper

echo "Installing Custom Extensions Requirements"
cd ../..
python3 -m pip install -r $COMFYUI_DIR/custom_nodes/comfyui-manager/requirements.txt
python3 -m pip install -r $COMFYUI_DIR/custom_nodes/ComfyUI-VideoHelperSuite/requirements.txt
python3 -m pip install -r $COMFYUI_DIR/custom_nodes/ComfyUI-KJNodes/requirements.txt
python3 -m pip install -r $COMFYUI_DIR/custom_nodes/ComfyUI_essentials/requirements.txt
python3 -m pip install -r $COMFYUI_DIR/custom_nodes/ComfyUI-Frame-Interpolation/requirements-with-cupy.txt
python3 -m pip install -r $COMFYUI_DIR/custom_nodes/ComfyUI-GGUF/requirements.txt
python3 -m pip install -r $COMFYUI_DIR/custom_nodes/ComfyUI-WanVideoWrapper/requirements.txt

echo "Done."


python3 -m pip install torch==2.8.0.dev20250317+cu128 --index-url https://download.pytorch.org/whl/nightly/cu128 --force-reinstall

python3 -m pip install torchaudio torchvision --index-url https://download.pytorch.org/whl/nightly/cu128 --force-reinstall

sudo apt update
sudo apt install -y ninja-build git cmake build-essential python3-dev
git clone https://github.com/facebookresearch/xformers.git
cd xformers
pip install -r requirements.txt
pip install ninja wheel cmake
git submodule update --init --recursive
/venv/main/bin/python -m pip install -e .

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
