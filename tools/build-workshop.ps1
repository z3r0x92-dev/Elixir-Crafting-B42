$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceRoot = Join-Path $repoRoot "src"
$workshopAssets = Join-Path $repoRoot "workshop"
$distRoot = Join-Path $repoRoot "dist"
$packageRoot = Join-Path $distRoot "ElixirCraftB42-Workshop"
$contentRoot = Join-Path $packageRoot "Contents\mods\ElixirCraftB42"

if (Test-Path $packageRoot) {
    Remove-Item -LiteralPath $packageRoot -Recurse -Force
}

New-Item -ItemType Directory -Path $contentRoot -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $sourceRoot "42") -Destination $contentRoot -Recurse
Copy-Item -LiteralPath (Join-Path $sourceRoot "common") -Destination $contentRoot -Recurse
Copy-Item -LiteralPath (Join-Path $sourceRoot "README.txt") -Destination $contentRoot
Copy-Item -LiteralPath (Join-Path $workshopAssets "preview.png") -Destination $packageRoot
Copy-Item -LiteralPath (Join-Path $workshopAssets "workshop.txt.template") -Destination (Join-Path $packageRoot "workshop.txt")

Write-Host "Created $packageRoot"
Write-Host "Copy it to $env:USERPROFILE\Zomboid\Workshop before uploading."

