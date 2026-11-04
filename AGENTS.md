# AGENTS.md

Wallpaper repo: images plus a flake exposing them to home-manager consumers.
See `README.md` for the output contract and `PLAN.md` (gitignored, local) for
design/open tasks.

## Layout rules

- `<collection>/<image>.{png,jpg,jpeg}` — exactly one level deep.
- Multiple images per collection are fine; subdirectories are ignored.
- Collection names: kebab-case, ASCII, no spaces.
- Image file names must not contain `"`.
- No images in the repo root. Empty collections are skipped.

## Commands

```bash
nix flake show
nix flake check
nix build '.#wallpapers."<collection>"."<file>"' --print-out-paths
nix flake update
```

Linting is configured in `.pre-commit-config.yaml` (yamllint `--strict`,
end-of-file-fixer, trailing-whitespace, conventional commit messages):
`pre-commit run --all-files`.

## Gotchas

- Nix 2.34 only reads git-tracked files: `git add` new images before
  `nix build` / `nix flake show`, otherwise outputs are missing silently.
- Attribute names contain dots, so quote each segment on the CLI.
- Store names are sanitized to `[A-Za-z0-9._+-]`; install names keep the
  original file name.
- The `runCommand` wrappers use `nixpkgs.legacyPackages.x86_64-linux`; the
  image contents are platform-independent, the derivations are not.
- `flake.lock` is generated — edit it only via `nix flake update`.
- `lib.removeExt` and `lib.sanitizeDerivationName` do not exist in current
  nixpkgs lib.
- Do not use `lib.listToAttrs` for `home.file` here; it failed at eval.
  The module uses `builtins.foldl'` + `//`.

## Git

- Never commit or push without explicit approval.
- Staging (`git add`) is required for flake evaluation and allowed.
- Commits follow conventional commits.
