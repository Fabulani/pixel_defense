# Enemies removed by the base get no death effect

- **Type:** polish
- **Priority:** low
- **Area:** enemies, VFX

`PlayerBase` frees enemies that reach it directly: no `died`, no burst, no fade (and, by design, no coins or split). Today the first hit loses the game, so this only shows in god mode, but it matters once the base has more than 1 hp. Add a separate "absorbed" effect path that pays nothing and spawns no children.
