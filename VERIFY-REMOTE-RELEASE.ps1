param(
    [string]$Mpp = ""
)

$ErrorActionPreference = "Stop"
Set-ExecutionPolicy -Scope Process Bypass -Force

$Root = $PSScriptRoot
$VersionMatch = Select-String `
    -Path (Join-Path $Root "gradle.properties") `
    -Pattern '^\s*version\s*=\s*(.+?)\s*$'

if (-not $VersionMatch) {
    throw "Could not determine project version."
}

$Version = $VersionMatch.Matches[0].Groups[1].Value.Trim()

if (-not $Mpp) {
    $Mpp = Join-Path $Root "dist\patches-$Version.mpp"
}

if (-not (Test-Path $Mpp)) {
    throw "MPP not found: $Mpp"
}

$MetadataPath = Join-Path $Root "patches-bundle.json"
$Metadata = Get-Content $MetadataPath -Raw | ConvertFrom-Json

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
Write-Host "GitHub remote release verifier" -ForegroundColor Cyan
Write-Host ""

Check "metadata version = $Version" ($Metadata.version -eq $Version)
Check "download URL targets tag v$Version" (
    $Metadata.download_url -like "*/releases/download/v$Version/*"
)
Check "download URL targets patches-$Version.mpp" (
    $Metadata.download_url.EndsWith("/patches-$Version.mpp")
)
Check "OWNER/REPO placeholder removed" (
    -not $Metadata.download_url.Contains("OWNER/REPO")
)

Add-Type -AssemblyName System.IO.Compression.FileSystem

$Archive = [System.IO.Compression.ZipFile]::OpenRead($Mpp)
try {
    $Dex = @(
        $Archive.Entries |
            Where-Object {
                $_.FullName -match '^classes(\d*)?\.dex$' -and $_.Length -gt 0
            }
    )

    Check "non-empty classes.dex present" ($Dex.Count -gt 0)

    $ManifestEntry = $Archive.GetEntry("META-INF/MANIFEST.MF")
    Check "META-INF/MANIFEST.MF present" ($null -ne $ManifestEntry)

    if ($ManifestEntry) {
        $Reader = New-Object System.IO.StreamReader($ManifestEntry.Open())
        try {
            $Manifest = $Reader.ReadToEnd()
        } finally {
            $Reader.Dispose()
        }

        $PatcherMatch = [regex]::Match(
            $Manifest,
            '(?m)^Patcher-Version:\s*(?<v>[^\r\n]+)'
        )

        $PatcherVersion = if ($PatcherMatch.Success) {
            $PatcherMatch.Groups["v"].Value.Trim()
        } else {
            ""
        }

        Check "Patcher-Version = 1.12.1-dev.1" (
            $PatcherVersion -eq "1.12.1-dev.1"
        )
    }
} finally {
    $Archive.Dispose()
}

if ($Failed) {
    throw "REMOTE RELEASE VERIFICATION FAILED."
}

Write-Host ""
Write-Host "REMOTE RELEASE VERIFICATION PASSED." -ForegroundColor Green
