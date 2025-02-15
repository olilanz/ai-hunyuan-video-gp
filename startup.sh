#!/bin/bash

set -euo pipefail  # Exit on error, show commands, handle pipes safely

echo "🔧 Starting HVGP container startup script..."

# Set up environment variables
HVGP_AUTO_UPDATE=${HVGP_AUTO_UPDATE:-0}

CACHE_HOME="/workspace/cache"
export HF_HOME="${CACHE_HOME}/huggingface"
export TORCH_HOME="${CACHE_HOME}/torch"
CKPTS_HOME="${CACHE_HOME}/ckpts"
LORA_HOME="${CACHE_HOME}/lora"
OUTPUT_HOME="/workspace/output"

echo "📂 Setting up cache directories..."
mkdir -p "${CACHE_HOME}" "${HF_HOME}" "${TORCH_HOME}" "${CKPTS_HOME}" "${LORA_HOME}" "${OUTPUT_HOME}"

# Clone or update HVGP
HVGP_HOME="${CACHE_HOME}/HVGP"
if [ ! -d "$HVGP_HOME" ]; then
    echo "📥 Unpacking HVGP repository..."
    mkdir -p "$HVGP_HOME"
    tar -xzvf HVGP.tar.gz --strip-components=1 -C "$HVGP_HOME"
fi
if [[ "$HVGP_AUTO_UPDATE" == "1" ]]; then
    echo "🔄 Updating the HVGP repository..."
    git -C "$HVGP_HOME" reset --hard
    git -C "$HVGP_HOME" pull
fi

# Ensure symlinks for models & output
ln -sfn "${CKPTS_HOME}" "$HVGP_HOME/ckpts"
ln -sfn "${LORA_HOME}" "$HVGP_HOME/lora"
ln -sfn "${OUTPUT_HOME}" "$HVGP_HOME/gradio_outputs"

# Virtual environment setup
VENV_HOME="${CACHE_HOME}/venv"
echo "📦 Setting up Python virtual environment..."
if [ ! -d "$VENV_HOME" ]; then
    python3 -m venv "$VENV_HOME"
fi
source "${VENV_HOME}/bin/activate"

# Ensure latest pip version
pip install --no-cache-dir --upgrade pip wheel

# Install required dependencies
echo "📦 Installing Python dependencies..."
pip install --no-cache-dir -r "$HVGP_HOME/requirements.txt"
pip install --no-cache-dir \
    flash-attn==2.7.2.post1 \
    sageattention==1.0.6 \
    xformers==0.0.29 \
    "huggingface_hub[cli]"

# Download model only if not already present
if [ ! -d "${CKPTS_HOME}/hunyuan-video-t2v-720p" ]; then
    echo "📥 Downloading HunyuanVideo model..."
    huggingface-cli download tencent/HunyuanVideo --local-dir "$CKPTS_HOME"
else
    echo "✅ Model already exists in ${CKPTS_HOME}, skipping download."
fi

# Start the service
HVGP_ARGS="--server-name 0.0.0.0 --server-port 7860"

echo "🚀 Starting HVGP service..."
python3 -u gradio_server.py ${HVGP_ARGS} 2>&1 | tee "${CACHE_HOME}/output.log"
echo "❌ The HVGP service has terminated."
