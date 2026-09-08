param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$')]
    [string]$Repo
)

$ErrorActionPreference = "Stop"
Set-ExecutionPolicy -Scope Process Bypass -Force

$Root = $PSScriptRoot
$VersionMatch = Select-String `
    -Path (Join-Path $Root "gradle.properties") `
    -Pattern '^\s*version\s*=\s*(.+?)\s*$'

if (-not $VersionMatch) {
    throw "Could not determine project version from gradle.properties."
}

$Version = $VersionMatch.Matches[0].Groups[1].Value.Trim()
$CreatedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

$ExistingBundlePath = Join-Path $Root "patches-bundle.json"
if (Test-Path $ExistingBundlePath) {
    try {
        $ExistingBundle = Get-Content $ExistingBundlePath -Raw | ConvertFrom-Json
        $ExpectedPrefix = "https://github.com/$Repo/releases/download/v$Version/"
        if (
            $ExistingBundle.version -eq $Version -and
            $ExistingBundle.download_url -like "$ExpectedPrefix*" -and
            $ExistingBundle.created_at
        ) {
            $CreatedAt = [string]$ExistingBundle.created_at
        }
    } catch {
        # Invalid/old metadata is safely replaced from the template below.
    }
}

$TemplatePath = Join-Path $Root "patches-bundle.template.json"
$BundlePath = Join-Path $Root "patches-bundle.json"
$BuildPath = Join-Path $Root "patches\build.gradle.kts"

$Template = [System.IO.File]::ReadAllText($TemplatePath)
$Bundle = $Template.
    Replace("__VERSION__", $Version).
    Replace("__CREATED_AT__", $CreatedAt).
    Replace("__REPO__", $Repo)

[System.IO.File]::WriteAllText(
    $BundlePath,
    $Bundle,
    [System.Text.UTF8Encoding]::new($false)
)

$Build = [System.IO.File]::ReadAllText($BuildPath)

$Build = [regex]::Replace(
    $Build,
    'source\s*=\s*"https://github\.com/[^"]+"',
    'source = "https://github.com/' + $Repo + '"'
)

$Build = [regex]::Replace(
    $Build,
    'website\s*=\s*"https://github\.com/[^"]+"',
    'website = "https://github.com/' + $Repo + '"'
)

[System.IO.File]::WriteAllText(
    $BuildPath,
    $Build,
    [System.Text.UTF8Encoding]::new($false)
)

Write-Host ""
Write-Host "[PASS] GitHub remote metadata configured" -ForegroundColor Green
Write-Host "Repository:    $Repo"
Write-Host "Version:       $Version"
Write-Host "Tag:           v$Version"
Write-Host "Release asset: patches-$Version.mpp"
Write-Host ""
Write-Host "Morphe source URL after publishing:" -ForegroundColor Cyan
Write-Host "  https://github.com/$Repo"
