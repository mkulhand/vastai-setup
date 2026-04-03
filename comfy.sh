#!/bin/bash

if command -v lsof >/dev/null 2>&1; then
    _pids=$(lsof -ti :18188 2>/dev/null || true)
    if [[ -n "${_pids}" ]]; then
        # shellcheck disable=SC2086
        kill -9 ${_pids} 2>/dev/null || true
    fi
fi

source /venv/main/bin/activate
# comfyui-api and ComfyUI must bind 0.0.0.0 for Docker -p … from the host (traffic is not 127.0.0.1 inside the container).
CMD='python3 /workspace/ComfyUI/main.py --listen 0.0.0.0 --port 18188 --disable-auto-launch --enable-cors-header'
STARTUP_CHECK_INTERVAL_S=5 OUTPUT_DIR="/workspace/outputs" HOST=0.0.0.0 CMD="${CMD}" COMFYUI_PORT_HOST=18188 BASE='' COMFY_HOME=/workspace/ComfyUI ./comfyui-api
