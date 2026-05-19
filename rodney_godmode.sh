#!/bin/bash
set -e

echo "=== Rodney GodMode provisioning started ==="

unset HF_TOKEN
unset HUGGINGFACE_HUB_TOKEN
unset HUGGING_FACE_HUB_TOKEN

export HF_HOME="/workspace/.hf_home"
export HF_HUB_DISABLE_TELEMETRY=1
export COMFYUI_MANAGER_DISABLE_AUTO_UPDATE=true

mkdir -p /tmp/ckpts
mkdir -p /workspace/ComfyUI/models/clip_vision
mkdir -p /workspace/ComfyUI/models/loras
mkdir -p /workspace/ComfyUI/models/upscale_models

cd /workspace/ComfyUI

echo "=== Fix ComfyUI version ==="
git fetch --all || true
git checkout 9d273d3a || true

echo "=== Remove conflicting CRT-Nodes ==="
rm -rf /workspace/ComfyUI/custom_nodes/CRT-Nodes

echo "=== Fix KJNodes version ==="
cd /workspace/ComfyUI/custom_nodes
rm -rf ComfyUI-KJNodes
git clone https://github.com/kijai/ComfyUI-KJNodes.git
cd ComfyUI-KJNodes
git checkout 9d7af919b91838fb22e31ad0107a6ddcf8bd7f3f
pip install -r requirements.txt || true

echo "=== Install useful dependencies ==="
pip install simpleeval onnxruntime-gpu || true

echo "=== Download Anna LoRA ==="
wget -nc -O /workspace/ComfyUI/models/loras/anna.safetensors \
"https://huggingface.co/Rodney007/Anna/resolve/main/anna.safetensors" || true

echo "=== Download CLIP Vision H ==="
rm -f /workspace/ComfyUI/models/clip_vision/clip_vision_h.safetensors
wget -O /workspace/ComfyUI/models/clip_vision/clip_vision_h.safetensors \
"https://huggingface.co/stabilityai/stable-video-diffusion-img2vid-xt/resolve/main/image_encoder/model.safetensors"

echo "=== Verify CLIP Vision ==="
ls -lh /workspace/ComfyUI/models/clip_vision/clip_vision_h.safetensors

echo "=== Rodney GodMode provisioning complete ==="

rm -f /.provisioning
