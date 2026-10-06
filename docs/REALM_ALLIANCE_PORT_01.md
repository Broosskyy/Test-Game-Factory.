# REALM ALLIANCE V2 — Vertical Slice Port 01

## Canonical source

The Godot vertical slice ports the existing REALM ALLIANCE combat master rather than inventing a new game.

Pinned reference:

- Repository: `Broosskyy/Realm-Alliance`
- Commit: `d7c385f8e75020742558fb4307f3cf712f7f1bdb`
- Reference branch: `feature/combat-master-convergence-01`
- World: **Wolkgarten**
- Hero: **Realmwächter**
- First combat presentation: **Wolkenflink** using the production cloud-golem state set

## Master constraints carried into Godot

- Combat is a fixed, non-scrolling stage.
- Production Wolkgarten scenery is layered, not replaced by a generic grid.
- Canonical mobile actor scale:
  - Hero: ~25–26% stage width
  - Normal enemy: ~45–47%
  - Elite: ~52–54%
  - Boss: ~60–61%
- Hero states: idle / attack / skill / hit / victory / defeat.
- Enemy states: idle / attack / hit / defeated.
- Damage feedback is large and readable.
- Bottom combat controls reserve their own space.
- Restart must always recover cleanly from victory/defeat.

## Port 01 scope

Port 01 proves:

1. real Wolkgarten production scenery in Godot,
2. real Realmwächter production art,
3. real enemy state art,
4. master actor scale and fixed-stage composition,
5. a minimal tap → attack → hit → counter-hit → death → restart state loop,
6. Web + Android export still pass.

It intentionally does **not** add Level-Up, Elite, Boss, Loot or the complete 60–90 second run yet. Those come only after this visual/state composition is accepted.

## Asset sync

Binary production art remains owned by the original REALM ALLIANCE repository during the port. Run:

```bash
bash scripts/sync_realm_assets.sh
```

The script downloads only the pinned production files required by the Godot slice. CI runs the same sync before Godot imports/exports.
