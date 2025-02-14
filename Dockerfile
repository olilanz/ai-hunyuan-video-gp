# Use the development container, which includes necessary CUDA libraries and the CUDA Compiler.
FROM nvidia/cuda:12.4.1-devel-ubuntu22.04

# Set system variables
ENV DEBIAN_FRONTEND=noninteractive
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

ENV CUDA_HOME=/usr/local/cuda
ENV PATH="$CUDA_HOME/bin:$PATH"
ENV LD_LIBRARY_PATH="$CUDA_HOME/lib64:$LD_LIBRARY_PATH"

# Ensure Python outputs everything that's printed inside the application
# (solvws the issue of not seeing the output of the application in the container)
ENV PYTHONUNBUFFERED=1

# Dynamic memory allocation for PyTorch in order to reduce memory fragmentation.
# (reduces risk of OOM eerors in low VRAM scenarios)
ENV PYTORCH_CUDA_ALLOC_CONF="expandable_segments:True"

# Install system dependencies in a single step to reduce layer size
RUN apt update && apt install -y \
    git \
    python3.10 python3-pip python3.10-venv && \
    python3 -m pip install --upgrade pip && \
    rm -rf /var/lib/apt/lists/*

# Install Miniconda
#RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
#    bash /tmp/miniconda.sh -b -p /opt/conda && \
#    rm /tmp/miniconda.sh && \
#    /opt/conda/bin/conda init && \
#    /opt/conda/bin/conda update -y conda && \
#    ln -s /opt/conda/bin/conda /usr/local/bin/conda && \
#    ln -s /opt/conda/bin/activate /usr/local/bin/activate

# Package the startup script and the latest version of the HVGP repositories
WORKDIR /app

RUN git clone --single-branch --depth=1 https://github.com/deepbeepmeep/HunyuanVideoGP.git HVGP && \
    tar -czf HVGP.tar.gz HVGP && \
    rm -rf HVGP

COPY startup.sh startup.sh

# Expose the required port (make sure it's used in the startup script)
EXPOSE 7860

# Parameters for the startup script
#ENV HVGP_PROFILE=1
#ENV HVGP_CUDA_IDX=0
#ENV HVGP_ENABLE_ICL=0
#ENV HVGP_TRANSFORMER_PATCH=0
ENV HVGP_AUTO_UPDATE=0
#ENV HVGP_SERVER_USER=""
#ENV HVGP_SERVER_PASSWORD=""

# Default command to run the container
CMD ["bash", "./startup.sh"]
