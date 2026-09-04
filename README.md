# NixOS Configuration — flanker

Personal NixOS configuration: one system flake, plus a **standalone**
Home Manager flake in [`home/`](home/).

The work laptop *tomcat* lives in a separate private repo. The desktop
*fulcrum* was configured here until it was reinstalled with Arch; its host
files were removed — the git history still has them if it ever comes back.

For a much more detailed map of where things live, see [CLAUDE.md](CLAUDE.md).

## Host

| | flanker |
|---|---|
| Role | Laptop |
| GPU | Hybrid NVIDIA + AMD |
| Desktop | Hyprland only |
| Login | Auto-login on TTY1, hyprlock as the auth gate |
| Storage | `/mnt/storage` over NFS from the desktop at 192.168.43.152, `/mnt/games` local |
| Extras | Battery alerts, wallpaper→theme sync |

The modules stay host-agnostic where it costs nothing — hardware-shaped choices
live in the host file, the Hyprland stack is an explicit import — so adding a
machine back is a matter of writing a host file, not untangling flanker's
assumptions from the shared ones.

## Layout

Directory-level only — a file-by-file tree in a README rots faster than it helps.

```
.nixos/
├── flake.nix              # system flake — nixosConfigurations.flanker
├── hosts/<host>/          # host entry point + hardware
├── modules/
│   ├── settings/          # shared system settings (networking, audio, users, …)
│   └── software/          # shared system packages and services
└── home/                  # standalone Home Manager flake
    ├── flake.nix          # homeConfigurations."imnos@flanker"
    ├── hosts/<host>.nix   # per-host home overrides
    └── modules/
        ├── hyprland/      # compositor stack — imported by the host file
        └── users/imnos.nix
```

## Usage

Shell aliases fill in the host:

```bash
updsys     # sudo nixos-rebuild switch --flake ~/.nixos#<host>
updhome    # home-manager switch --flake ~/.nixos/home#imnos@<host>
```

Written out, for when the aliases are not available (a fresh checkout, a TTY
rescue shell):

```bash
sudo nixos-rebuild switch --flake ~/.nixos#flanker
home-manager switch --flake ~/.nixos/home#imnos@flanker
```

## Checking before deploying

```bash
nix flake check --no-build                       # root flake — the NixOS system
nix flake check ./home --no-build                # home flake — the homeConfiguration
nixos-rebuild build --flake ~/.nixos#flanker     # build without switching
home-manager build --flake ~/.nixos/home#imnos@flanker
```

The second line is not redundant. `home/` is its own flake and the root check
never descends into it, so a root-only check says nothing about the home
configuration. It is also only meaningful because `home/flake.nix` re-exports
the activation package as `checks`: `homeConfigurations` is not a schema
`nix flake check` recognises, so without that it reports an unknown output and
forces nothing.

To validate the working tree rather than the last commit, ask for the path
explicitly — a flake reference in a Git repository resolves to `HEAD`, silently
ignoring uncommitted edits:

```bash
nix flake check path:$PWD --no-build
```

A weekly timer ([`home/modules/nixos-update-check.nix`](home/modules/nixos-update-check.nix))
does this automatically — it resolves newer inputs in a throwaway copy of the
tree, so it never rewrites the lock files in place. It iterates over whatever
hosts the flakes declare, so a second machine would be covered without editing
it.

Note that a passing evaluation says nothing about *runtime* config: Hyprland Lua,
Wayle TOML, matugen templates and rofi themes are all opaque to Nix. Several have
been accepted happily and then silently ignored at runtime.

## Design decisions

- **Two independent flakes.** `updsys` and `updhome` can be run separately, so a
  system change under test cannot take userspace down with it.
- **They do *not* follow each other.** `home/flake.nix` tracks its own
  `nixos-unstable`. The revisions currently match by coincidence, not by
  construction — update them together, or expect drift.
- **Hyprland uses the Lua config format**, not hyprlang, which is removed in
  Hyprland 0.57. See [`home/modules/hyprland/config.nix`](home/modules/hyprland/config.nix).
- **Colours come from the wallpaper.** matugen regenerates Alacritty, rofi,
  fuzzel, hyprlock and kdeglobals palettes; `wallpaper-next` (SUPER+SHIFT+W)
  drives it.
- **Host-specific policy lives in host files**, shared policy in `modules/` and
  `home/modules/`. The Hyprland stack is an explicit import, not a default.
