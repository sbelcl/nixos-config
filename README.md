# NixOS Configuration — flanker & fulcrum

Personal multi-host NixOS configuration: one system flake, plus a **standalone**
Home Manager flake in [`home/`](home/).

A third machine, the work laptop *tomcat*, lives in a separate private repo.

For a much more detailed map of where things live, see [CLAUDE.md](CLAUDE.md).

## Hosts

| | fulcrum | flanker |
|---|---|---|
| Role | Gaming desktop | Laptop |
| GPU | NVIDIA RTX 3080 Ti | Hybrid NVIDIA + AMD |
| Desktop | Hyprland only | Hyprland only |
| Login | Auto-login on TTY1, hyprlock as the auth gate | Auto-login on TTY1, hyprlock as the auth gate |
| Storage | `/mnt/storage` (ext4 HDD, currently unplugged — SATA cable) | `/mnt/storage` over NFS from fulcrum, `/mnt/games` local |
| Extras | ComfyUI on CUDA, Ollama, NFS server, Gaming Mode via `steam-gamescope` | Battery alerts |

## Layout

Directory-level only — a file-by-file tree in a README rots faster than it helps.

```
.nixos/
├── flake.nix              # system flake — nixosConfigurations.{flanker,fulcrum}
├── hosts/<host>/          # host entry point + hardware
├── modules/
│   ├── settings/          # shared system settings (networking, audio, users, …)
│   └── software/          # shared system packages and services
└── home/                  # standalone Home Manager flake
    ├── flake.nix          # homeConfigurations."imnos@{flanker,fulcrum}"
    ├── hosts/<host>.nix   # per-host home overrides
    └── modules/
        ├── hyprland/      # compositor stack — imported by flanker only
        └── users/imnos.nix
```

## Usage

Both machines have shell aliases that fill in the right host:

```bash
updsys     # sudo nixos-rebuild switch --flake ~/.nixos#<host>
updhome    # home-manager switch --flake ~/.nixos/home#imnos@<host>
```

Written out, for when the aliases are not available (a fresh checkout, a TTY
rescue shell):

```bash
sudo nixos-rebuild switch --flake ~/.nixos#flanker
home-manager switch --flake ~/.nixos/home#imnos@flanker
# …or #fulcrum / #imnos@fulcrum
```

After pushing from one machine, `git pull` on the other before rebuilding.

## Checking before deploying

```bash
nix flake check --no-build                    # both flakes evaluate
nixos-rebuild build --flake ~/.nixos#fulcrum  # build another host without switching
home-manager build --flake ~/.nixos/home#imnos@flanker
```

Building the *other* host is worth the habit: an input bump can break a machine
you are not sitting at, and you will not find out until you go there. A weekly
timer ([`home/modules/nixos-update-check.nix`](home/modules/nixos-update-check.nix))
does this automatically on flanker — it resolves newer inputs in a throwaway copy
of the tree, so it never rewrites the lock files in place.

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
  `home/modules/`. The Hyprland stack is imported by flanker alone.
