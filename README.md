# Wallpapers

Wallpaper collection exposed as a Nix flake. Each folder is a collection;
every `png`/`jpg`/`jpeg` file one level deep becomes a store path and can be
used directly as a desktop background or as `stylix.image`.

## Layout

```
<collection>/<image>.{png,jpg,jpeg}
```

- exactly one level: `charlie-henson/GDWP-795-4K-No-Logo-Image-1.jpg`
- a collection may hold any number of images
- collection names: kebab-case, no spaces or special characters
- image file names: anything except `"` (it breaks attr/JSON names)
- empty collections are ignored
- no images in the repo root

## Usage as a flake input

```nix
inputs.wallpapers.url = "github:lukasgierth/wallpapers";
```

### Outputs

| Output | Content |
| --- | --- |
| `wallpapersTree` | store path of the whole repo |
| `wallpapers.<collection>.<file>` | derivation containing that one image |
| `wallpaperFiles` | `{ "<collection>" = [ "<file>" ... ]; }` |
| `wallpaperNames` | `[ "<collection>/<file>" ... ]` |
| `hmModules.wallpapers` | home-manager module installing the images |

Attribute names with dots need quoting:

```bash
nix build '.#wallpapers."charlie-henson"."GDWP-795-4K-No-Logo-Image-1.jpg"' --print-out-paths
```

### home-manager

```nix
{ inputs, ... }:
{
  imports = [ inputs.wallpapers.hmModules.wallpapers ];
  # optional: subset instead of all
  wallpapers.pick = [ "charlie-henson/GDWP-795-4K-No-Logo-Image-1.jpg" ];
}
```

This installs every selected image as

- `~/.local/share/backgrounds/<collection>-<file>` (GNOME background picker)
- `~/.local/share/wallpapers/<collection>-<stem>/` as a KDE Plasma wallpaper
  package (`metadata.json` + `contents/image.<ext>`)

The same module works on NixOS and non-NixOS systems with Nix + home-manager.

### Stylix

```nix
stylix.image = inputs.wallpapers.wallpapers."charlie-henson"."GDWP-795-4K-No-Logo-Image-1.jpg";
```

## Local checks

```bash
nix flake show
nix flake check
nix build '.#wallpapers."<collection>"."<file>"' --print-out-paths
nix flake update   # bump the nixpkgs pin
```

Nix only sees files that are tracked by git, so stage new images before
evaluating (`git add <collection>/...`). An empty folder cannot be committed
and disappears on clone.

See `PLAN.md` for the design decisions and open consumer-side work.
