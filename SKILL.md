---
name: machin-demo-cyberpunk
description: Build, run, and modify machin-demo-cyberpunk — an infinite, chunk-streamed procedural planet (noise terrain + Blade-Runner neon buildings) you fly through, written in machin (MFL) via raylib. Use when working on this repo, or as the worked example of the noise builtins, infinite chunk streaming, a fly camera, and GPU-mesh terrain composed together.
---

# machin-demo-cyberpunk

An infinite procedural planet you free-fly through: noise-generated wasteland terrain that streams in chunks, with Blade-Runner neon megastructures and a hazy sky. The capstone game-dev demo — it composes the whole stack.

> Shared game-dev setup, the FFI surface, and cross-cutting gotchas live in the canonical **[machin-gamedev skill](https://github.com/javimosch/machin/blob/main/skills/machin-gamedev/SKILL.md)**. This file is the specifics.

## Build & run

```bash
./build.sh                 # machin encode cyberpunk.src -> cyberpunk.mfl, then machin build
./machin-demo-cyberpunk     # WASD + mouse to fly; Space/Ctrl up/down; Shift boost; Esc quit
```

Needs `machin` **v0.49.0+** (noise), a C compiler, **raylib**, a display, and a mouse.

## What it composes

| piece | how |
|---|---|
| **terrain** | `terrain_h(x,z)` = `fbm(noise2)` + a detail octave; native math throughout |
| **infinite streaming** | a slot pool (`[]Model` + `ccx`/`ccz`/`cused`); each frame unload out-of-range chunks, build in-range ones into free slots — only the leading edge regenerates |
| **GPU mesh per chunk** | `alloc`/`poke_f32`/`poke_u8` vertex+color arrays → `cstruct Mesh` → `UploadMesh(mesh, false)` → `LoadModelFromMesh` → `DrawModel`; `UnloadModel` on eviction |
| **fly camera** | `Camera3D` from `GetMouseDelta` (yaw/pitch) + `IsKeyDown` (WASD/Space/Ctrl/Shift) + `GetFrameTime`; forward/right via `sin`/`cos` |
| **buildings** | per chunk, `noise2` gates which sub-grid cells host a tower + its height; immediate `DrawCube` (dark) + `DrawCubeWires` (neon) + a glowing cap |
| **atmosphere** | `ClearBackground` (near-black) + `DrawRectangleGradientV` haze (purple→orange) drawn before `BeginMode3D`; cycling neon hues |

## Patterns worth copying

- **fbm (fractal noise):** sum octaves — `s += amp*noise2(x*fr, z*fr); amp*=0.5; fr*=2` (5 octaves here). The single most useful procedural primitive.
- **Chunk slot pool with opaque `Model{}`:** pre-fill `[]Model` with zeroed `Model{}` (a zero opaque handle is a safe no-op for `DrawModel`/`UnloadModel`); track `cused[]`. `loaded_at`/`free_slot` are linear scans (the pool is small).
- **World-space chunk meshes:** bake absolute world coordinates into each chunk's mesh and `DrawModel` at the origin — they assemble seamlessly.
- **Buildings are immediate, not meshes:** their positions are deterministic from `(chunkX, chunkZ)` + `noise2`, so they're recomputed and drawn each frame (no GPU state to stream).
- **raylib frees the mesh buffers:** `UploadMesh`/`LoadModelFromMesh` take ownership of your `alloc`'d vertex/color buffers; `UnloadModel` frees them (`calloc`/`free` compatible). Don't `free` them yourself.
- **Fly camera math:** `forward = (cos(pitch)·sin(yaw), sin(pitch), cos(pitch)·cos(yaw))`; `right = normalize(cross(forward, up))` = `(-fz, 0, fx)/|..|`; move by `speed·GetFrameTime()`.
- **int/float + the `a < -b` lexer trap** as everywhere: `if h < 0.0 - 3.0`, `float(i)`/`int(floor(...))`.

## Modifying

- **View distance / cost:** `RAD()` (chunks each way; `(2·RAD+1)²` loaded), `CELLS()` (mesh resolution), `MAXC()` (slot pool ≥ loaded count).
- **World shape:** `terrain_h` (frequencies/amplitudes), `CHUNK()` (world size per chunk).
- **City:** `draw_buildings` — the `noise2 > 0.22` density gate, the `9 + d·60` height, `neon()` palette.
- **Mood:** the haze colors + `ClearBackground` in `main`, the terrain palette in `shade_color`.
- After any edit to `cyberpunk.src`, re-run `./build.sh` (never hand-edit `cyberpunk.mfl` — it is generated).

## Verifying without a mouse

Headless checks can't drive WASD/mouse. To confirm streaming, build an autopilot variant (`sed` the WASD block to `camz = camz + 2.4`) and screenshot two moments — the chunk-upload count grows past the initial `(2·RAD+1)²` and the scene changes as new terrain loads.
