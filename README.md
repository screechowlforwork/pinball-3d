# Pinball — Neon Table

A 3D pinball game for the browser with a modern, Material Design 3–inspired neon look.

## Tech stack

- **React 19 + TypeScript + Vite**
- **three.js / @react-three/fiber / @react-three/drei** — rendering
- **@react-three/rapier** — physics (fixed 120 Hz timestep, kinematic flippers, CCD ball)
- **@react-three/postprocessing** — bloom + vignette
- **zustand** — game state (score, balls, phase, tilt)
- **Tailwind CSS 4** — MD3-style HUD

## Run it

```bash
npm ci
npm run dev
```

Open http://localhost:5173.

## Controls

| Input | Action |
| --- | --- |
| `←` / `Z` | Left flipper |
| `→` / `/` / `M` | Right flipper |
| `Space` (hold + release) | Charge & launch the plunger |
| `N` | Nudge the table (3+ quick nudges = tilt) |
| Touch | Bottom-left/right zones = flippers, round button = launch |

Add `?debug` to the URL for physics collider rendering and `window.__ball`/`__world` handles.

## Layout

- `src/scene/` — table, flippers, plunger, ball, bumpers, slingshots, lanes/targets, lighting, post FX
- `src/game/` — constants, zustand store, input flags, WebAudio SFX
- `src/ui/` — HUD (score card, toasts, launch hint, game-over dialog, touch controls)
