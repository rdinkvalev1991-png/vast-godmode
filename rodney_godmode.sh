#!/bin/bash
set -e

echo "=== Rodney GodMode provisioning started ==="

# Prevent broken empty HF Bearer token
unset HF_TOKEN
unset HUGGINGFACE_HUB_TOKEN
unset HUGGING_FACE_HUB_TOKEN

export HF_HOME="/workspace/.hf_home"
export HF_HUB_DISABLE_TELEMETRY=1
export HF_XET_HIGH_PERFORMANCE=1
export COMFYUI_MANAGER_DISABLE_AUTO_UPDATE=true

PY="/venv/main/bin/python"

require_file() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "❌ Missing required file: $file"
    echo "Provisioning failed. ComfyUI will not be started with broken/missing models."
    exit 1
  fi
  echo "✅ Found: $file"
}

move_if_exists() {
  local src="$1"
  local dst="$2"
  if [ -f "$src" ]; then
    mkdir -p "$(dirname "$dst")"
    mv "$src" "$dst"
  fi
}

echo "=== Create folders ==="

mkdir -p /tmp/ckpts

mkdir -p /workspace/ComfyUI/models/clip_vision
mkdir -p /workspace/ComfyUI/models/loras
mkdir -p /workspace/ComfyUI/models/upscale_models
mkdir -p /workspace/ComfyUI/models/diffusion_models
mkdir -p /workspace/ComfyUI/models/unet
mkdir -p /workspace/ComfyUI/models/text_encoders
mkdir -p /workspace/ComfyUI/models/vae
mkdir -p /workspace/ComfyUI/models/detection
mkdir -p /workspace/ComfyUI/models/ultralytics/bbox
mkdir -p /workspace/ComfyUI/models/ultralytics/segm
mkdir -p /workspace/ComfyUI/models/sam2

mkdir -p /workspace/ComfyUI/custom_nodes/comfyui_controlnet_aux/ckpts/yzd-v/DWPose
mkdir -p /workspace/ComfyUI/custom_nodes/comfyui_controlnet_aux/ckpts/hr16/DWPose-TorchScript-BatchSize5

cd /workspace/ComfyUI

echo "=== Fix ComfyUI version ==="
git fetch --all || true
git checkout 9d273d3a || true

echo "=== Remove conflicting CRT-Nodes ==="
rm -rf /workspace/ComfyUI/custom_nodes/CRT-Nodes

echo "=== Install required custom nodes ==="
cd /workspace/ComfyUI/custom_nodes

git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git || true
git clone https://github.com/kijai/ComfyUI-WanAnimatePreprocess.git || true
git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git || true
git clone https://github.com/chrisgoringe/cg-use-everywhere.git || true
git clone https://github.com/kijai/ComfyUI-segment-anything-2.git || true
git clone https://github.com/Fannovel16/comfyui_controlnet_aux.git || true
git clone https://github.com/rgthree/rgthree-comfy.git || true
git clone https://github.com/cubiq/ComfyUI_essentials.git || true
git clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git || true
git clone https://github.com/WASasquatch/was-node-suite-comfyui.git || true
git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git || true
git clone https://github.com/ltdrdata/ComfyUI-Impact-Subpack.git || true
git clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git || true
git clone https://github.com/ClownsharkBatwing/RES4LYF.git || true

echo "=== Fix KJNodes version ==="
cd /workspace/ComfyUI/custom_nodes
rm -rf ComfyUI-KJNodes
git clone https://github.com/kijai/ComfyUI-KJNodes.git
cd ComfyUI-KJNodes
git checkout 9d7af919b91838fb22e31ad0107a6ddcf8bd7f3f

echo "=== Install useful dependencies ==="
$PY -m pip install --upgrade pip setuptools wheel || true

$PY -m pip install \
simpleeval \
onnx \
onnxruntime \
onnxruntime-gpu \
piexif \
ultralytics \
accelerate \
opencv-python-headless \
imageio-ffmpeg \
numba \
PyWavelets \
scipy \
scikit-image \
matplotlib \
pandas \
tqdm \
einops \
gguf \
ftfy \
segment-anything \
dill \
diffusers \
transformers \
sentencepiece \
safetensors \
tokenizers \
protobuf \
huggingface_hub \
hf_xet \
peft \
kornia \
spandrel \
soundfile \
av \
decord \
timm \
omegaconf \
yacs \
addict \
mediapipe \
filterpy \
loguru \
rich \
psutil \
|| true

