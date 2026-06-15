# Salin template env jika belum ada (Windows)
$root = Split-Path -Parent $PSScriptRoot
$example = Join-Path $root "env.example.json"
$target = Join-Path $root "env.json"

if (Test-Path $target) {
  Write-Host "env.json sudah ada — tidak diubah."
  exit 0
}

Copy-Item $example $target
Write-Host "env.json dibuat dari env.example.json"
Write-Host "Edit env.json dan isi GEMINI_API_KEY dari Google AI Studio."
Write-Host "https://aistudio.google.com/apikey"
