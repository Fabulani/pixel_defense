# 6. Debug menu and CI

## Debug menu: the one-way rule

```mermaid
flowchart LR
  Main -- "if OS.is_debug_build():<br/>load('res://debug/debug_menu.gd').new()<br/>.setup(level, building_manager, tower_menu, vfx, camera)" --> DM[debug_menu.gd<br/>CanvasLayer 100, ALWAYS]
  DM --> Ctx[debug_context.gd<br/>injected refs]
  DM --> St["debug_state.gd<br/>static vars (survive F1)"]
  DM --> EWS["extra_wave_spawner.gd<br/>PAUSABLE"]
  DM --> Sec["sections/*.gd<br/>Game, Waves, Enemies, Towers, Time, VFX"]
  Sec -- "public game API only:<br/>factors (&quot;debug&quot;), set_health_ratio, spawn,<br/>set_tower_level, set_difficulty, skip_to_wave …" --> Game[(game code)]
  Game -. "never names debug/" .-x DM
```

- There is no `class_name` in `debug/`. Scripts use `preload` consts and `extends "res://debug/..."`. This lets a release export drop the folder: the CI appends `debug/*` to `exclude_filter` on tag builds.
- New tools go in a new `sections/<name>_section.gd`, which extends `debug_section.gd` and implements `build(ctx)`, `refresh()` (polled every 200 ms while the menu is open) and `apply_state()`.

## CI / release

```mermaid
flowchart LR
  subgraph build.yml["build.yml (PR, push main, dispatch, workflow_call)"]
    check["check: import ×2 (judge 2nd),<br/>headless boot 120 frames"] --> export["export matrix<br/>windows, linux, android, web"]
    export --> art["artifacts export-&lt;platform&gt;<br/>(logs-* on failure)"]
  end
  subgraph release.yml["release.yml (tag vX.Y.Z)"]
    meta["meta: strict tag regex,<br/>no v0.0.0, commit on main"] --> rb["build: calls build.yml<br/>require_signing: true + secrets"]
    rb --> rel["release: exactly 4 files,<br/>SHA256SUMS, gh release create<br/>(--clobber on re-run)"]
    rel --> pages[pages: deploy web export]
  end
  rb -.-> build.yml
```

| Build | Export mode | debug/ included | Android key |
|---|---|---|---|
| PR / main / manual | `--export-debug` | yes | throwaway debug key |
| tag release | `--export-release` | no (`debug/*` excluded via sed) | release keystore secrets |

Security conventions: top-level `permissions: contents: read`, and jobs raise only what they need. `${{ }}` values are never put inside `run:`; they are passed through `env:`.
