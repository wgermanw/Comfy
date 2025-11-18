# Flux LoRA test checklist

## Installed runtime
- Python env: `.venv` (3.12.9).
- PyTorch nightly: `torch==2.7.0.dev20250310+cu124`, `torchvision==0.22.0.dev20250226+cu124` (installed without dependency pins to support RTX 5060 Ti).
- `torchaudio` nightly does not publish Windows wheels for Python 3.12/ CUDA 12.4 yet, so it is intentionally omitted. Install the CPU build later if you need only the API surface.

## Base model downloads (run once after logging into Hugging Face)
```powershell
# Authenticate first (required because FLUX.1-dev is gated)
huggingface-cli login

# Flux diffusion weights (~9-26 GB depending on variant)
huggingface-cli download black-forest-labs/FLUX.1-dev flux1-dev.safetensors `
  --local-dir models/diffusion_models --local-dir-use-symlinks False

# Text encoders (clip-l + t5xxl)
huggingface-cli download comfyanonymous/flux_text_encoders clip_l.safetensors `
  --local-dir models/text_encoders --local-dir-use-symlinks False
huggingface-cli download comfyanonymous/flux_text_encoders t5xxl_fp16.safetensors `
  --local-dir models/text_encoders --local-dir-use-symlinks False

# Flux VAE
huggingface-cli download Comfy-Org/Lumina_Image_2.0_Repackaged split_files/vae/ae.safetensors `
  --local-dir models/vae --local-dir-use-symlinks False
```
The commands above keep everything under `ComfyUI/models/**` which is what the workflow expects. Replace the repo IDs if you prefer an fp8/fp16 variant or a different VAE.

## Custom LoRA placement
Your trained adapters already live in `models/loras/`:
- `flux_mikassa_transformer.safetensors`
- `flux_mikassa_text_encoder.safetensors`

## Ready-made workflow
A starter workflow is stored at `user/workflows/flux_mikassa_lora.json`. It loads:
1. Base Flux UNet.
2. DualCLIP text encoders.
3. LoRA #1 (`flux_mikassa_transformer`) on the model path (clip strength defaults to 0).
4. LoRA #2 (`flux_mikassa_text_encoder`) on the text encoder path (model strength defaults to 0).

Load it from the ComfyUI interface via **Workflow > Load**; prompt + resolution widgets are already wired up. Swap LoRA strengths or files straight from the two `LoraLoader` nodes.

## Running ComfyUI
```powershell
cd D:\Mikassa_LoRA\ComfyUI
.\.venv\Scripts\python.exe main.py --listen 0.0.0.0 --port 8188
```
Then open http://127.0.0.1:8188/ in a browser, load the workflow, and queue a job. Enable **SDPA-only** in settings if you need to reduce VRAM.

## First test reminder
1. Download the base models (see above).
2. Launch ComfyUI.
3. Load `flux_mikassa_lora` workflow.
4. Enter a short prompt and optionally tweak Lora strengths.
5. Hit **Queue Prompt**.
6. Review renders under `ComfyUI/output/`.

If you see missing model errors, confirm their filenames precisely match what the nodes expect or adjust the widget dropdowns inside the workflow.
