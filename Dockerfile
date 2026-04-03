# syntax=docker/dockerfile:1
# ComfyUI + CUDA 12.8 + cuDNN (devel for xformers), aligned with comfyUI_AIO.sh.
#
# Build: ./build.sh   (GITHUB_TOKEN in .env or env; optional IMAGE_TAG)
#
# Run (GPU):
#   docker run --gpus all -p 3000:3000 -p 18188:18188 --env-file .env comfy-aio:cuda128
#
# Base tag: switch to 12.8.1-* if published for ubuntu22.04 on Docker Hub.
FROM nvidia/cuda:12.8.0-cudnn-devel-ubuntu22.04

# WORKSPACE: visible to every RUN and to the final container (install script + entrypoint; override with docker run -e).
# No GPU during docker build: PyTorch cannot detect SM versions → empty TORCH arch list → xformers IndexError in _get_cuda_arch_flags.
ARG TORCH_CUDA_ARCH_LIST="7.5;8.0;8.6;8.9;9.0"
ENV DEBIAN_FRONTEND=noninteractive \
    WORKSPACE=/workspace \
    PATH="/venv/main/bin:/usr/local/bin:${PATH}" \
    NVIDIA_VISIBLE_DEVICES=all \
    TORCH_CUDA_ARCH_LIST=${TORCH_CUDA_ARCH_LIST} \
    FORCE_CUDA=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    git \
    curl \
    wget \
    unzip \
    ninja-build \
    cmake \
    build-essential \
    supervisor \
    lsof \
    libgl1 \
    libglib2.0-0 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /venv/main \
    && /venv/main/bin/pip install --no-cache-dir --upgrade pip uv

# AWS CLI v2 (entrypoint: MinIO sync)
RUN _arch="$(uname -m)"; \
    case "${_arch}" in \
        x86_64) _aws_zip="awscli-exe-linux-x86_64.zip" ;; \
        aarch64) _aws_zip="awscli-exe-linux-aarch64.zip" ;; \
        *) _aws_zip="awscli-exe-linux-x86_64.zip" ;; \
    esac; \
    curl -fsSL "https://awscli.amazonaws.com/${_aws_zip}" -o /tmp/awscliv2.zip \
    && unzip -q /tmp/awscliv2.zip -d /tmp \
    && /tmp/aws/install --update -i /usr/local/aws-cli -b /usr/local/bin \
    && rm -rf /tmp/aws /tmp/awscliv2.zip

RUN mkdir -p /opt/supervisor-scripts /workspace/outputs \
    && ln -sf /usr/bin/python3 /usr/local/bin/python

COPY comfy.sh /opt/supervisor-scripts/comfy.sh
RUN chmod +x /opt/supervisor-scripts/comfy.sh \
    && sed -i 's/sudo //g' /opt/supervisor-scripts/comfy.sh

COPY docker/comfy.supervisor.conf /etc/supervisor/conf.d/comfy.conf

COPY docker/install-comfy-stack.sh /tmp/install-comfy-stack.sh
RUN chmod +x /tmp/install-comfy-stack.sh

RUN --mount=type=secret,id=github_token \
    GITHUB_TOKEN="$(cat /run/secrets/github_token)" /tmp/install-comfy-stack.sh \
    && rm -f /tmp/install-comfy-stack.sh

ARG COMFYUI_API_VERSION=1.17.1
RUN wget -q "https://github.com/SaladTechnologies/comfyui-api/releases/download/${COMFYUI_API_VERSION}/comfyui-api" -O /workspace/comfyui-api \
    && chmod +x /workspace/comfyui-api

COPY docker/entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

WORKDIR /workspace

EXPOSE 3000 18188

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
