# Responsive Foundation

The Game Factory uses a **mobile-first 720 × 1280 logical reference canvas**.

Godot is configured with:

- `canvas_items` stretch mode
- `expand` stretch aspect
- adaptive Web canvas resizing
- full-viewport anchored root UI
- a reusable native safe-area container

## Why 720 × 1280?

It keeps mobile UI readable while `expand` adds logical space instead of distorting or letterboxing the game when the physical aspect ratio changes.

Portrait phones, tall phones, tablets, landscape devices and desktop browsers therefore share one coordinate system without stretching UI.

## UI rules

- Full-screen backgrounds always anchor to all four viewport edges.
- Gameplay/UI containers never use hard-coded 1280 × 720 rectangles.
- Interactive UI belongs inside the reusable safe-area container.
- World/camera logic may react to the expanded visible area; UI stays anchored.
- Touch and mouse/keyboard are first-class targets.
- Orientation-specific layout changes should be driven by available viewport shape, not device model.

## Web

The Web export uses Godot's adaptive canvas resize policy. The browser's usable viewport is filled by the Godot canvas.

## Android/iOS

Native display safe areas are converted from physical screen coordinates into the logical Godot viewport before UI margins are applied.
