# Wave rework

Planned 2026-11-22. Replaces the dev-only wave generation (roadmap item 5). One PR per phase. Each phase has its own brief (`phase-N.md`) so an implementer reads only that.

## Why

- Size `3 + 3 × fib(index)`: wave 15 ≈ 1134 enemies, spawn gap 0.01 s from wave 11 (likely part of the Android fps drop).
- Variants picked w/ global `randi()` -> `--seed` replays map, not waves. Slot overwrite -> shares inexact.
- `max_waves` 15 in `.tres` vs 20 in script.
- Income = kill coins only; fast pays 0.
- All spawners share one mix; no special waves, no bosses.

## Decisions

- **Run length**: 20 waves, `WaveConfig.max_waves`. Later a settings screen customizes it (and difficulty). Endless mode: later.
- **Difficulty**: per-wave budget, fixed before the wave (seeded). Enemies cost points. No Risk-of-Rain-style director (time-based credit spender): waves here are discrete, seeded, previewable.
- **Seed**: each wave's local `RandomNumberGenerator` seeded with `hash([map_seed, wave_index])`, same approach as `MapGenerator`. No global `randi`. Engine-version hash drift: fix later if it ever matters.
- **Pacing**: countdown after spawning ends; "next wave" button skips it for a bonus. Waves may overlap.
- **Normal vs special**: normal waves have no name (banner "Wave N"). Special waves (templates: swarm, tank, rush, boss, more as `.tres`) show name + one-line description. A "modifier wave" = a template w/ its own params.
- **Per-spawner composition**: budget split over open spawners; each spawner draws its own template.
- **Legacy map**: removed as playable option (phase 0). Tilemap stays in `levels/level.tscn` for future unique maps (`docs/ideas.md`).

## Phases

| # | Brief | Content | Status |
|---|---|---|---|
| 0 | [phase-0.md](phase-0.md) | Remove legacy map option | todo |
| 1 | [phase-1.md](phase-1.md) | Seeded budget generator, 20 waves, `tools/print_waves` | todo |
| 2 | [phase-2.md](phase-2.md) | Wave templates, per-spawner composition, boss slot | todo |
| 3 | [phase-3.md](phase-3.md) | Countdown, call-early bonus, wave banner | todo |
| 4 | [phase-4.md](phase-4.md) | Bosses (base + varieties). Blocked on debug scene | outline |

Briefs 1-4 are rechecked against merged code before their phase starts.

Not in this rework: endless mode, wave-settings screen, upcoming-waves strip, first-encounter intro card, wave-clear bonus, balancing pass (all values are placeholders).

## Agent briefing (every brief links this)

Read first, in order:
1. `/home/kabano/workspace/studio/.claude/agents/implementer.md` (implementer) or `/home/kabano/workspace/studio/.claude/agents/reviewer.md` (reviewer)
2. `/home/kabano/workspace/studio/.claude/skills/terse-speech/SKILL.md`
3. `/home/kabano/workspace/studio/.claude/skills/godot-studio/SKILL.md`
4. pixel_defense `CLAUDE.md`
5. this file's Decisions + the phase brief

pixel_defense deltas (win over studio files on conflict):
- Mobile renderer, not Forward+. No `modules/`, no host/module split -> module rules n/a.
- No StudioTest, no test runner. Ignore red-first, `tests/`, `red proof` report line. Verify w/ headless runs, report output:
  - `godot --headless --import` (twice if `.godot/` fresh)
  - `godot --headless --quit-after 120` -> no `SCRIPT ERROR` / `ERROR:`
  - phase tool/scenario scripts. Scratch scenario scripts -> scratchpad dir, never repo. Only `tools/` files named in brief get committed.
- CLAUDE.md conventions apply (static typing, `##` docs, `_on_<source>_<signal>`, cross-scene wiring in `Main._ready()`, `Level` facade).
- Git: no commit, branch, switch, stash, push. Manager does all git.
- No edits to `CLAUDE.md`, `README.md`, `docs/`. Manager updates them after review.
- Values marked placeholder: use as given, never tune.

## Workflow per phase

1. Manager: branch `wave-rework/phase-N` from `main`; recheck brief vs code.
2. Implementer (sonnet, medium effort).
3. Reviewer (sonnet, high effort, read-only): `git diff main` + untracked files vs brief.
4. Manager triages findings -> fixes back to same implementer.
5. Headless verification (manager reruns acceptance commands).
6. Manager updates `CLAUDE.md`, docs, phase status, `docs/untracked/workflow-notes.md` (git-ignored personal notes).
7. Manager commits. Author/committer = user, no `Co-Authored-By`, no attribution. Check `git log --format='%h %an <%ae> | %cn <%ce>' origin/main..HEAD` before push.
8. User playtests.
9. Manager pushes + opens PR (no "Generated with" line). User merges.
