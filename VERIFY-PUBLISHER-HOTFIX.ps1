param()

$ErrorActionPreference = "Stop"
Set-ExecutionPolicy -Scope Process Bypass -Force

$Root = $PSScriptRoot

$Publisher = [System.IO.File]::ReadAllText(
    (Join-Path $Root "PUBLISH-GITHUB-RELEASE.ps1")
)
$OneClick = [System.IO.File]::ReadAllText(
    (Join-Path $Root "ONECLICK-PUBLISH.ps1")
)
$BuildRemote = [System.IO.File]::ReadAllText(
    (Join-Path $Root "BUILD-REMOTE-MPP.ps1")
)

$Failed = $false

function Check([string]$Name, [bool]$Passed) {
    if ($Passed) {
        Write-Host "[PASS] $Name" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] $Name" -ForegroundColor Red
        $script:Failed = $true
    }
}

Write-Host ""
Write-Host "Publisher hotfix v1.0.2 verifier" -ForegroundColor Cyan
Write-Host ""

Check "Run() no longer uses automatic `$Args variable" (
    $Publisher.Contains('function Run([string]$Exe, [string[]]$CommandArgs)')
)

Check "Run() splats CommandArgs" (
    $Publisher.Contains('& $Exe @CommandArgs')
)

Check "publisher configures Git auth via gh" (
    $Publisher.Contains('gh auth setup-git')
)

Check "existing empty repo retry path present" (
    $Publisher.Contains('git ls-remote --heads')
)

Check "existing non-empty repo remains protected" (
    $Publisher.Contains('history-preserving publisher')
)

Check "null-safe Git output helper present" (
    $Publisher.Contains('function Get-GitText')
)

Check "empty git tag lookup is null-safe" (
    $Publisher.Contains('$ExistingTag = Get-GitText')
)

Check "git identity lookup is null-safe" (
    $Publisher.Contains('$Name = Get-GitText') -and
    $Publisher.Contains('$Email = Get-GitText')
)

Check "ONECLICK no longer stores params in `$Args" (
    -not $OneClick.Contains('$Args = @{') -and
    $OneClick.Contains('$PublishParams = @{')
)

Check "BUILD-REMOTE no longer stores params in `$Args" (
    -not $BuildRemote.Contains('$Args = @()') -and
    $BuildRemote.Contains('$BuildInvokeArgs = @()')
)

if ($Failed) {
    throw "HOTFIX VERIFICATION FAILED."
}

Write-Host ""
Write-Host "PUBLISHER HOTFIX VERIFICATION PASSED." -ForegroundColor Green