echo "=== Install custom node requirements ==="
cd /workspace/ComfyUI

$PY -m pip install -r custom_nodes/ComfyUI-WanVideoWrapper/requirements.txt || true
$PY -m pip install -r custom_nodes/ComfyUI-WanAnimatePreprocess/requirements.txt || true
$PY -m pip install -r custom_nodes/ComfyUI-VideoHelperSuite/requirements.txt || true
$PY -m pip install -r custom_nodes/ComfyUI-segment-anything-2/requirements.txt || true
$PY -m pip install -r custom_nodes/comfyui_controlnet_aux/requirements.txt || true
$PY -m pip install -r custom_nodes/ComfyUI-KJNodes/requirements.txt || true
$PY -m pip install -r custom_nodes/was-node-suite-comfyui/requirements.txt || true
$PY -m pip install -r custom_nodes/ComfyUI-Frame-Interpolation/requirements.txt || true
$PY -m pip install -r custom_nodes/RES4LYF/requirements.txt || true
$PY -m pip install -r custom_nodes/ComfyUI-Impact-Pack/requirements.txt || true
$PY -m pip install -r custom_nodes/ComfyUI-Impact-Subpack/requirements.txt || true

echo "=== Reinstall critical missing packages after requirements ==="
$PY -m pip install \
onnx \
gguf \
ftfy \
diffusers \
transformers \
sentencepiece \
segment-anything \
dill \
onnxruntime \
onnxruntime-gpu \
piexif \
ultralytics \
opencv-python-headless \
accelerate \
imageio-ffmpeg \
numba \
PyWavelets \
hf_xet \
|| true

echo "=== Verify Python dependencies ==="
$PY - <<'PY'
import importlib

packages = [
    "cv2",
    "onnx",
    "onnxruntime",
    "accelerate",
    "gguf",
    "ftfy",
    "diffusers",
    "transformers",
    "sentencepiece",
    "piexif",
    "ultralytics",
    "dill",
    "pywt",
]

for pkg in packages:
    try:
        importlib.import_module(pkg)
        print(f"✅ Python package OK: {pkg}")
    except Exception as e:
        print(f"⚠️ Python package issue: {pkg}: {e}")
PY

echo "=== Check ONNX providers ==="
$PY - <<'PY'
try:
    import onnxruntime as ort
    print("ONNXRuntime providers:", ort.get_available_providers())
except Exception as e:
    print("ONNXRuntime check failed:", e)
PY

echo "=== Download Anna LoRA ==="
wget -nc -O /workspace/ComfyUI/models/loras/anna.safetensors \
"https://huggingface.co/Rodney007/Anna/resolve/main/anna.safetensors" || true

require_file /workspace/ComfyUI/models/loras/anna.safetensors

echo "=== Download CLIP Vision H ==="
rm -f /workspace/ComfyUI/models/clip_vision/clip_vision_h.safetensors

wget -O /workspace/ComfyUI/models/clip_vision/clip_vision_h.safetensors \
"https://huggingface.co/stabilityai/stable-video-diffusion-img2vid-xt/resolve/main/image_encoder/model.safetensors"

require_file /workspace/ComfyUI/models/clip_vision/clip_vision_h.safetensors

echo "=== Download WAN text encoder ==="
hf download Comfy-Org/Wan_2.1_ComfyUI_repackaged \
split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors \
--local-dir /workspace/ComfyUI/models/text_encoders

move_if_exists \
/workspace/ComfyUI/models/text_encoders/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors \
/workspace/ComfyUI/models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors

require_file /workspace/ComfyUI/models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors

echo "=== Download WAN VAE ==="
hf download Comfy-Org/Wan_2.1_ComfyUI_repackaged \
split_files/vae/wan_2.1_vae.safetensors \
--local-dir /workspace/ComfyUI/models/vae

move_if_exists \
/workspace/ComfyUI/models/vae/split_files/vae/wan_2.1_vae.safetensors \
/workspace/ComfyUI/models/vae/wan_2.1_vae.safetensors

require_file /workspace/ComfyUI/models/vae/wan_2.1_vae.safetensors

