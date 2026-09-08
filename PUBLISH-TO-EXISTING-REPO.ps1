param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$')]
    [string]$Repo,

    [string]$WorkingDirectory = "$env:USERPROFILE\Downloads\Multi-App-Patches-Remote-Publish"
)

$ErrorActionPreference = "Stop"
Set-ExecutionPolicy -Scope Process Bypass -Force

$Source = $PSScriptRoot
$Target = [System.IO.Path]::GetFullPath($WorkingDirectory)

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git was not found in PATH."
}
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "GitHub CLI (gh) was not found. Install it, then run: gh auth login"
}

& gh auth status
if ($LASTEXITCODE -ne 0) {
    throw "GitHub CLI is not authenticated. Run: gh auth login"
}

& gh repo view $Repo *> $null
if ($LASTEXITCODE -ne 0) {
    throw "GitHub repository does not exist or is not accessible: $Repo"
}

if (Test-Path $Target) {
    throw "WorkingDirectory already exists: $Target`nChoose another -WorkingDirectory or remove the old staging clone."
}

Write-Host "Cloning existing fork/repository..." -ForegroundColor Cyan
& git clone "https://github.com/$Repo.git" $Target
if ($LASTEXITCODE -ne 0) {
    throw "git clone failed."
}

Write-Host "Overlaying the ported remote-source package..." -ForegroundColor Cyan

$RoboArgs = @(
    $Source,
    $Target,
    "/E",
    "/COPY:DAT",
    "/DCOPY:DAT",
    "/R:1",
    "/W:1",
    "/NFL",
    "/NDL",
    "/NP",
    "/NJH",
    "/NJS",
    "/XD", ".git",
    "/XD", ".deps",
    "/XD", ".tools",
    "/XD", "dist",
    "/XD", ".gradle",
    "/XD", "patches\build"
)

& robocopy @RoboArgs | Out-Null
$RoboCode = $LASTEXITCODE
if ($RoboCode -gt 7) {
    throw "robocopy failed with exit code $RoboCode"
}

Write-Host "[PASS] Package overlaid onto cloned repository" -ForegroundColor Green
Write-Host "Publishing from:" -ForegroundColor Cyan
Write-Host "  $Target"

& (Join-Path $Target "PUBLISH-GITHUB-RELEASE.ps1") -Repo $Repo
if (-not $?) {
    throw "Publishing from the existing repository clone failed."
}
