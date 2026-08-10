# NixOS Config — Claude Context

Multi-host NixOS flake for imnos. Two machines in this repo: **fulcrum** (desktop) and **flanker** (laptop). Work laptop **tomcat** lives in a separate private repo (`sbelcl/nixos-tomcat`).

## Repo Layout

```
~/.nixos/                          ← system flake
├── hosts/
│   ├── fulcrum/fulcrum.nix        # Gaming desktop — RTX 3080 Ti, KDE Plasma only
│   └── flanker/flanker.nix        # Laptop — hybrid NVIDIA+AMD, Hyprland only
└── modules/
    ├── software/                  # Shared system packages/services
    └── settings/                  # Shared settings (networking, printing, etc.)

~/.nixos/home/                     ← home-manager flake
├── modules/
│   ├── default.nix                # Shared home modules (DE/WM-agnostic)
│   ├── packages.nix               # User packages + MIME associations
│   ├── hyprland/                  # Hyprland stack — flanker-only import
│   ├── rofi.nix                   # App launcher — flanker-only (Plasma uses KRunner)
│   ├── fuzzel.nix                 # Wayland launcher — flanker-only
│   ├── battery.nix                # UPower alerts — flanker-only (laptop)
│   ├── matugen.nix                # Wallpaper→theme sync — flanker-only (HyprPanel trigger)
│   ├── dolphin.nix                # File manager + thumbnails (shared)
│   └── alacritty.nix              # Terminal (shared)
└── hosts/
    ├── fulcrum.nix                # Fulcrum-specific home overrides
    └── flanker.nix                # Flanker home + imports the flanker-only modules
```

## Apply Changes

| Command | What it does |
|---|---|
| `updsys` | `sudo nixos-rebuild switch --flake ~/.nixos#<hostname>` |
| `updhome` | `home-manager switch --flake ~/.nixos/home#imnos@<hostname>` |

Always `git pull` on the other machine after pushing changes.

## Where Does a Change Go?

| Task | File |
|---|---|
| Add user package | `home/modules/packages.nix` → `home.packages` |
| Add system package | `hosts/<host>/<host>.nix` → `environment.systemPackages` |
| Enable a system service | `hosts/<host>/<host>.nix` → `services.*` |
| Configure a dotfile | `home/modules/<app>.nix` |
| Add Hyprland keybind | `home/modules/hyprland/config.nix` (flanker only) |
| Add MIME association | `home/modules/packages.nix` → `xdg.mimeApps.defaultApplications` |
| Shared across both machines | `modules/` (system) or `home/modules/` (home) |
| Host-specific | `hosts/<host>/` or `home/hosts/<host>.nix` |

## Key Facts

### fulcrum (desktop)
- RTX 3080 Ti · KDE Plasma (Wayland) **only** — gaming rig with gamescope "Gaming Mode" SDDM session (HDR/VRR path). No Hyprland/Xmonad/Niri here.
- `/mnt/storage` — ext4 HDD, automounted
- `/mnt/games` — XFS NVMe, automounted
- ComfyUI at `http://127.0.0.1:8188` (CUDA, models in `/mnt/storage/comfyui/`)
- NFS server — exports `/mnt/storage` to `192.168.43.0/24`

### flanker (laptop)
- Hybrid NVIDIA+AMD · **Hyprland only** — auto-login on TTY1, no greeter, hyprlock as auth gate
- `/mnt/storage` — NFS mount from fulcrum (`192.168.43.152:/mnt/storage`)
- `/mnt/games` — local XFS NVMe

### Both machines
- **Terminal**: Alacritty · **Files**: Dolphin · **Browser**: Yandex Browser (custom flake, GStreamer + Chrome 144 codecs)
- **Default apps**: images→qview, video/audio→VLC, archives→Ark, PDF→Firefox

### flanker-only (Hyprland stack)
- **WM**: Hyprland · **Panel**: Wayle · **Lock**: hyprlock · **Launcher**: Rofi / fuzzel
- **Session services** (gated on `HYPRLAND_INSTANCE_SIGNATURE`): cliphist, polkit-gnome, udiskie, gammastep — in `home/modules/hyprland/services.nix`; battery alerts (`home/modules/battery.nix`) use the same gate
- **Theme sync**: matugen watches wallpaper changes via HyprPanel and rewrites Alacritty/Rofi/fuzzel/kdeglobals color files
- **Keybinds**: `home/modules/hyprland/config.nix`
- **Imports** (in `home/hosts/flanker.nix`): `hyprland/hyprland.nix`, `rofi.nix`, `fuzzel.nix`, `battery.nix`, `matugen.nix`

## Debugging

| Error | Fix |
|---|---|
| Package not found | `nix search nixpkgs <name>` — check attribute path |
| Option does not exist | Read full path in error → search.nixos.org/options |
| home-manager file conflict | `home-manager switch -b backup` (backs up conflicting file to `.backup`) |
| Service fails | `systemctl status <svc>` · `journalctl -u <svc> -n 50` |
| Hash/dependency error | `nix flake update` |
| Git push fails | `gh auth login` then `git push` |