echo "=== Download WAN Animate diffusion model ==="
hf download Comfy-Org/Wan_2.2_ComfyUI_Repackaged \
split_files/diffusion_models/wan2.2_animate_14B_bf16.safetensors \
--local-dir /workspace/ComfyUI/models/diffusion_models

move_if_exists \
/workspace/ComfyUI/models/diffusion_models/split_files/diffusion_models/wan2.2_animate_14B_bf16.safetensors \
/workspace/ComfyUI/models/diffusion_models/wan2.2_animate_14B_bf16.safetensors

require_file /workspace/ComfyUI/models/diffusion_models/wan2.2_animate_14B_bf16.safetensors

echo "=== Download WAN T2V low noise diffusion model ==="
hf download Comfy-Org/Wan_2.2_ComfyUI_Repackaged \
split_files/diffusion_models/wan2.2_t2v_low_noise_14B_fp16.safetensors \
--local-dir /workspace/ComfyUI/models/diffusion_models

move_if_exists \
/workspace/ComfyUI/models/diffusion_models/split_files/diffusion_models/wan2.2_t2v_low_noise_14B_fp16.safetensors \
/workspace/ComfyUI/models/diffusion_models/wan2.2_t2v_low_noise_14B_fp16.safetensors

require_file /workspace/ComfyUI/models/diffusion_models/wan2.2_t2v_low_noise_14B_fp16.safetensors

echo "=== Create UNET symlinks ==="
rm -f /workspace/ComfyUI/models/unet/wan2.2_animate_14B_bf16.safetensors
rm -f /workspace/ComfyUI/models/unet/wan2.2_t2v_low_noise_14B_fp16.safetensors

ln -s /workspace/ComfyUI/models/diffusion_models/wan2.2_animate_14B_bf16.safetensors \
/workspace/ComfyUI/models/unet/wan2.2_animate_14B_bf16.safetensors

ln -s /workspace/ComfyUI/models/diffusion_models/wan2.2_t2v_low_noise_14B_fp16.safetensors \
/workspace/ComfyUI/models/unet/wan2.2_t2v_low_noise_14B_fp16.safetensors

require_file /workspace/ComfyUI/models/unet/wan2.2_animate_14B_bf16.safetensors
require_file /workspace/ComfyUI/models/unet/wan2.2_t2v_low_noise_14B_fp16.safetensors

echo "=== Download WAN LoRAs ==="
hf download Comfy-Org/Wan_2.2_ComfyUI_Repackaged \
split_files/loras/wan2.2_animate_14B_relight_lora_bf16.safetensors \
--local-dir /workspace/ComfyUI/models/loras

move_if_exists \
/workspace/ComfyUI/models/loras/split_files/loras/wan2.2_animate_14B_relight_lora_bf16.safetensors \
/workspace/ComfyUI/models/loras/wan2.2_animate_14B_relight_lora_bf16.safetensors

require_file /workspace/ComfyUI/models/loras/wan2.2_animate_14B_relight_lora_bf16.safetensors

hf download dci05049/i2v_lightx2v_low_noise_model.safetensors \
i2v_lightx2v_low_noise_model.safetensors \
--local-dir /workspace/ComfyUI/models/loras

require_file /workspace/ComfyUI/models/loras/i2v_lightx2v_low_noise_model.safetensors

echo "=== Download WAN Animate detection models ==="
hf download Kijai/vitpose_comfy \
onnx/vitpose_h_wholebody_model.onnx \
--local-dir /workspace/ComfyUI/models/detection

hf download Kijai/vitpose_comfy \
onnx/vitpose_h_wholebody_data.bin \
--local-dir /workspace/ComfyUI/models/detection

move_if_exists \
/workspace/ComfyUI/models/detection/onnx/vitpose_h_wholebody_model.onnx \
/workspace/ComfyUI/models/detection/vitpose_h_wholebody_model.onnx

move_if_exists \
/workspace/ComfyUI/models/detection/onnx/vitpose_h_wholebody_data.bin \
/workspace/ComfyUI/models/detection/vitpose_h_wholebody_data.bin

require_file /workspace/ComfyUI/models/detection/vitpose_h_wholebody_model.onnx
require_file /workspace/ComfyUI/models/detection/vitpose_h_wholebody_data.bin

