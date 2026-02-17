# Pixel Defense

Tower defense with randomly generated maps every wave.

# Install

Download Git LFS: https://git-lfs.com/

Clone:

```sh
git clone git@github.com:Fabulani/pixel_defense.git
```

Initialize Git LFS and fetch assets:

```sh
git lfs install && git lfs fetch
```

# Notes

AI suggestion:
	
| Day | Objective | Concrete Tasks | Deliverable |
|-----|-----------|----------------|-------------|
| **Day 1** | Set up environment & learn basics | • Install Godot 4.x (stable).  • Complete the official *“Your First 2D Game”* tutorial (covers scenes, nodes, signals, input).  • Initialise a Git repository (README, .gitignore). | Working Godot project skeleton; confidence with nodes, scripts, and the editor. |
| **Day 2** | Core mechanics – tower placement & enemy pathing | • Create a **TileMap** grid (e.g., 16×9 cells).  • Script a **Tower** node (Area2D + CollisionShape2D) that can be placed with mouse click (snap to grid).  • Implement a simple **Enemy** node that follows a pre‑defined **Path2D** (start → end).  • Add a UI button “Start Wave”. | Player can place towers and launch a single wave of enemies that travel the path. |
| **Day 3** | Procedural map per wave (MVP) | • Write a deterministic **map generator**:   – Random walk from start to end, carving a path on the TileMap.   – Store tower positions before regeneration; after generating a new map, re‑instantiate towers at saved coordinates.  • Add a **WaveManager** that calls the generator at the beginning of each wave. | Map changes every wave while existing towers persist. |
| **Day 4** | Add second tower & second enemy type | • Duplicate Tower script → **RapidShooter** (higher fire rate, lower damage).  • Duplicate Enemy script → **FastEnemy** (higher speed, lower HP).  • Expose damage, fire‑rate, speed as exported variables for quick tuning. | Two distinct tower/enemy archetypes; basic balancing possible via inspector. |
| **Day 5** | Visual polish (minimalist) & feedback | • Replace placeholder rectangles with simple **ColorRect** or **Polygon2D** shapes (different colors per type).  • Attach **Particles2D** to tower shots (small burst) and enemy death (fade out).  • Add UI labels: *Gold*, *Health*, *Wave #*.  • Play a short sound effect on tower fire (use free .wav from freesound.org). | Game looks intentional despite minimal art; player receives clear feedback. |
| **Day 6** | Balancing, bug fixing, and save‑state | • Implement a basic **gold economy**: towers cost gold, enemies grant gold on death.  • Clamp player health; end game when health reaches zero.  • Test 5 consecutive waves; fix any crashes (common culprits: null references, tower placement after map regen).  • Add a simple **SaveData** script (writes current gold, wave, tower list to a JSON file). | Game runs for several waves, ends cleanly, and can reload last session. |
| **Day 7** | Final packaging & submission | • Export to **HTML5/WebGL** (compatible with itch.io).  • Create a concise README with controls, theme description, and jam link.  • Upload the zip and HTML build to the Brackeys 15 jam page. | Fully playable jam entry ready for judging. |
