param()

$ErrorActionPreference = "Stop"
Set-ExecutionPolicy -Scope Process Bypass -Force

$Root = $PSScriptRoot
$SourceRoot = Join-Path $Root "patches\src\main\kotlin"

if (-not (Test-Path $SourceRoot)) {
    throw "Patch source tree not found: $SourceRoot"
}

$Source = (
    Get-ChildItem -Path $SourceRoot -Filter "*.kt" -File -Recurse |
        ForEach-Object { [System.IO.File]::ReadAllText($_.FullName) }
) -join "`n"

$BuildText = @(
    [System.IO.File]::ReadAllText((Join-Path $Root "settings.gradle.kts")),
    [System.IO.File]::ReadAllText((Join-Path $Root "gradle\libs.versions.toml")),
    [System.IO.File]::ReadAllText((Join-Path $Root "patches\build.gradle.kts"))
) -join "`n"

$Scan = $Source + "`n" + $BuildText
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
Write-Host "Multi-App Patches -> Morphe 1.12.1-dev.1 port verification" -ForegroundColor Cyan
Write-Host ""

Check "targets official app.morphe:morphe-patcher 1.12.1-dev.1" (
    $BuildText.Contains('morphe-patcher = "1.12.1-dev.1"')
)

Check "old app.morphe:patcher:2.0.1 coordinate removed" (
    -not $Scan.Contains("app.morphe:patcher:2.0.1")
)

Check "legacy PatchResult API removed" (
    -not $Scan.Contains("PatchResult")
)

Check "legacy PatchOption class hierarchy removed" (
    -not $Scan.Contains("patch.options.PatchOption")
)

Check "legacy defaultEnabled override removed" (
    -not $Scan.Contains("defaultEnabled")
)

Check "legacy Compatibility.minVersion removed" (
    -not $Scan.Contains("minVersion")
)

Check "legacy Compatibility.maxVersion removed" (
    -not $Scan.Contains("maxVersion")
)

Check "legacy Compatibility patches-list field removed" (
    -not $Scan.Contains("patches = listOf(")
)

Check "compatibility declarations use current AppTarget API" (
    $Source.Contains("AppTarget(version = ")
)

Check "Constants is an object matching existing imports" (
    $Source.Contains("object Constants")
)

Check "Custom Branding uses current resourcePatch API" (
    $Source.Contains("val wallverseCustomBrandingPatch = resourcePatch(")
)

Check "Custom Branding uses current stringOption API" (
    $Source.Contains("val customAppName by stringOption(")
)

Check "Custom Branding uses current booleanOption API" (
    $Source.Contains("val customIcon by booleanOption(")
)

$PatchRegex = [regex]'(?m)^\s*val\s+\w+Patch\s*=\s*(?:bytecodePatch|resourcePatch)\s*\('
$PatchCount = $PatchRegex.Matches($Source).Count
Check "exactly 8 top-level patch declarations found (found $PatchCount)" ($PatchCount -eq 8)

Check "build uses local official patches Gradle plugin source" (
    $BuildText.Contains('includeBuild(".deps/morphe-patches-gradle-plugin")')
)

Check "build substitutes exact local official patcher source" (
    $BuildText.Contains('includeBuild(".deps/morphe-patcher")')
)

if ($Failed) {
    throw "PORT VERIFICATION FAILED."
}

Write-Host ""
Write-Host "SOURCE PORT VERIFICATION PASSED." -ForegroundColor Green
Write-Host "No files were modified." -ForegroundColor DarkGray
