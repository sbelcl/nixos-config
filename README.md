# NixOS Configuration — flanker

Personal NixOS configuration using flakes with standalone Home Manager.
Built around a Wayland-first setup using the [Niri](https://github.com/YaLTeR/niri) scrolling compositor.

## Hardware

- **CPU:** AMD
- **GPU:** NVIDIA (discrete) + AMD (integrated) — PRIME hybrid mode
- **Display:** Wayland

## Structure

```
.nixos/
├── flake.nix                  # System flake
├── flake.lock
├── hosts/
│   └── flanker/
│       ├── flanker.nix        # Host entry point
│       ├── hardware-configuration.nix
│       └── graphics.nix       # NVIDIA PRIME config
├── modules/
│   ├── settings/              # System-level settings
│   │   ├── audio.nix          # PipeWire
│   │   ├── bluetooth.nix
│   │   ├── env.nix            # System environment variables
│   │   ├── greetd.nix         # Display manager
│   │   ├── locales.nix
│   │   ├── maintenance.nix    # Nix store maintenance
│   │   ├── networking.nix
│   │   ├── power.nix
│   │   ├── printing.nix
│   │   ├── usb.nix
│   │   └── users.nix
│   └── software/              # System-level applications
│       ├── docker.nix
│       ├── niri.nix           # Compositor + XDG portals
│       ├── packages.nix
│       ├── steam.nix
│       └── thunar.nix
└── home/                      # Standalone Home Manager flake
    ├── flake.nix              # Home flake (follows system nixpkgs)
    ├── flake.lock
    ├── home.nix               # Home entry point
    └── modules/
        ├── fonts.nix
        ├── git.nix
        ├── neovim.nix
        ├── packages.nix
        ├── session-variables.nix
        ├── yandex.nix
        ├── niri/              # Compositor configuration
        │   ├── niri.nix       # Keybindings, layout
        │   ├── waybar.nix
        │   ├── swaylock.nix
        │   ├── wlogout.nix
        │   └── niri-eww.nix
        └── users/             # User-specific overrides
```

## Usage

### System update

```bash
sudo nixos-rebuild switch --flake ~/.nixos#flanker
```

Or using the alias:

```bash
updsys
```

### Home Manager update

```bash
home-manager switch --flake ~/.nixos/home#imnos
```

Or using the alias:

```bash
updhome
```

### Check before deploying

```bash
# Validate flake
nix flake check

# Build without activating
nixos-rebuild build --flake ~/.nixos#flanker

# Test in a VM
nixos-rebuild build-vm --flake ~/.nixos#flanker
./result/bin/run-nixos-vm
```

## Key Keybindings (Niri)

See [`home/modules/niri/niri.nix`](home/modules/niri/niri.nix) for the full list.

| Key | Action |
|-----|--------|
| `Super + Enter` | Terminal |
| `Super + Space` | Overview |
| `Super + Q` | Close window |
| `Super + D` | App launcher |

## Design Decisions

- **Separate flakes** — system and home are independent; `updsys` and `updhome` can be run separately to avoid breaking userspace when testing system changes.
- **Home flake follows system nixpkgs** — `nixpkgs.follows = "system-flake/nixpkgs"` ensures both use the same package set.
- **NVIDIA hybrid mode** — configured via `hardware.nvidia.mode = "hybrid"` in `graphics.nix`, easily switchable.
