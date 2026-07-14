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

# Clone the SenseNova-U1 monorepo (shallow clone to save space)
RUN cd / && git clone --depth 1 https://github.com/OpenSenseNova/SenseNova-U1.git

# Install the sensenova-u1 Python package with --no-deps
# The base image already has torch, transformers, safetensors, etc.
# Using --no-deps avoids reinstalling/downgrading existing packages
# and prevents disk space issues from rolling back large packages.
RUN pip install -e /SenseNova-U1 --no-deps

# Install only the additional deps that SenseNova needs but the base image lacks
# (httpx, numpy, pillow, python-dotenv are already in the base image)
RUN pip install --no-deps httpx python-dotenv || true

# Install ComfyUI-SenseNova-U1 custom nodes via the official install script
# Using --copy mode since symlinks don't survive reliably in Docker layers
RUN python /SenseNova-U1/apps/comfyui/install.py --comfyui /comfyui --copy --force

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
# are already in the base image. We override with our copies to be safe.
# ---------------------------------------------------------------------------

COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml
COPY handler.py /handler.py
COPY start.sh /start.sh
COPY network_volume.py /network_volume.py
RUN chmod +x /start.sh

WORKDIR /

CMD ["/start.sh"]