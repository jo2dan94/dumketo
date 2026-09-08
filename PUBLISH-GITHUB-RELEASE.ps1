param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$')]
    [string]$Repo,

    [switch]$CreateRepo,

    [switch]$PrivateRepo,

    [switch]$RefreshDependencies
)

$ErrorActionPreference = "Stop"
Set-ExecutionPolicy -Scope Process Bypass -Force

$Root = $PSScriptRoot

function Stage([string]$Text) {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " $Text" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
}

function Run([string]$Exe, [string[]]$CommandArgs) {
    & $Exe @CommandArgs
    if ($LASTEXITCODE -ne 0) {
        throw "$Exe $($CommandArgs -join ' ') failed with exit code $LASTEXITCODE"
    }
}

function Get-GitText {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$CommandArgs,

        [switch]$AllowFailure
    )

    $OutputLines = @(& git @CommandArgs 2>$null)
    $Code = $LASTEXITCODE

    if (-not $AllowFailure -and $Code -ne 0) {
        throw "git $($CommandArgs -join ' ') failed with exit code $Code"
    }

    if ($OutputLines.Count -eq 0) {
        return ""
    }

    return (($OutputLines | ForEach-Object { [string]$_ }) -join "`n").Trim()
}

Stage "1/7 - TOOLS + GITHUB AUTH"

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

& gh auth setup-git
if ($LASTEXITCODE -ne 0) {
    throw "GitHub CLI could not configure Git authentication."
}

Stage "2/7 - ENSURE DESTINATION REPOSITORY"

& gh repo view $Repo *> $null
$RepoExists = ($LASTEXITCODE -eq 0)

if (-not $RepoExists) {
    if (-not $CreateRepo) {
        throw "GitHub repository $Repo does not exist. Create it first or rerun with -CreateRepo."
    }

    $Visibility = if ($PrivateRepo) { "--private" } else { "--public" }
    Run "gh" @("repo", "create", $Repo, $Visibility, "--description", "Multi-App Patches compatibility port for Morphe")
    Write-Host "[PASS] Created GitHub repository $Repo" -ForegroundColor Green
} else {
    Write-Host "[PASS] GitHub repository exists: $Repo" -ForegroundColor Green

    if (-not (Test-Path (Join-Path $Root ".git"))) {
        $RemoteUrl = "https://github.com/$Repo.git"
        $RemoteHeads = @(& git ls-remote --heads $RemoteUrl 2>$null)
        $RemoteCode = $LASTEXITCODE

        if ($RemoteCode -ne 0) {
            throw "Could not inspect remote Git history for $Repo."
        }

        if ($RemoteHeads.Count -eq 0) {
            Write-Host "[PASS] Existing GitHub repository is empty; safe to resume from this folder." -ForegroundColor Green
        } else {
            throw @"
$Repo already contains Git history, but this extracted folder is not a clone of it.

Use the history-preserving publisher instead:
  .\PUBLISH-TO-EXISTING-REPO.ps1 -Repo "$Repo"

This safety check prevents accidentally replacing an existing repository history.
"@
        }
    }
}

Stage "3/7 - CONFIGURE REMOTE METADATA"

& (Join-Path $Root "CONFIGURE-GITHUB-REMOTE.ps1") -Repo $Repo
if (-not $?) {
    throw "Remote metadata configuration failed."
}

Stage "4/7 - BUILD"

$BuildArgs = @()
if ($RefreshDependencies) {
    $BuildArgs += "-RefreshDependencies"
}

& (Join-Path $Root "BUILD-REMOTE-MPP.ps1") @BuildArgs
if (-not $?) {
    throw "Build failed."
}

$VersionMatch = Select-String `
    -Path (Join-Path $Root "gradle.properties") `
    -Pattern '^\s*version\s*=\s*(.+?)\s*$'

$Version = $VersionMatch.Matches[0].Groups[1].Value.Trim()
$Tag = "v$Version"
$Asset = Join-Path $Root "dist\patches-$Version.mpp"

