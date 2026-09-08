# Multi-App Patches 1.0.0-port1

Compatibility release for current Morphe Manager dev.

- Targets `app.morphe:morphe-patcher:1.12.1-dev.1`.
- Removes the obsolete `app.morphe:patcher:2.0.1` build requirement.
- Ports compatibility declarations to current `AppTarget`.
- Ports Wallverse Custom Branding declaration to current patch/options API.
- Preserves Wallverse Unlock Premium bytecode logic.
- Produces a Morphe `.mpp` with `Patcher-Version: 1.12.1-dev.1`.

The public upstream source has placeholder/no-op implementations for seven of the eight advertised
patches. This compatibility release does not fabricate missing behavior.
