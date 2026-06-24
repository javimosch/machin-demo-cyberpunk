# machin-game-demo-cyberpunk

An **infinite procedural planet you fly through** — written in **[machin](https://github.com/javimosch/machin)** (MFL), rendered with raylib. WASD + mouse to free-fly over endless noise-generated wasteland, with **Blade-Runner-style neon megastructures** rising out of a hazy sky. The terrain **streams in chunks** around you and regenerates forever as you move.

Part of [**awesome-machin**](https://github.com/javimosch/awesome-machin) — the machin ecosystem.

> **Agents:** [`SKILL.md`](SKILL.md) covers the build, the noise terrain, chunk streaming, and the fly camera.

```
   ▮ ▮     ▮         machin — cyberpunk planet
 ▮ ║ ▯ ▮ ║ ▮   ▮     neon towers over an endless noise wasteland,
 ║ ║ ║ ▮ ║ ║ ▮ ║     hazy Blade-Runner sky · WASD + mouse to fly
─┴─┴─┴─┴─┴─┴─┴─┴──   terrain streams in chunks, forever
```

## Controls

- **WASD** + **mouse** — free-fly (mouse looks, WASD moves)
- **Space** / **Left Ctrl** — up / down
- **Left Shift** — boost
- **Esc** — quit

## Why it exists

This is the dogfood that drove machin's **`noise`** builtins (v0.49.0) — and it stitches together the whole stack the game/3D series built:

- **Noise terrain:** every hill, valley, and building placement comes from `noise2`, layered into **fbm** (fractal brownian motion) in MFL.
- **Infinite streaming:** the world is a grid of chunks around the camera; as you fly, chunks that drift out of range are unloaded and new ones built — a slot pool keyed by chunk coordinate, so only the leading edge regenerates.
- **GPU meshes:** each chunk is a flat-shaded mesh built in raw memory (`alloc`/`poke`), uploaded to a vertex buffer (`UploadMesh` over the pointer/array FFI, v0.47–0.48), drawn as a `Model`, and `UnloadModel`-ed when it leaves.
- **Fly camera:** a `Camera3D` (nested cstruct, v0.45) driven by `GetMouseDelta` + `IsKeyDown` + `GetFrameTime`, with forward/right vectors from native `sin`/`cos` (v0.46).
- **Buildings:** grimy **grey opaque megastructures** — Blade-Runner style. A per-cell quasi-random hash (`noise2` at high frequency) drives **100+ procedural variants**: 1–4 stacked setback boxes, varied widths/heights, a grey palette that darkens toward the base (soot/pollution), lit windows, antenna masts with blinking beacons, and the odd neon sign. (Surfaces are flat-shaded, not UV-textured — true textures want a material/shader pass.)
- **Flora — real GPU instancing.** Thousands of plants (a small mesh) are drawn in a **single `DrawMeshInstanced` call** with a custom instancing shader (`in mat4 instanceTransform`), their transform matrices built in raw memory each frame from noise-placed, terrain-snapped positions. Buildings cluster in **city districts** (low-frequency noise); the open scrubland between them is where the flora shows. Plus drifting bob-animated **drones** with neon eyes (immediate).
- **Fauna — procedural skeletal creatures.** A herd of mechanical quad-walkers roams the wasteland, each a **forward-kinematics skeleton** posed every frame through the rlgl **matrix stack** (`rlPushMatrix`/`rlTranslatef`/`rlRotatef`/`rlPopMatrix`): a torso + head over four two-segment legs whose hip and knee joints swing from `sin`/`cos` in a **diagonal gait** (a sine-driven body bob to match). The creatures stride forward and turn lazily, snapping to terrain height — no skinned mesh, just nested transforms over `DrawCube`.
- **10 km draw distance.** raylib's default perspective clips the world at ~1 km; the demo installs a **custom projection matrix** (`rlSetMatrixProjection`, a 16-float `Matrix` cstruct built with a 10 000-unit far plane) and lays down a **coarse low-res terrain underlay** — one big mesh recentered on the camera as it drifts — so the horizon recedes for kilometers, the fine chunks blending into it through the fog.
- **Atmosphere — a real shader.** The whole 3D scene renders into an off-screen `RenderTexture`, then composites to the screen through a **fragment shader** (`LoadShaderFromMemory`) that does **depth fog** — distant towers dissolve into the haze (sampling the render target's depth buffer, linearized; the sky is skipped) — plus chromatic aberration, a blue lift, scanlines, and a vignette. A dark `ClearBackground` + `DrawRectangleGradientV` set the purple→orange sky behind it.
- **Smooth streaming:** chunk meshes are built at most a few per frame (a budget) so flying never hitches — mouse-look and WASD stay responsive while the world regenerates around you.

No assets, no engine — the planet *is* the program. It's the Tier-3 ("procedural worlds") step of the [game-dev north star](https://github.com/javimosch/machin/blob/main/docs/NORTH-STAR-GAMEDEV.md).

## Build

Needs the `machin` compiler (**v0.49.0+**), a C compiler, **raylib**, a display, and a mouse. A GUI binary links the system graphics stack, so it is **not** a no-dependency binary.

```bash
./build.sh            # → ./machin-game-demo-cyberpunk
./machin-game-demo-cyberpunk
```

`build.sh` uses a **system raylib** if installed; otherwise it **vendors raylib's prebuilt static release** into `vendor/` automatically — no root required.

## Tuning

In `cyberpunk.src`: `CHUNK`/`CELLS` (chunk size & mesh resolution), `RAD` (view distance in chunks), `FAR` (far clip / draw distance), `CGRID`/`CSPAN` (distant-underlay resolution & extent), `NCREAT` (herd size), `terrain_h` (the noise field), `draw_buildings` (density/height/neon), `draw_creature` (the skeleton & gait), the haze colors in `main`. See [`SKILL.md`](SKILL.md).

## License

MIT
