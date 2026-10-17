# REALM ALLIANCE — Modular Hero Visual Rig 01

The combat hero is no longer treated as one permanently baked image.

## Locked principle

Gameplay equipment and visual composition are separate.

The hero body, weapon, headgear, wings, outfit/armor visual and aura are independent layers. They may look like one finished character in combat, but they are not authored as one inseparable runtime asset.

## Runtime hierarchy

```
HeroSlot
  HeroMotion
    HeroVisualRig
      AuraBack
      BackSocket
        Wings
      Body
      Outfit
      WeaponSocket
        Weapon
      HeadSocket
        Headgear
      AuraFront
```

`HeroSlot` owns combat composition.

`HeroMotion` owns attack/hit/recoil movement.

`HeroVisualRig` owns modular appearance.

## Weapon rule

The sword is a real item, not part of the hero body.

The current slice equips:

- id: `realmblade_basic`
- visual: `weapons/realmblade/blade-basic.png`
- level: 1
- upgrade: 0
- base damage: 25

Every hero state has a weapon socket transform:

- Idle
- Attack
- Skill
- Hit
- Victory
- Defeat

The weapon sprite has a grip pivot. The grip pivot is placed on the state socket, so the sword rotates around the hand rather than around the center of the image.

This is the base for later per-frame sockets if multi-frame animation requires tighter hand tracking.

## Future customization slots

Prepared but inactive in Vertical Slice 01:

- Headgear / hats / helmets
- Wings / back items
- Armor / outfit visual
- Aura front/back

These slots exist only as visual infrastructure. They do not add inventory, currencies, upgrade screens or progression scope to the current slice.

## Armor decision

Equipment data may later contain helmet, chest, gloves, boots, etc.

The first visual implementation should use one complete `Outfit` / armor-set layer instead of independently animating every armor part. That keeps production cost manageable while gameplay stats can still remain itemized.

## Evolution / skins

Hero Evolution and skins should select body/outfit visual sets while preserving the same socket contract whenever possible.

A visual evolution can change:

- body art
- outfit
- aura
- wings
- state animation

without owning the weapon item.

## Acceptance rule

A modular item is only visually accepted when it reads as physically attached to the hero.

For weapons this means:

- grip sits in the hand,
- rotation follows the pose,
- no visible floating,
- no duplicated baked weapon,
- state transitions do not permanently move the HeroSlot.

If one state needs correction, adjust only its socket transform — never the combat layout slot.