hf download Wan-AI/Wan2.2-Animate-14B \
process_checkpoint/det/yolov10m.onnx \
--local-dir /workspace/ComfyUI/models/detection

move_if_exists \
/workspace/ComfyUI/models/detection/process_checkpoint/det/yolov10m.onnx \
/workspace/ComfyUI/models/detection/yolov10m.onnx

require_file /workspace/ComfyUI/models/detection/yolov10m.onnx

echo "=== Also copy detection models to controlnet_aux ckpts ==="
mkdir -p /workspace/ComfyUI/custom_nodes/comfyui_controlnet_aux/ckpts/yzd-v/DWPose
mkdir -p /workspace/ComfyUI/custom_nodes/comfyui_controlnet_aux/ckpts/hr16/DWPose-TorchScript-BatchSize5

cp /workspace/ComfyUI/models/detection/yolov10m.onnx \
/workspace/ComfyUI/custom_nodes/comfyui_controlnet_aux/ckpts/yzd-v/DWPose/yolox_l.onnx

echo "=== Download DWPose fallback models ==="
hf download yzd-v/DWPose \
yolox_l.onnx \
--local-dir /workspace/ComfyUI/custom_nodes/comfyui_controlnet_aux/ckpts/yzd-v/DWPose || true

hf download hr16/DWPose-TorchScript-BatchSize5 \
dw-ll_ucoco_384_bs5.torchscript.pt \
--local-dir /workspace/ComfyUI/custom_nodes/comfyui_controlnet_aux/ckpts/hr16/DWPose-TorchScript-BatchSize5 || true

require_file /workspace/ComfyUI/custom_nodes/comfyui_controlnet_aux/ckpts/yzd-v/DWPose/yolox_l.onnx

echo "=== Download SAM2 model ==="
hf download facebook/sam2.1-hiera-base-plus \
sam2.1_hiera_base_plus.pt \
--local-dir /workspace/ComfyUI/models/sam2 || true

echo "=== Download upscaler ==="
wget -nc -O /workspace/ComfyUI/models/upscale_models/4x-UltraSharp.pth \
"https://huggingface.co/uwg/upscaler/resolve/main/ESRGAN/4x-UltraSharp.pth"

require_file /workspace/ComfyUI/models/upscale_models/4x-UltraSharp.pth

echo "=== Final verification of key files ==="
require_file /workspace/ComfyUI/models/clip_vision/clip_vision_h.safetensors
require_file /workspace/ComfyUI/models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors
require_file /workspace/ComfyUI/models/vae/wan_2.1_vae.safetensors
require_file /workspace/ComfyUI/models/diffusion_models/wan2.2_animate_14B_bf16.safetensors
require_file /workspace/ComfyUI/models/diffusion_models/wan2.2_t2v_low_noise_14B_fp16.safetensors
require_file /workspace/ComfyUI/models/unet/wan2.2_animate_14B_bf16.safetensors
require_file /workspace/ComfyUI/models/unet/wan2.2_t2v_low_noise_14B_fp16.safetensors
require_file /workspace/ComfyUI/models/loras/i2v_lightx2v_low_noise_model.safetensors
require_file /workspace/ComfyUI/models/loras/wan2.2_animate_14B_relight_lora_bf16.safetensors
require_file /workspace/ComfyUI/models/detection/vitpose_h_wholebody_model.onnx
require_file /workspace/ComfyUI/models/detection/vitpose_h_wholebody_data.bin
require_file /workspace/ComfyUI/models/detection/yolov10m.onnx
require_file /workspace/ComfyUI/models/upscale_models/4x-UltraSharp.pth

echo "=== List key model folders ==="
ls -lh /workspace/ComfyUI/models/clip_vision || true
ls -lh /workspace/ComfyUI/models/text_encoders || true
ls -lh /workspace/ComfyUI/models/vae || true
ls -lh /workspace/ComfyUI/models/diffusion_models || true
ls -lh /workspace/ComfyUI/models/unet || true
ls -lh /workspace/ComfyUI/models/loras || true
ls -lh /workspace/ComfyUI/models/detection || true
ls -lh /workspace/ComfyUI/models/upscale_models || true

echo "=== Rodney GodMode provisioning complete ==="

rm -f /.provisioning
