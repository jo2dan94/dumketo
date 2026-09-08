param(
    [switch]$RefreshDependencies
)

$ErrorActionPreference = "Stop"
Set-ExecutionPolicy -Scope Process Bypass -Force

$Root = $PSScriptRoot

$BuildInvokeArgs = @()
if ($RefreshDependencies) {
    $BuildInvokeArgs += "-RefreshDependencies"
}

& (Join-Path $Root "BUILD-MULTIAPP-PORTED.ps1") @BuildInvokeArgs
if (-not $?) {
    throw "Multi-App build failed."
}

$VersionMatch = Select-String `
    -Path (Join-Path $Root "gradle.properties") `
    -Pattern '^\s*version\s*=\s*(.+?)\s*$'

$Version = $VersionMatch.Matches[0].Groups[1].Value.Trim()
$Mpp = Join-Path $Root "dist\patches-$Version.mpp"

if (-not (Test-Path $Mpp)) {
    throw "Expected remote release artifact was not produced: $Mpp"
}

Write-Host ""
Write-Host "[PASS] Remote release artifact created:" -ForegroundColor Green
Write-Host "  $Mpp" -ForegroundColor Cyan
