param(
    [switch]$RefreshDependencies
)

$ErrorActionPreference = "Stop"
Set-ExecutionPolicy -Scope Process Bypass -Force

$Root = $PSScriptRoot
$Deps = Join-Path $Root ".deps"
$Tools = Join-Path $Root ".tools"
$Dist = Join-Path $Root "dist"

$PatcherRepo = "https://github.com/MorpheApp/morphe-patcher.git"
$PatcherCommit = "bd8608b2d0f0e1237d43f038dbff8d93ad97499e" # v1.12.1-dev.1

$PluginRepo = "https://github.com/MorpheApp/morphe-patches-gradle-plugin.git"
$PluginCommit = "9e6220d8ac3c0092c233af4e216f3bab6bb22e0d" # 1.3.4 main

$GradleVersion = "9.7.1"
$GradleSha256 = "acd53f1edaf02f1a8ff99879f8a34b302661a057d9b063ae9e35b552f804d20a"
$GradleUrl = "https://services.gradle.org/distributions/gradle-$GradleVersion-bin.zip"

function Stage([string]$Text) {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " $Text" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
}

function Pass([string]$Text) {
    Write-Host "[PASS] $Text" -ForegroundColor Green
}

function Invoke-GitChecked {
    param(
        [string]$WorkingDirectory,
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$GitArgs
    )

    & git -C $WorkingDirectory @GitArgs
    if ($LASTEXITCODE -ne 0) {
        throw "git $($GitArgs -join ' ') failed with exit code $LASTEXITCODE"
    }
}

function Ensure-PinnedGitSource {
    param(
        [string]$Name,
        [string]$Url,
        [string]$Path,
        [string]$Commit
    )

    if ($RefreshDependencies -and (Test-Path $Path)) {
        Remove-Item $Path -Recurse -Force
    }

    if (-not (Test-Path (Join-Path $Path ".git"))) {
        Write-Host "Fetching $Name..."
        New-Item -ItemType Directory -Path $Path -Force | Out-Null

        & git -C $Path init -q
        if ($LASTEXITCODE -ne 0) { throw "git init failed for $Name" }

        & git -C $Path remote add origin $Url
        if ($LASTEXITCODE -ne 0) { throw "git remote add failed for $Name" }

        & git -C $Path fetch --depth 1 origin $Commit
        if ($LASTEXITCODE -ne 0) { throw "git fetch failed for $Name" }

        & git -C $Path checkout --detach FETCH_HEAD
        if ($LASTEXITCODE -ne 0) { throw "git checkout failed for $Name" }
    }

    $Head = (& git -C $Path rev-parse HEAD 2>$null).Trim()
    if ($LASTEXITCODE -ne 0 -or $Head -ne $Commit) {
        Write-Host "$Name is not at the pinned commit; repairing checkout..." -ForegroundColor Yellow

        & git -C $Path fetch --depth 1 origin $Commit
        if ($LASTEXITCODE -ne 0) { throw "git fetch failed while repairing $Name" }

        & git -C $Path checkout --detach FETCH_HEAD
        if ($LASTEXITCODE -ne 0) { throw "git checkout failed while repairing $Name" }

        $Head = (& git -C $Path rev-parse HEAD).Trim()
    }

    if ($Head -ne $Commit) {
        throw "$Name commit mismatch. Expected $Commit, got $Head"
    }

    Pass "$Name pinned at $Commit"
}

function Ensure-Java17 {
    $JavaExe = $null

    if ($env:JAVA_HOME) {
        $Candidate = Join-Path $env:JAVA_HOME "bin\java.exe"
        if (Test-Path $Candidate) {
            $JavaExe = $Candidate
        }
    }

    if (-not $JavaExe) {
        $Cmd = Get-Command java -ErrorAction SilentlyContinue
        if ($Cmd) {
            $JavaExe = $Cmd.Source
        }
    }

    if (-not $JavaExe) {
        $Candidates = @(
            "$env:ProgramFiles\Android\Android Studio\jbr\bin\java.exe",
            "$env:LOCALAPPDATA\Programs\Android Studio\jbr\bin\java.exe"
        )

        $Found = $Candidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
        if ($Found) {
            $JavaExe = $Found
            $env:JAVA_HOME = Split-Path (Split-Path $Found -Parent) -Parent
            $env:Path = "$(Split-Path $Found -Parent);$env:Path"
        }
    }

    if (-not $JavaExe) {
        throw "Java was not found. Install/use JDK 17+ (Android Studio's bundled JBR is fine)."
    }

    $VersionLine = (& $JavaExe -version 2>&1 | Select-Object -First 1).ToString()
    $Match = [regex]::Match($VersionLine, '"(?<major>\d+)(?:\.(?<minor>\d+))?')
    if ($Match.Success) {
        $Major = [int]$Match.Groups["major"].Value
        if ($Major -eq 1 -and $Match.Groups["minor"].Success) {
            $Major = [int]$Match.Groups["minor"].Value
        }
        if ($Major -lt 17) {
            throw "Java $Major detected; Gradle $GradleVersion requires JDK 17+."
        }
    }

    Pass "Java: $VersionLine"
}

