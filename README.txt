MULTI-APP PATCHES — CURRENT MORPHE API PORT
===========================================

Goal
----
Build a fresh Multi-App Patches .mpp against the exact patcher shipped by the
current Morphe Manager dev build, WITHOUT modifying the working R4+PAT manager.

Target:
  app.morphe:morphe-patcher:1.12.1-dev.1

This is a local compatibility port of the public dumketo/multi-app-patches source.
It is not an upstream dumketo release.

FIRST: STATIC VERIFY
--------------------
Open PowerShell in this folder:

Set-ExecutionPolicy -Scope Process Bypass -Force

.\VERIFY-MULTIAPP-PORT.ps1

Expected:
  SOURCE PORT VERIFICATION PASSED.

BUILD
-----
Set-ExecutionPolicy -Scope Process Bypass -Force

.\BUILD-MULTIAPP-PORTED.ps1

The builder:
1. verifies the port;
2. downloads/verifies Gradle 9.7.1 if needed;
3. downloads pinned PUBLIC source for:
     Morphe patcher 1.12.1-dev.1
     Morphe patches Gradle plugin 1.3.4
4. builds with the official :patches:buildAndroid path;
5. verifies classes.dex and Patcher-Version;
6. writes the final artifact under:
     .\dist\

NO PAT REQUIRED
---------------
The build uses local composite builds of the official Morphe source.
It does not require or read your Morphe GitHub PAT.

The script supplies dummy GITHUB_ACTOR/GITHUB_TOKEN values only because the
official SettingsPlugin requires those environment variable names to exist even
when its GitHub Packages repository is not needed. The dummy values are not
credentials and are restored/removed after Gradle exits.

REFRESH PINNED CHECKOUTS
------------------------
If the .deps folders become damaged:

.\BUILD-MULTIAPP-PORTED.ps1 -RefreshDependencies

IMPORTANT FUNCTIONALITY NOTE
----------------------------
The source audit found that seven of the eight advertised patches are placeholders
or no-ops in the public dumketo source. Only Wallverse Unlock Premium contains
substantive patching logic.

This port fixes API/build compatibility; it does not invent missing patch logic.

See:
  PORT-AUDIT.md
