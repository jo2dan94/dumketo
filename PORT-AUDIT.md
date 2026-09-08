# Multi-App Patches → current Morphe API port

## Target

This port targets **the exact patcher version bundled by the current Morphe Manager dev build**:

- Artifact: `app.morphe:morphe-patcher`
- Version: `1.12.1-dev.1`
- Patcher commit: `bd8608b2d0f0e1237d43f038dbff8d93ad97499e`
- Patches Gradle plugin: `1.3.4`
- Plugin commit: `9e6220d8ac3c0092c233af4e216f3bab6bb22e0d`

The build intentionally does **not** target `app.morphe:patcher:2.0.1`.

## Exact source changes made

### Build system

Original:
```kotlin
compileOnly("app.morphe:patcher:2.0.1")
```

Port:
- Uses the current official Morphe patches Gradle plugin.
- The plugin supplies `app.morphe:morphe-patcher:1.12.1-dev.1`.
- `settings.gradle.kts` substitutes that coordinate with a pinned local checkout
  of the official patcher source.

### `Constants.kt`

The original source had two separate problems:

1. Other files imported values as `Constants.WALLVERSE_COMPATIBILITY`, but
   `Constants.kt` declared top-level values and had no `object Constants`.
2. It used old compatibility constructor fields:
   `minVersion`, `maxVersion`, and `patches`.

The port:
- restores `object Constants`;
- replaces min/max declarations with current `AppTarget(version = ...)`;
- removes the obsolete patch-name list from Compatibility.

### `CustomBrandingPatch.kt`

The original used the old class-style patch API:
- `class ... : Patch()`
- `defaultEnabled`
- `PatchResult`
- `PatchResult.success/failed`
- `PatchOption.StringPatchOption`
- `PatchOption.BooleanPatchOption`

The port uses:
- `resourcePatch(...)`
- `stringOption(...)`
- `booleanOption(...)`
- current `Compatibility`.

The upstream implementation contained only placeholder/TODO resource operations,
so the port intentionally remains a no-op instead of inventing behavior.

### Other patch files

The builder-style patch declarations, Fingerprint API, instruction filters and
InstructionExtensions used by the Wallverse premium patch are compatible in shape
with Morphe Patcher 1.12.1-dev.1 and were preserved.

## Important upstream quality finding

Of the eight advertised patches, **only the Wallverse Unlock Premium patch contains
substantive patching logic in the public source**.

The following source files contain placeholder/no-op execute blocks:
- AccuBattery — Unlock Pro Features
- AccuBattery — Remove Ads
- AdGuard — Premium License
- AdGuard — Custom DNS
- Adobe Acrobat — Unlock Pro Tools
- Adobe Acrobat — Remove Watermarks

Wallverse Custom Branding also contains placeholder behavior.

Therefore a successful port/build can make all eight patch declarations loadable,
but it does **not** magically make the seven placeholder patches functional.

The published `patches-list.json` also advertises a `dnsServers` option for
AdGuard Custom DNS which is absent from its Kotlin source. This port preserves the
actual Kotlin source rather than fabricating implementation.

## Build safety

`BUILD-MULTIAPP-PORTED.ps1`:
- does not modify Morphe Manager or the R4+PAT tree;
- uses no real GitHub PAT;
- pins the exact official patcher and patches-plugin commits;
- downloads Gradle 9.7.1 and verifies the official SHA-256 before extraction;
- runs the official `:patches:buildAndroid` path;
- verifies the resulting `.mpp` has a non-empty `classes.dex`;
- verifies the manifest says `Patcher-Version: 1.12.1-dev.1`;
- copies the validated artifact to `dist`.


## GitHub remote source packaging

This package adds a root `patches-bundle.json` and a reproducible release publisher.

Expected release:
- tag: `v1.0.0-port1`
- asset: `patches-1.0.0-port1.mpp`
- manifest patcher requirement: `1.12.1-dev.1`

`CONFIGURE-GITHUB-REMOTE.ps1` rewrites both the metadata download URL and the `.mpp`
Source/Website fields for the destination repository.

`VERIFY-REMOTE-RELEASE.ps1` rejects:
- mismatched metadata version;
- mismatched tag/asset URL;
- leftover OWNER/REPO placeholders;
- an empty/missing DEX;
- any Patcher-Version other than `1.12.1-dev.1`.

`PUBLISH-GITHUB-RELEASE.ps1` uses GitHub CLI authentication (`gh auth`) and does not require
a raw personal access token to be stored in this project.
