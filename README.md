# REALM ALLIANCE V2 — Godot Vertical Slice

Clean Godot production base for the REALM ALLIANCE Wolkgarten combat slice and the reusable systems proven by that slice.

## Engine / targets

- Godot 4.7.2 stable
- Web build + Vercel test
- Android debug APK
- Mobile-first responsive foundation

## Current milestone

**REALM ALLIANCE V2 — Vertical Slice Port 01**

The generic Game Factory demo is no longer the product reference. The canonical content reference is the existing REALM ALLIANCE combat master from `Broosskyy/Realm-Alliance`.

Current slice:

`Wolkgarten → Realmwächter → Wolkenflink → Tap Combat → Hit → Counter-Hit → Victory/Defeat → Restart`

See:

- `docs/REALM_ALLIANCE_PORT_01.md`
- `docs/PRODUCTION_RULES.md`
- `docs/VERTICAL_SLICE.md`

## Sync production art

```bash
bash scripts/sync_realm_assets.sh
```

CI performs the same pinned sync automatically before Godot imports the project.

## Core principle

> REALM ALLIANCE produces the proven game systems. The Game Factory extracts reusable systems only after they work in the real slice.
