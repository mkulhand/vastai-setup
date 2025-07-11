#!/bin/bash

#kill any comfyUI process before starting comfy-api
sudo kill -9 $(sudo lsof -t -i :18188)

source /venv/main/bin/activate
HOST=127.0.0.1 CMD='python3 /workspace/ComfyUI/main.py --disable-auto-launch --port 18188 --enable-cors-header' COMFYUI_PORT_HOST=18188 BASE='' COMFY_HOME=/workspace/ComfyUI ./comfyui-api
