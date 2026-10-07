# REALM ALLIANCE V2 — Godot Vertical Slice

Clean Godot production base for proving one polished REALM ALLIANCE combat run before scaling the full game or extracting reusable Game Factory systems.

## Engine / targets

- Godot 4.7.2 stable
- Web build + Vercel test
- Android debug APK
- Mobile-first responsive foundation

## Current milestone

**Grünhain Vertical Slice 06**

The current production test is now the complete Grünhain run because the V2 repository contains a full production encounter roster and a finished single-background combat scene for this region.

Run target:

`Start → 3 normal enemies → Level-up → Elite → Boss → Loot → Victory/Defeat → Restart`

Current production roster:

- M001 Waldwinzling
- M002 Blatthorn
- M004 Pilzling
- M010 Waldgeist (Elite)
- B001 Mooskönig (Boss)

The previous Wolkgarten Godot scene remains in the repository as a visual/port reference, but it is no longer the active main scene for the Game Factory vertical-slice test.

## Asset policy

Runtime assets are pinned to exact commits from `Broosskyy/Realm-Alliance`. Presentation sheets and mockups are reference only; original isolated PNGs are preferred whenever available.

## Core principle

> Finish one small run to Play-Store quality first. Scale content and extract reusable systems only after the run is stable and polished.


## Locked combat layout

The active slice uses a fixed master layout contract. Do not tune actor anchors ad hoc from individual screenshots.

See `docs/GRUENHAIN_COMBAT_MASTER_LOCK.md` and `realm_alliance/combat/gruenhain_combat_layout.gd`.
