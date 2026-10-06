# Production Rules

## Goal

Build one small slice that looks and feels like a finished mobile game before scaling content.

## Non-negotiable rules

1. No new feature while the current core interaction is visibly or technically broken.
2. No second enemy until Hero vs. Enemy #1 feels good.
3. Fix movement, scale, collision and camera before combat expansion.
4. Fix attack timing, hit reaction, damage feedback and death before loot expansion.
5. Build concrete game code first; extract reusable Game Factory code only after a pattern is proven.
6. Mobile input is a first-class requirement, not a late porting task.
7. Every gameplay state must have a reliable restart/recovery path.
8. Use placeholder art when needed; do not block mechanics on final assets.
9. Avoid giant managers and speculative abstractions.
10. Keep the vertical slice playable at every meaningful checkpoint.

## Quality gate

A phase is complete only when it is both:

- technically stable
- visually coherent enough that we would keep it in a Play Store gameplay trailer
