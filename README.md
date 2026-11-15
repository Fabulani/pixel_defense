# Pixel Defense

Tower defense with randomly generated maps every wave.

![Pixel Defense gameplay with towers shooting incoming enemies](docs/img/screenshot.png)

# Play / Download

- [Play in the browser](https://fabulani.github.io/pixel_defense/)
- Windows, Linux and Android builds are on the [Releases page](https://github.com/Fabulani/pixel_defense/releases) (`SHA256SUMS.txt` included).

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

Alternatively download from Kenney (<www.kenney.nl>) and extract them next to the scenes that use them, in their feature folders (e.g. `entities/`, `ui/`):
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

# Releasing

Releases are built by GitHub Actions (`.github/workflows/release.yml`) when a `vMAJOR.MINOR.PATCH` tag on `main` is pushed:

```sh
git switch main && git pull
git tag v0.1.0 && git push origin v0.1.0
```

The workflow exports Windows, Linux, Android and Web, creates the GitHub release (notes are generated from the merged PRs since the previous tag) and deploys the web build to GitHub Pages. Tags not on `main` or not of the form `v1.2.3` are rejected; the first release must be at least `v0.0.1`. The "play in the browser" link in the release notes works only after the first release has deployed Pages.

## One-time setup

Run once, with admin rights on the repo (needs `gh auth login`).

1. Enable GitHub Pages with the "GitHub Actions" source (or Settings > Pages > Source: GitHub Actions):

   ```sh
   gh api -X POST repos/Fabulani/pixel_defense/pages -f build_type=workflow
   ```

2. Allow tags to deploy to the `github-pages` environment. By default only `main` may, and a tag-triggered run fails with "Tag ... is not allowed to deploy to github-pages due to environment protection rules". The environment exists only after step 1. (UI: Settings > Environments > github-pages > Deployment branches and tags > add rule, type Tag, pattern `v[0-9]*`.)

   ```sh
   # make sure the environment uses custom branch/tag rules (keeps the existing `main` rule)
   gh api repos/Fabulani/pixel_defense/environments/github-pages/deployment-branch-policies
   # if that returns 404, run first:
   # gh api -X PUT repos/Fabulani/pixel_defense/environments/github-pages \
   #   -F 'deployment_branch_policy[protected_branches]=false' -F 'deployment_branch_policy[custom_branch_policies]=true'
   gh api -X POST repos/Fabulani/pixel_defense/environments/github-pages/deployment-branch-policies \
     -f name='v[0-9]*' -f type=tag
   ```

3. Create the Android release keystore and store it as secrets. Back the keystore up somewhere safe (losing it means players cannot update the app) and never commit it (`*.keystore` and `*.jks` are git-ignored).

   ```sh
   keytool -genkeypair -v -keystore release.keystore -alias pixel_defense \
     -keyalg RSA -keysize 2048 -validity 10000
   gh secret set ANDROID_KEYSTORE_BASE64 < <(base64 -w0 release.keystore)
   gh secret set ANDROID_KEYSTORE_USER --body pixel_defense   # the alias
   gh secret set ANDROID_KEYSTORE_PASSWORD                    # prompts; use the keystore password
   ```

   The key password must equal the keystore password (the Godot export takes one password).

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
- Daniel Bologna & Federico Belluci
	- [Godot Signals Architecture: Best Practices & Event Bus [2026 Guide]](https://blog.febucci.com/2024/12/godot-signals-architecture/)
