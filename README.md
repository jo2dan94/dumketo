# Multi-App Patches — GitHub Remote Morphe Port

This package turns the compatibility port into a normal **Remote** Morphe patch source.

## Target

- Morphe patcher artifact: `app.morphe:morphe-patcher`
- Required version: `1.12.1-dev.1`
- Patcher commit: `bd8608b2d0f0e1237d43f038dbff8d93ad97499e`
- Patches Gradle plugin: `1.3.4`
- Plugin commit: `9e6220d8ac3c0092c233af4e216f3bab6bb22e0d`

## Remote layout

The root `patches-bundle.json` points Morphe to:

```text
releases/tag/v1.0.0-port1
└── patches-1.0.0-port1.mpp
```

## Publish

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force

.\ONECLICK-PUBLISH.ps1 `
  -Repo "OWNER/multi-app-patches-modern" `
  -CreateRepo
```

If the repository already exists, omit `-CreateRepo`.

The script uses the authenticated GitHub CLI (`gh auth`) instead of storing a raw token in this project.

## Add to Morphe

After publishing, add:

```text
https://github.com/OWNER/multi-app-patches-modern
```

Do **not** keep the original `dumketo/multi-app-patches` remote enabled, because its v1.0.0 release
still declares patcher 2.0.1 and will trigger the global "Morphe is out of date" warning.

## Functional-source caveat

The public dumketo source contains substantive patching logic only for **Wallverse Unlock Premium**.
The other advertised patches are placeholders/no-ops in the public Kotlin source. This package ports
the source faithfully; it does not invent missing behavior.