Stage "5/7 - VERIFY RELEASE CONTENT"

& (Join-Path $Root "VERIFY-REMOTE-RELEASE.ps1") -Mpp $Asset
if (-not $?) {
    throw "Remote release verification failed."
}

Stage "6/7 - COMMIT + PUSH"

if (-not (Test-Path (Join-Path $Root ".git"))) {
    Run "git" @("-C", $Root, "init")
    Run "git" @("-C", $Root, "branch", "-M", "main")
}

$Origin = Get-GitText -CommandArgs @("-C", $Root, "remote", "get-url", "origin") -AllowFailure
if ($LASTEXITCODE -ne 0 -or -not $Origin) {
    Run "git" @(
        "-C", $Root,
        "remote", "add", "origin",
        "https://github.com/$Repo.git"
    )
} elseif ($Origin -notmatch [regex]::Escape($Repo)) {
    Run "git" @(
        "-C", $Root,
        "remote", "set-url", "origin",
        "https://github.com/$Repo.git"
    )
}

$Name = Get-GitText -CommandArgs @("-C", $Root, "config", "user.name") -AllowFailure
if (-not $Name) {
    Run "git" @("-C", $Root, "config", "user.name", "Multi-App Patches Publisher")
}

$Email = Get-GitText -CommandArgs @("-C", $Root, "config", "user.email") -AllowFailure
if (-not $Email) {
    Run "git" @("-C", $Root, "config", "user.email", "multi-app-patches@localhost")
}

Run "git" @("-C", $Root, "add", "-A")

& git -C $Root diff --cached --quiet
$HasChanges = ($LASTEXITCODE -ne 0)

if ($HasChanges) {
    Run "git" @("-C", $Root, "commit", "-m", "release: $Version")
} else {
    Write-Host "No source/metadata changes to commit."
}

$HeadCommit = Get-GitText -CommandArgs @("-C", $Root, "rev-parse", "HEAD")
$ExistingTag = Get-GitText -CommandArgs @("-C", $Root, "tag", "--list", $Tag)
if (-not $ExistingTag) {
    Run "git" @(
        "-C", $Root,
        "tag", "-a", $Tag,
        "-m", "Multi-App Patches $Version"
    )
} else {
    $TagCommit = Get-GitText -CommandArgs @("-C", $Root, "rev-list", "-n", "1", $Tag)
    if ($TagCommit -ne $HeadCommit) {
        throw "Tag $Tag already exists on a different commit. Bump the project version before publishing another release."
    }
    Write-Host "[PASS] Existing tag $Tag already points at current HEAD" -ForegroundColor Green
}

Run "git" @("-C", $Root, "push", "-u", "origin", "main")
Run "git" @("-C", $Root, "push", "origin", $Tag)

Stage "7/7 - CREATE/UPDATE GITHUB RELEASE"

& gh release view $Tag --repo $Repo *> $null
$ReleaseExists = ($LASTEXITCODE -eq 0)

if ($ReleaseExists) {
    Run "gh" @(
        "release", "upload",
        $Tag,
        $Asset,
        "--repo", $Repo,
        "--clobber"
    )
} else {
    Run "gh" @(
        "release", "create",
        $Tag,
        $Asset,
        "--repo", $Repo,
        "--title", "Multi-App Patches $Version",
        "--notes-file", (Join-Path $Root "RELEASE-NOTES-v1.0.0-port1.md")
    )
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " GITHUB REMOTE SOURCE PUBLISHED" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Morphe Patch Source URL:" -ForegroundColor Yellow
Write-Host "  https://github.com/$Repo" -ForegroundColor Cyan
Write-Host ""
Write-Host "Release:"
Write-Host "  https://github.com/$Repo/releases/tag/$Tag"
Write-Host ""
Write-Host "Delete the original dumketo remote source before adding this URL."
