# SensNova-U1 Serverless Endpoint for RunPod

Custom RunPod serverless worker based on `runpod/worker-comfyui` with SenseNova-U1 support for AI infographic generation.

## What This Does

Wraps the [SenseNova-U1-8B-MoT-Infographic-V2](https://huggingface.co/sensenova/SenseNova-U1-8B-MoT-Infographic-V2) model in a ComfyUI serverless endpoint. Submit ComfyUI workflows with SenseNova custom nodes (`SenseNovaU1LocalLoader`, `SenseNovaU1LocalTextToImage`) via the RunPod serverless API.

## Model

- **Model**: `sensenova/SenseNova-U1-8B-MoT-Infographic-V2` (8B MoT, ~35GB)
- **Architecture**: NEO-unify (no VAE, no Visual Encoder)
- **Task**: High-density infographic generation with text rendering
- **License**: Apache 2.0

## Requirements

- Network volume (100GB+) with HuggingFace cache for model weights
- GPU: 24GB+ VRAM (A40, A5000, A6000, L4 recommended)
- Env vars: `HF_HOME`, `HF_HUB_CACHE`, `SENSENOVA_U1_SRC`

## Usage

```bash
curl -X POST "https://api.runpod.ai/v2/<ENDPOINT_ID>/runsync" \
  -H "Authorization: Bearer $RUNPOD_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "input": {
      "workflow": {
        "1": {
          "class_type": "SenseNovaU1LocalLoader",
          "inputs": {
            "model_path": "sensenova/SenseNova-U1-8B-MoT-Infographic-V2",
            "device": "cuda",
            "dtype": "bfloat16"
          }
        },
        "2": {
          "class_type": "SenseNovaU1LocalTextToImage",
          "inputs": {
            "u1_model": ["1", 0],
            "prompt": "Generate an infographic about...",
            "resolution": "2720x1536|16:9",
            "num_steps": 50,
            "cfg_scale": 4.0,
            "timestep_shift": 3.0
          }
        },
        "3": {
          "class_type": "SaveImage",
          "inputs": {
            "images": ["2", 0],
            "filename_prefix": "infographic"
          }
        }
      }
    }
  }'
```