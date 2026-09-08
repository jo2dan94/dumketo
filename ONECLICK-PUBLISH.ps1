param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$')]
    [string]$Repo,

    [switch]$CreateRepo,

    [switch]$PrivateRepo
)

$ErrorActionPreference = "Stop"
Set-ExecutionPolicy -Scope Process Bypass -Force

$PublishParams = @{
    Repo = $Repo
}

if ($CreateRepo) {
    $PublishParams.CreateRepo = $true
}

if ($PrivateRepo) {
    $PublishParams.PrivateRepo = $true
}

& (Join-Path $PSScriptRoot "PUBLISH-GITHUB-RELEASE.ps1") @PublishParams
if (-not $?) {
    throw "One-click publish failed."
}
