# Test Game Factory

A clean Godot production base for building one polished vertical slice first, then extracting reusable systems.

## Engine

- Godot 4.7.2 stable
- GDScript
- Mobile-first production discipline
- Android first-class target
- Web export remains possible where the project allows it

## Current milestone

**Foundation → Hero → Movement → Camera**

See:

- `docs/PRODUCTION_RULES.md`
- `docs/VERTICAL_SLICE.md`

## Core principle

> Build the game first. Extract the factory second.

Reusable systems belong in `game_factory/` only after they work reliably in the reference slice under `game/`.
