param([switch]$Init, [switch]$Verify)
$ErrorActionPreference = "Stop"
$Root = (& git rev-parse --show-toplevel) 2>$null
if (-not $Root) { $Root = (Get-Location).Path }
$T = Join-Path $Root "brief-kit/templates"
$Bin = Join-Path $Root "scripts/brief"
New-Item -ItemType Directory -Force -Path $Bin | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Root "_reference/adr"), (Join-Path $Root "_reference/diagrams") | Out-Null
function CopyIfMissing($src,$dst){
  if(-not(Test-Path $dst)){ New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null; Copy-Item $src $dst }
}

if ($Init) {
  (Get-Content (Join-Path $T "BRIEF.md.tmpl")) -replace "{{DATE}}",(Get-Date -Format "yyyy-MM-dd") |
    Set-Content (Join-Path $Root "BRIEF.md")
  CopyIfMissing (Join-Path $T "briefignore.tmpl") (Join-Path $Root ".briefignore")
  CopyIfMissing (Join-Path $T "configs/markdownlint.jsonc.tmpl") (Join-Path $Root ".markdownlint.jsonc")
  CopyIfMissing (Join-Path $T "configs/mlc_config.json.tmpl") (Join-Path $Root "mlc_config.json")
  CopyIfMissing (Join-Path $T "configs/vale.ini.tmpl") (Join-Path $Root ".vale.ini")
  CopyIfMissing (Join-Path $T "scripts/brief/check-brief.sh.tmpl") (Join-Path $Bin "check-brief.sh")

  # CI autodetect (default GitHub)
  if (Test-Path (Join-Path $Root ".gitlab-ci.yml")) {
    CopyIfMissing (Join-Path $T "ci/gitlab.yml.tmpl") (Join-Path $Root ".gitlab-ci.yml")
  } elseif (Test-Path (Join-Path $Root "azure-pipelines.yml")) {
    CopyIfMissing (Join-Path $T "ci/azure.yml.tmpl") (Join-Path $Root "azure-pipelines.yml")
  } elseif (Test-Path (Join-Path $Root "bitbucket-pipelines.yml")) {
    CopyIfMissing (Join-Path $T "ci/bitbucket.yml.tmpl") (Join-Path $Root "bitbucket-pipelines.yml")
  } else {
    New-Item -ItemType Directory -Force -Path (Join-Path $Root ".github/workflows") | Out-Null
    CopyIfMissing (Join-Path $T "ci/github.yml.tmpl") (Join-Path $Root ".github/workflows/brief-ci.yml")
  }

  Write-Host "Seeded. Run: bash scripts/brief/check-brief.sh"
} elseif ($Verify) {
  bash (Join-Path $Bin "check-brief.sh")
} else {
  Write-Host "Use -Init or -Verify"
}
