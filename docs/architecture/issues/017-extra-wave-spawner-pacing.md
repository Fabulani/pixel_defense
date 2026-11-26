# The debug "spawn wave N" extra does not match real wave pacing

- **Type:** debug tooling
- **Priority:** low
- **Area:** debug

## Description
`debug/extra_wave_spawner.gd` passes `[]` as `last_templates` and ignores `WaveTemplate.spawn_delay_multiplier` and the per-spawner stagger. An extra wave therefore spawns at a different rhythm, and may draw different templates, than the real wave N would.

## Fix
Reuse `WaveManager`'s pacing formula (`delay × n × template multiplier`, first delay `delay × (k + 1)`) and its last-templates logic, or document the difference in the Waves section.
