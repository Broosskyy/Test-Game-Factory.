# Vertical Slice V1

## Target

A polished 60–90 second combat run.

## Sequence

1. Spawn / ready state
2. Hero movement
3. First normal enemy
4. Basic attack and hit feedback
5. Additional normal enemies
6. Level-up choice
7. Elite encounter
8. Boss encounter
9. Reward / result
10. Victory or defeat
11. Reliable restart

## Build order

### Phase 1 — Hero foundation
- movement
- collision
- facing / orientation
- camera
- mouse + keyboard debug input
- mobile touch input boundary

### Phase 2 — Combat foundation
- attack
- hitbox / hurtbox
- health
- hit reaction
- damage numbers
- death

### Phase 3 — Enemy factory
- one normal enemy
- data-driven tuning where useful
- spawn / death lifecycle
- second and third enemy only after Enemy #1 is stable

### Phase 4 — Run structure
- level-up
- elite
- boss
- victory / defeat
- restart

### Phase 5 — Polish
- VFX
- hit stop / screenshake where appropriate
- audio
- transitions
- UI polish
- mobile performance

## Explicitly out of scope for V1

- large inventory system
- shop
- wings / pets
- guilds
- multiplayer
- open world expansion
- large content catalogs
- complex backend
