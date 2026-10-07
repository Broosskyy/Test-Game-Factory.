# Grünhain Combat Master Lock

This document ends the screenshot → anchor → screenshot loop.

## Product target

The active Game Factory reference remains the short REALM ALLIANCE Grünhain run:

Start → Normal 1 → Normal 2 → Normal 3 → Level-up → Elite → Boss → Loot → Victory/Defeat → Restart.

The purpose of this slice is to prove a repeatable production system, not to expand the game.

## Visual source of truth

The approved REALM ALLIANCE combat masters define the hierarchy:

1. global header,
2. compact region progress,
3. compact enemy HUD,
4. hero left / enemy right on one shared ground line,
5. large readable hit feedback,
6. vitals immediately under combat,
7. four dominant skill orbs + AUTO,
8. fixed five-tab navigation.

Grünhain uses its own finished production background and roster. Wolkgarten mockups remain composition references, not runtime art for this slice.

## Fixed layout contract

All combat layout is now centralized in:

`realm_alliance/combat/gruenhain_combat_layout.gd`

The layout exposes fixed slots for:

- Hero
- Normal enemy
- Elite enemy
- Boss enemy
- Enemy HUD
- World progress
- Streak toaster
- Damage feedback
- Hit VFX
- Vitals
- Skills
- Combat backing
- Input hint

Portrait is the primary quality target. Landscape remains supported through a second explicit profile.

## Ground-line rule

Portrait ground line: **0.74 of the combat stage**.

Hero, Normal, Elite and Boss slots must terminate within ±0.035 of that line.

This is a structural rule. Actor art can change, but actor holders do not drift vertically from state to state.

## Motion rule

The slot owns layout.

The motion wrapper owns animation.

Hierarchy:

```
HeroSlot
  HeroMotion
    HeroArt

EnemySlot
  EnemyMotion
    EnemyArt
```

Attack, hit recoil, spawn and death may animate `HeroMotion` / `EnemyMotion`.

They must never animate or reset `HeroSlot` / `EnemySlot` position.

This prevents the exact bug where an anchored Control was reset with `position = Vector2.ZERO` and jumped toward the stage origin.

## State rule

Idle / Attack / Hit / Defeat / Victory may only replace art/state.

A state change must not modify:

- anchors,
- offsets,
- scale class,
- ground line,
- HUD placement.

Normal / Elite / Boss differences come only from their locked slot classes plus their own state assets.

## Acceptance gate

We do not reopen layout tuning for subjective 2–5 px differences.

Layout is reopened only if one of these is true:

- actor is visibly clipped,
- actor feet miss the shared ground line materially,
- HUD overlaps critical actor/action information,
- portrait or landscape becomes unusable,
- a state/tween changes permanent actor placement.

Otherwise the layout is considered locked and work moves forward to:

1. correct white-haired Realmwächter production state kit,
2. combat timing / hit feel,
3. animation lock,
4. audio/VFX polish,
5. final 60–90 second run QA,
6. extraction of reusable Game Factory systems.