function Ensure-Gradle {
    New-Item -ItemType Directory -Path $Tools -Force | Out-Null

    $GradleHome = Join-Path $Tools "gradle-$GradleVersion"
    $GradleBat = Join-Path $GradleHome "bin\gradle.bat"
    if (Test-Path $GradleBat) {
        Pass "Gradle $GradleVersion already available"
        return $GradleBat
    }

    $Zip = Join-Path $Tools "gradle-$GradleVersion-bin.zip"

    if (Test-Path $Zip) {
        $ExistingHash = (Get-FileHash -Algorithm SHA256 $Zip).Hash.ToLowerInvariant()
        if ($ExistingHash -ne $GradleSha256) {
            Remove-Item $Zip -Force
        }
    }

    if (-not (Test-Path $Zip)) {
        Write-Host "Downloading official Gradle $GradleVersion..."
        $OldProgress = $ProgressPreference
        try {
            $ProgressPreference = "SilentlyContinue"
            Invoke-WebRequest -Uri $GradleUrl -OutFile $Zip
        } finally {
            $ProgressPreference = $OldProgress
        }
    }

    $Hash = (Get-FileHash -Algorithm SHA256 $Zip).Hash.ToLowerInvariant()
    if ($Hash -ne $GradleSha256) {
        throw "Gradle distribution SHA-256 mismatch. Expected $GradleSha256, got $Hash"
    }
    Pass "Gradle distribution SHA-256 verified"

    Expand-Archive -Path $Zip -DestinationPath $Tools -Force

    if (-not (Test-Path $GradleBat)) {
        throw "Gradle extraction completed but gradle.bat was not found: $GradleBat"
    }

    Pass "Gradle $GradleVersion extracted"
    return $GradleBat
}

function Verify-Mpp {
    param([string]$Path)

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $Archive = [System.IO.Compression.ZipFile]::OpenRead($Path)
    try {
        $Dex = @(
            $Archive.Entries |
                Where-Object { $_.FullName -match '^classes(\d*)?\.dex$' -and $_.Length -gt 0 }
        )
        if ($Dex.Count -eq 0) {
            throw "Built .mpp has no non-empty classes.dex entry."
        }

        $ManifestEntry = $Archive.GetEntry("META-INF/MANIFEST.MF")
        if ($null -eq $ManifestEntry) {
            throw "Built .mpp has no META-INF/MANIFEST.MF."
        }

        $Reader = New-Object System.IO.StreamReader($ManifestEntry.Open())
        try {
            $Manifest = $Reader.ReadToEnd()
        } finally {
            $Reader.Dispose()
        }

        $PatcherMatch = [regex]::Match($Manifest, '(?m)^Patcher-Version:\s*(?<v>[^\r\n]+)')
        if (-not $PatcherMatch.Success) {
            throw "Built .mpp manifest has no Patcher-Version."
        }

        $PatcherVersion = $PatcherMatch.Groups["v"].Value.Trim()
        if ($PatcherVersion -ne "1.12.1-dev.1") {
            throw "Wrong Patcher-Version in .mpp. Expected 1.12.1-dev.1, got $PatcherVersion"
        }

        $NameMatch = [regex]::Match($Manifest, '(?m)^Name:\s*(?<v>[^\r\n]+)')
        $BundleName = if ($NameMatch.Success) { $NameMatch.Groups["v"].Value.Trim() } else { "<missing>" }

        return [pscustomobject]@{
            Manifest = $Manifest
            PatcherVersion = $PatcherVersion
            BundleName = $BundleName
            DexEntries = ($Dex | ForEach-Object { "$($_.FullName)=$($_.Length)" }) -join ", "
        }
    } finally {
        $Archive.Dispose()
    }
}

Stage "MORPHE MULTI-APP PATCHES MODERN PORT"

Write-Host "Target patcher: 1.12.1-dev.1"
Write-Host "Official patcher commit: $PatcherCommit"
Write-Host "Official patches-plugin commit: $PluginCommit"
Write-Host ""
Write-Host "This build does NOT use your GitHub PAT." -ForegroundColor Green
Write-Host "The official patcher and Gradle plugin are built locally from pinned public source." -ForegroundColor Green

