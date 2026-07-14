# SensNova-U1 Serverless Worker for RunPod
# Based on runpod/worker-comfyui with SenseNova-U1 custom nodes added
#
# Build: RunPod GitHub Integration (automatic) or:
#   docker build -t sensenova-serverless .
#   docker push <your-registry>/sensenova-serverless

FROM runpod/worker-comfyui:5.8.6-base-cuda12.8.1

# ---------------------------------------------------------------------------
# Install SenseNova-U1: clone repo, install package, install ComfyUI nodes
# ---------------------------------------------------------------------------

# Clone the SenseNova-U1 monorepo
RUN cd / && git clone --depth 1 https://github.com/OpenSenseNova/SenseNova-U1.git

# Install the sensenova-u1 Python package (from source, no-deps to avoid
# pulling in evaluation/benchmarking subrepos)
RUN pip install -e /SenseNova-U1 --no-deps

# Install ComfyUI-SenseNova-U1 dependencies
RUN pip install httpx numpy pillow python-dotenv

# Install the sensenova-u1 runtime package from the GitHub tarball
# (avoids git submodule update pulling hundreds of MB of benchmark code)
RUN pip install "sensenova-u1 @ https://github.com/OpenSenseNova/SenseNova-U1/archive/refs/heads/main.tar.gz"

# Install ComfyUI-SenseNova-U1 custom nodes via the official install script
# Using --copy mode since symlinks don't survive in Docker layers reliably
RUN python /SenseNova-U1/apps/comfyui/install.py --comfyui /comfyui --copy --force

# Install any additional requirements from the ComfyUI app
RUN pip install -r /SenseNova-U1/apps/comfyui/requirements.txt 2>/dev/null || true

# ---------------------------------------------------------------------------
# Environment variables
# ---------------------------------------------------------------------------

ENV SENSENOVA_U1_SRC=/SenseNova-U1/src
ENV HF_HOME=/runpod-volume/huggingface-cache
ENV HF_HUB_CACHE=/runpod-volume/huggingface-cache/hub
ENV TRANSFORMERS_CACHE=/runpod-volume/huggingface-cache/hub

# Increase ComfyUI startup timeout for large model loading (35GB)
ENV COMFY_API_AVAILABLE_MAX_RETRIES=0
ENV COMFY_API_AVAILABLE_INTERVAL_MS=50

# ---------------------------------------------------------------------------
# The handler.py, start.sh, extra_model_paths.yaml, and network_volume.py
# are already in the base image. We just need to ensure they're present.
# ---------------------------------------------------------------------------

# Ensure extra_model_paths.yaml is in place (for network volume model discovery)
COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml

# Ensure handler and scripts are in place (override base image versions)
COPY handler.py /handler.py
COPY start.sh /start.sh
COPY network_volume.py /network_volume.py
RUN chmod +x /start.sh

WORKDIR /

CMD ["/start.sh"]