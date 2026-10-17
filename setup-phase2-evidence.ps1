$ErrorActionPreference = "Stop"

$phase2 = Join-Path (Get-Location) "Phase 2"
if (-not (Test-Path $phase2)) {
    throw "Run this script from the IOTBTECH_Final_Project repository root. Phase 2 was not found."
}

$evidence = Join-Path $phase2 "evidence"
$folders = @(
    "01-backend-build",
    "02-frontend-build",
    "03-local-runtime",
    "04-swagger",
    "05-login",
    "06-ecr-backend",
    "07-ecr-frontend"
)

New-Item -ItemType Directory -Force -Path $evidence | Out-Null
foreach ($folder in $folders) {
    $path = Join-Path $evidence $folder
    New-Item -ItemType Directory -Force -Path $path | Out-Null
    New-Item -ItemType File -Force -Path (Join-Path $path ".gitkeep") | Out-Null
}

Write-Host "Created Phase 2 evidence structure:"
Get-ChildItem $evidence -Directory | Select-Object -ExpandProperty Name
