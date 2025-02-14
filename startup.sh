#!/bin/bash

set -euo pipefail  # Exit on error, show commands, handle pipes safely

echo "🔧 Starting HVGP container startup script..."

# Set up arguments
#HVGP_PROFILE=${HVGP_PROFILE:-1}
#HVGP_CUDA_IDX=${HVGP_CUDA_IDX:-0}
#HVGP_ENABLE_ICL=${HVGP_ENABLE_ICL:-0}
#HVGP_TRANSFORMER_PATCH=${HVGP_TRANSFORMER_PATCH:-0}
HVGP_AUTO_UPDATE=${HVGP_AUTO_UPDATE:-0}
#HVGP_SERVER_USER=${HVGP_SERVER_USER:-""}
#HVGP_SERVER_PASSWORD=${HVGP_SERVER_PASSWORD:-""}

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
    echo "📥 Unnpacking HVGP repository..."
    mkdir -p "$HVGP_HOME"
    tar -xzvf HVGP.tar.gz --strip-components=1 -C "$HVGP_HOME"
fi
if [[ "$HVGP_AUTO_UPDATE" == "1" ]]; then
    echo "🔄 Updating the HVGP repository..."
    git -C "$HVGP_HOME" reset --hard
    git -C "$HVGP_HOME" pull
fi
ln -sfn ${CKPTS_HOME} "$HVGP_HOME/ckpts"
ln -sfn ${LORA_HOME} "$HVGP_HOME/lora"

# Install dependencies
#CONDA_HOME="${CACHE_HOME}/conda"
#echo "📦 Installing dependencies..."
#if [ ! -d "$CONDA_HOME" ]; then
#    conda env create --file "$HVGP_HOME/environment.yml" --prefix $CONDA_HOME
#fi
VENV_HOME="${CACHE_HOME}/venv"
echo "📦 Installing dependencies..."
if [ ! -d "$VENV_HOME" ]; then
    python3 -m venv "$VENV_HOME"
fi

#source /opt/conda/etc/profile.d/conda.sh
#conda activate $CONDA_HOME
#conda info --envs
#if ! conda info --envs | grep -q "$CONDA_HOME"; then
#    echo "Error: Conda environment activation failed."
#    exit 1
#fi
source "${VENV_HOME}/bin/activate"
pip install --no-cache-dir -r "$HVGP_HOME/requirements.txt"
pip install --no-cache-dir wheel
pip install --no-cache-dir \
    flash-attn==2.7.2.post1 \
    sageattention==1.0.6 \
    xformers==0.0.29
pip install "huggingface_hub[cli]"

# Download the model: https://github.com/Tencent/HunyuanVideo/tree/main/ckpts
# They are saved at HF_HOME/tencent/HunyuanVideo
huggingface-cli download tencent/HunyuanVideo --local-dir $CKPTS_HOME

# Build command line argds and start the service
HVGP_ARGS=" \
    --save-path ${OUTPUT_HOME} \
    --server-name 0.0.0.0 \
    --server-port 7860"

# Ensuring that all output is flushed to the console, and that stderr is redirected to stdout and log
echo "🚀 Starting HVGP service..."
cd "$HVGP_HOME" || exit 1
python3 -u gradio_server.py ${HVGP_ARGS} 2>&1 | tee "${CACHE_HOME}/output.log"
echo "❌ The HVGP service has terminated."s
