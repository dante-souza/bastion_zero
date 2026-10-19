# Bastion Zero — Phase B.3 visual-fidelity correction

**Reason:** physical J8 screenshot from 2026-10-18 shows a working
B.2 Guardian, but its sparse single-color circles and thin mechanical
modules do not match the selected blue reactor artwork; the near-black
background also looks too uniform. This is not an APK mismatch.

## Corrective implementation

- Added `assets/guardian_phase_b3.svg`, an original vector illustration
  directly modeled after the user-approved visual language: broad cyan/azure
  beveled armor ring, glossy blue eye, metal housing, quartered outer arcs,
  and four more substantial cardinal modules.
- No raster screenshot of the reference and no third-party artwork included.
  Godot imports the SVG as a small, cached Texture2D, avoiding expensive
  runtime 3D effects or fragment shaders on the Samsung J8.
- Guardian is shown at **208 logical pixels** square (asset's actual visible
  mechanical diameter ~164 pixels). No collisions or touch targets changed.
- Retained B.2 physical Sentinel barrel alignment and short flashes, and
  breach-induced rim feedback. The visual asset itself is static.
- Strengthened `BACKDROP_BOTTOM` to midnight-blue #081E39 and raised the
  softly vertex-interpolated lower-field halo's opacity. Its fan remains
  20 triangles in low-FX, 32 in full-FX.
- Kept electric-blue Phase A horizon and old simulation breach threshold
  unchanged.

## Validation

The Godot smoke test now checks the SVG resource imports as a texture,
the Guardian illustration size, and the clearer lower-field visual tokens.
CI must pass both headless Godot and Android ARMv7 export before deployment.

### From the existing Phase B branch

```powershell
git fetch origin --prune
git switch feature/m1-visual-phase-b-guardian
git merge --ff-only origin/feature/m1-visual-phase-b-guardian
make check-tools
make phase-b
make phase-b-screenshot
```

Check both LOW and FULL from the hangar. We want the comparison to show
a richer cyan chassis and a perceptible but restrained navy/blue lower
glow, not a bright full-screen gradient. J8 FPS must be verified on-device.
