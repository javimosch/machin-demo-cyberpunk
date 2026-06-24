# machin-demo-cyberpunk

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
- **Buildings:** noise decides which cells host a tower and how tall; drawn immediate as a dark box + neon wireframe + glowing cap.
- **Atmosphere:** a dark `ClearBackground` + a vertical `DrawRectangleGradientV` haze (deep purple → murky orange), neon hues cycling on the towers.

No assets, no engine — the planet *is* the program. It's the Tier-3 ("procedural worlds") step of the [game-dev north star](https://github.com/javimosch/machin/blob/main/docs/NORTH-STAR-GAMEDEV.md).

## Build

Needs the `machin` compiler (**v0.49.0+**), a C compiler, **raylib**, a display, and a mouse. A GUI binary links the system graphics stack, so it is **not** a no-dependency binary.

```bash
./build.sh            # → ./machin-demo-cyberpunk
./machin-demo-cyberpunk
```

`build.sh` uses a **system raylib** if installed; otherwise it **vendors raylib's prebuilt static release** into `vendor/` automatically — no root required.

## Tuning

In `cyberpunk.src`: `CHUNK`/`CELLS` (chunk size & mesh resolution), `RAD` (view distance in chunks), `terrain_h` (the noise field), `draw_buildings` (density/height/neon), the haze colors in `main`. See [`SKILL.md`](SKILL.md).

## License

MIT
