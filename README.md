# Pixel Defense

Tower defense with randomly generated maps every wave.

![Pixel Defense gameplay with towers shooting incoming enemies](docs/img/screenshot.png)

# Install

Clone:

```sh
git clone git@github.com:Fabulani/pixel_defense.git
```

Then open the project in Godot.

## Assets

Download [Git LFS](https://git-lfs.com/) and, in the project folder, initialize and pull the assets:

```sh
git lfs install && git lfs pull
```

Alternatively download from Kenney (<www.kenney.nl>) and extract them in the asset folder:
- Pixel Shmup
- Kenney Fonts
- Input Prompts Pixel 16×

# Structure

The project is organized as follows:

```
core/            # core mechanics and features
docs/            # documentation
entities/        # game-domain elements
levels/          # tileset maps and wave data
main/            # game entrypoint
ui/              # everything ui related
```

# Gallery

![Game Over screen](docs/img/game_over.png)

# Thanks

Some helpful resources helped me get this game up and running:
- CoffeeCrow
	- [How To Create A Tower Defence Game In Godot!](https://youtube.com/playlist?list=PLhBqFleCVBkUo2ZFIZcFRBB4HMv7JjPWG&si=Asag0uhvkSEXF2If)
- Zenva
	- [TOWER DEFENSE in Godot - Complete Mini-Course](https://youtu.be/qZp00LxXjWA)
- Godotneers
	- [Godot UI Basics - how to build beautiful interfaces that work everywhere (Beginners)](https://youtu.be/1_OFJLyqlXI) 
	- [Data models - using data to create extensible, maintainable games in Godot](https://youtu.be/4vAkTHeoORk)
- dandeliondino
	- [godot-4-tileset-terrains-docs](https://github.com/dandeliondino/godot-4-tileset-terrains-docs)
- Overshot Productions
	- [Safe Area Dynamic Margins Setup in Godot 4: Mobile Device Orientation Tutorial](https://youtu.be/MeURXJij6PA)
- Bramwell
	- [Drag Camera: Godot Guide](https://youtu.be/gpvLqLggJuk)
- FinePointCGI
	- [Creating a Flexible Touch Screen Camera Controller In Godot | Basics With Godot](https://youtu.be/vnAkooGCLDA)
- thygrrr
	- [Godot Zoom and Pan, smooth & cursor-centric Camera2D motion](https://gist.github.com/thygrrr/8288cabeb5cd25031ce6132c4a886311)
- DevDuck
	- [How I Organize My 10k+ Line Godot Project!](https://youtu.be/4az0VX9ApcA)
- Oskar Dudycz
	- [My thoughts on Vertical Slices, CQRS, Semantic Diffusion and other fancy words](https://www.architecture-weekly.com/p/my-thoughts-on-vertical-slices-cqrs)