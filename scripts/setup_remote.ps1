<#
.SYNOPSIS
    Bootstraps a fresh ComfyUI checkout and drops the Mikassa LoRA assets in place.

.DESCRIPTION
    - clones ComfyUI (or uses the existing folder)
    - creates a local virtual environment
    - installs ComfyUI python requirements
    - copies the LoRA weights + workflow from this repo into the new checkout

    Base model downloads (Flux UNet, text encoders, VAE) are not automated here because
    they require an authenticated Hugging Face session. See README for the commands.
#>

[CmdletBinding()]
param(
    [string]$ComfyRepo = "https://github.com/comfyanonymous/ComfyUI.git",
    [string]$InstallDir = "$PSScriptRoot\..\ComfyUI",
    [string]$PythonCmd = "python"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Path $PSScriptRoot -Parent
$installPath = Resolve-Path -Path $InstallDir -ErrorAction SilentlyContinue
if (-not $installPath) {
    Write-Host "Cloning ComfyUI into $InstallDir"
    git clone $ComfyRepo $InstallDir
    $installPath = Resolve-Path -Path $InstallDir
}
else {
    Write-Host "Using existing ComfyUI folder at $installPath"
}

Push-Location $installPath
try {
    if (-not (Test-Path ".venv")) {
        Write-Host "Creating python virtualenv (.venv)"
        & $PythonCmd -m venv .venv
    }

    $venvPython = Join-Path $installPath ".venv\Scripts\python.exe"
    if (-not (Test-Path $venvPython)) {
        throw "Virtualenv python executable not found at $venvPython"
    }

    Write-Host "Upgrading pip"
    & $venvPython -m pip install --upgrade pip

    Write-Host "Installing ComfyUI requirements"
    & $venvPython -m pip install -r requirements.txt

    $destLora = Join-Path $installPath "models\loras"
    $destWorkflows = Join-Path $installPath "user\workflows"
    New-Item -ItemType Directory -Force -Path $destLora | Out-Null
    New-Item -ItemType Directory -Force -Path $destWorkflows | Out-Null

    $sourceLora = Join-Path $repoRoot "loras"
    Write-Host "Copying LoRA weights from $sourceLora"
    Get-ChildItem $sourceLora -Filter "*.safetensors" | ForEach-Object {
        Copy-Item $_.FullName -Destination $destLora -Force
    }

    $sourceWorkflows = Join-Path $repoRoot "workflows"
    Write-Host "Copying workflows from $sourceWorkflows"
    Get-ChildItem $sourceWorkflows -Filter "*.json" | ForEach-Object {
        Copy-Item $_.FullName -Destination $destWorkflows -Force
    }

    Write-Host "`nAll set!"
    Write-Host "Next steps:"
    Write-Host "  1) Download Flux base models + text encoders + VAE (see README)."
    Write-Host "  2) Launch ComfyUI: .\.venv\Scripts\python.exe main.py --listen 0.0.0.0 --port 8188"
    Write-Host "  3) Load workflow 'flux_mikassa_lora' in the UI and start generating."
}
finally {
    Pop-Location
}
