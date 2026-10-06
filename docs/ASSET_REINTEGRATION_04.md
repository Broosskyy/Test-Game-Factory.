# REALM ALLIANCE — Asset Reintegration 04

## Purpose

Rebuild the Godot combat slice from the strongest existing REALM ALLIANCE production assets instead of recreating UI and VFX with text placeholders or re-cutting presentation screenshots.

## Canonical runtime sources

### Combat Master art

Repository: `Broosskyy/Realm-Alliance`  
Pinned commit: `d7c385f8e75020742558fb4307f3cf712f7f1bdb`  
Reference branch: `feature/combat-master-convergence-01`

Used for:

- Wolkgarten world layers
- Realmwächter combat states currently available as isolated files
- Cloud/stone golem states
- Crystal wolf states
- Realmblade variants
- Golem and Realmblade VFX

### V2 production UI / VFX

Repository: `Broosskyy/Realm-Alliance`  
Pinned commit: `61b4aa9b2dff1337e0a64615f8f98c4791e1af4e`  
Reference branch: `realm-v2-web-first`

Used for:

- UI V4 combat core icons
- UI V4 combat status icons
- UI V4 navigation
- V2 resource icons
- Monster/boss HUD art
- V190 combat impacts
- V190 progression and reward VFX

Both sources are pinned. Later changes in the legacy repository cannot silently alter the Godot slice.

## Uploaded-sheet audit

### Active direction / production-relevant

- Steingolem + crystal VFX sheet: strong match for current combat target.
- Realmblade elemental weapon/VFX sheets: strong match for the elemental attack pipeline.
- Blue/purple/gold crystalline UI sheet: strong match for current V2 master UI direction.
- Wolkgarten modular island/ruin sheets: strong match for future stage reconstruction.
- White-haired Realmwächter boards: strong match for the majority of later master mockups.

Where equivalent isolated source PNGs already exist in the repository, the original individual files are preferred over cutting the uploaded sheets.

### Reference only

- Full screen mockup/composition boards: visual master reference, never runtime textures.
- Older brown/gold parchment UI sheets: useful reference but not the active combat UI direction.
- Legacy all-in-one presentation sheets with headings/labels: never imported directly into gameplay.

### Hero conflict

Two incompatible hero directions are present in historical material:

1. brown-haired / red-scarf combat hero,
2. white-haired / blue-cloak Realmwächter.

The approved later combat/product masters predominantly use the white-haired Realmwächter. However, the pinned combat branch currently contains isolated runtime state PNGs for the red-scarf variant.

Rule for now:

- do not mix both characters inside one animation state set,
- keep the existing isolated combat hero temporarily,
- migrate only when a complete isolated white-haired state set is available (Idle/Attack/Skill/Hit/Victory/Defeated at minimum).

## Reintegration 04 runtime changes

- resource-letter placeholders -> production resource icons
- status-letter placeholders -> production combat status icons
- skill text symbols -> production combat-core icons
- AUTO text symbol -> production AUTO icon
- bottom navigation text symbols -> production navigation icons
- basic Realmblade VFX -> crystal Realmblade slash
- add strong ice impact on enemy hit
- sync additional Realmblade variants, golem VFX, portal island, progression and reward VFX

## Quality rule

A presentation sheet is never treated as a production sprite merely because it looks good.

Priority:

1. original isolated transparent PNG,
2. isolated asset generated from an owned source kit and visually QA'd,
3. temporary procedural placeholder,
4. presentation/mockup crop only as a last temporary reference — never a shipping asset.
