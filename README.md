# Mikassa Flux LoRA Deployment Kit

This repository keeps everything that is **not** already hosted upstream:

- the trained Flux LoRA weights (`loras/*.safetensors`)
- the ComfyUI workflow wired for those adapters (`workflows/flux_mikassa_lora.json`)
- a helper script that spins up a fresh ComfyUI checkout and copies the assets in place (`scripts/setup_remote.ps1`)
- notes about the runtime combo that was tested (`FLUX_LORA_NOTES.md`)

Clone/push this repo to any Windows box, run the setup script, download the base models, and you are ready to queue prompts.

## Quick start on a rented GPU box

```powershell
# 1. Clone your repo somewhere on the VM
git clone <your-git-url> Mikassa_LoRA
cd Mikassa_LoRA

# 2. Provision ComfyUI + virtualenv + copy LoRAs/workflows
pwsh .\scripts\setup_remote.ps1

# 3. Authenticate with Hugging Face (required for Flux weights)
huggingface-cli login

# 4. Download the base models into ComfyUI/models/**
pwsh -Command "& {`
  huggingface-cli download black-forest-labs/FLUX.1-dev flux1-dev.safetensors `
    --local-dir ComfyUI/models/diffusion_models --local-dir-use-symlinks False;`
  huggingface-cli download comfyanonymous/flux_text_encoders clip_l.safetensors `
    --local-dir ComfyUI/models/text_encoders --local-dir-use-symlinks False;`
  huggingface-cli download comfyanonymous/flux_text_encoders t5xxl_fp16.safetensors `
    --local-dir ComfyUI/models/text_encoders --local-dir-use-symlinks False;`
  huggingface-cli download Comfy-Org/Lumina_Image_2.0_Repackaged split_files/vae/ae.safetensors `
    --local-dir ComfyUI/models/vae --local-dir-use-symlinks False`
}"

# 5. Launch ComfyUI
cd ComfyUI
.\.venv\Scripts\python.exe .\main.py --listen 0.0.0.0 --port 8188
```

Open http://localhost:8188/, go to **Workflow → Load**, pick `flux_mikassa_lora`, tweak the prompt and LoRA strength sliders, then queue your job.

## Repository layout

- `loras/` – transformer + text-encoder adapters exported from the local run.
- `workflows/flux_mikassa_lora.json` – ready-made ComfyUI graph referencing the stock Flux downloads plus the two adapters above.
- `scripts/setup_remote.ps1` – reproducible environment bootstrapper.
- `FLUX_LORA_NOTES.md` – extra context / manual install instructions.
- `training_manifest.json` – training metadata snapshot (handy if you retrain or share provenance).

Anything under `ComfyUI/` or `checkpoint-final/` is local state and intentionally ignored—new hosts should re-run the setup script to get a clean copy instead of syncing the entire working tree.

## Troubleshooting checklist

1. **Missing model/Lora errors** – make sure the filenames inside `ComfyUI/models/**` exactly match the ones referenced by the loader nodes (edit the widgets if you rename files).
2. **Flux weights are gated** – you must be logged into the Hugging Face CLI *and* have been granted access to `black-forest-labs/FLUX.1-dev`.
3. **CUDA kernel mismatch** – install a PyTorch build that supports your GPU’s compute capability. Nightly cu126 builds already contain wider arch lists (see `FLUX_LORA_NOTES.md`).
4. **Workflow changes** – update the JSON under `workflows/` and re-run the setup script to push the new graph to the remote Comfy instance.

Happy rendering!