Stage "1/5 - SOURCE PORT VERIFICATION"
& (Join-Path $Root "VERIFY-MULTIAPP-PORT.ps1")
if (-not $?) {
    throw "Static port verifier failed."
}

Stage "2/5 - TOOLCHAIN"
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git was not found in PATH."
}
Pass "Git found"

Ensure-Java17
$GradleBat = Ensure-Gradle

Stage "3/5 - PINNED OFFICIAL MORPHE SOURCES"
New-Item -ItemType Directory -Path $Deps -Force | Out-Null

Ensure-PinnedGitSource `
    -Name "Morphe patches Gradle plugin 1.3.4" `
    -Url $PluginRepo `
    -Path (Join-Path $Deps "morphe-patches-gradle-plugin") `
    -Commit $PluginCommit

Ensure-PinnedGitSource `
    -Name "Morphe patcher 1.12.1-dev.1" `
    -Url $PatcherRepo `
    -Path (Join-Path $Deps "morphe-patcher") `
    -Commit $PatcherCommit

Stage "4/5 - BUILD .MPP"

# The official settings plugin requires these variables to exist because normally
# it can use GitHub Packages. In this build every Morphe dependency is substituted
# by pinned local source, so dummy values are enough and no real credential is used.
$OldActor = $env:GITHUB_ACTOR
$OldToken = $env:GITHUB_TOKEN

try {
    $env:GITHUB_ACTOR = "local-source-build"
    $env:GITHUB_TOKEN = "unused-local-source-build"

    Push-Location $Root
    try {
        & $GradleBat ":patches:clean" ":patches:buildAndroid" "--no-daemon" "--stacktrace"
        $BuildCode = $LASTEXITCODE
    } finally {
        Pop-Location
    }
} finally {
    if ($null -eq $OldActor) {
        Remove-Item Env:GITHUB_ACTOR -ErrorAction SilentlyContinue
    } else {
        $env:GITHUB_ACTOR = $OldActor
    }

    if ($null -eq $OldToken) {
        Remove-Item Env:GITHUB_TOKEN -ErrorAction SilentlyContinue
    } else {
        $env:GITHUB_TOKEN = $OldToken
    }
}

if ($BuildCode -ne 0) {
    throw "Gradle build failed with exit code $BuildCode"
}

$Built = Get-ChildItem -Path (Join-Path $Root "patches\build\libs") -Filter "*.mpp" -File |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if ($null -eq $Built) {
    throw "Gradle reported success but no .mpp was found under patches\build\libs."
}

Pass "Gradle produced $($Built.Name)"

Stage "5/5 - .MPP STRUCTURE + MANIFEST VALIDATION"
$Info = Verify-Mpp -Path $Built.FullName

New-Item -ItemType Directory -Path $Dist -Force | Out-Null
$VersionMatch = Select-String -Path (Join-Path $Root "gradle.properties") -Pattern '^\s*version\s*=\s*(.+?)\s*$'
if (-not $VersionMatch) {
    throw "Could not determine project version from gradle.properties."
}
$ProjectVersion = $VersionMatch.Matches[0].Groups[1].Value.Trim()
$Final = Join-Path $Dist "patches-$ProjectVersion.mpp"
Copy-Item $Built.FullName $Final -Force

$Sha = (Get-FileHash -Algorithm SHA256 $Final).Hash.ToLowerInvariant()
$Size = (Get-Item $Final).Length

$Report = Join-Path $Dist "BUILD-VALIDATION.txt"
@"
Multi-App Patches modern port build validation
==============================================
Built: $(Get-Date -Format o)

Bundle:
  $Final

Size:
  $Size bytes

SHA-256:
  $Sha

Manifest Name:
  $($Info.BundleName)

Patcher-Version:
  $($Info.PatcherVersion)

DEX:
  $($Info.DexEntries)

Pinned sources:
  morphe-patcher:
    $PatcherCommit
  morphe-patches-gradle-plugin:
    $PluginCommit

Validation:
  source port verifier: PASS
  classes.dex present/non-empty: PASS
  Patcher-Version == 1.12.1-dev.1: PASS
"@ | Set-Content $Report -Encoding UTF8

Pass "classes.dex present and non-empty"
Pass "Patcher-Version = 1.12.1-dev.1"
Pass "SHA-256 = $Sha"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " BUILD + VALIDATION COMPLETE" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Fresh .mpp:" -ForegroundColor Yellow
Write-Host "  $Final" -ForegroundColor Cyan
Write-Host ""
Write-Host "Validation report:"
Write-Host "  $Report"
