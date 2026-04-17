# NixOS Config — Claude Context

Multi-host NixOS flake for imnos. Two machines: **fulcrum** (desktop) and **flanker** (laptop).

## Repo Layout

```
~/.nixos/                          ← system flake
├── hosts/
│   ├── fulcrum/fulcrum.nix        # Gaming desktop — RTX 3080 Ti, KDE Plasma + Niri
│   └── flanker/flanker.nix        # Laptop — hybrid NVIDIA+AMD, Niri WM only
└── modules/
    ├── software/                  # Shared system packages/services
    └── settings/                  # Shared settings (networking, printing, etc.)

~/.nixos/home/                     ← home-manager flake
├── modules/
│   ├── default.nix                # Imports all shared home modules
│   ├── packages.nix               # User packages + MIME associations
│   ├── niri/niri.nix              # Niri WM — keybinds, window rules, services
│   ├── dolphin.nix                # File manager + thumbnails
│   ├── vibepanel.nix              # Status bar (AGS/vibepanel)
│   ├── alacritty.nix              # Terminal
│   └── rofi.nix                   # App launcher
└── hosts/
    ├── fulcrum.nix                # Fulcrum-specific home overrides
    └── flanker.nix                # Flanker-specific home overrides
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
| Add Niri keybind | `home/modules/niri/niri.nix` → `binds {}` |
| Add MIME association | `home/modules/packages.nix` → `xdg.mimeApps.defaultApplications` |
| Shared across both machines | `modules/` (system) or `home/modules/` (home) |
| Host-specific | `hosts/<host>/` or `home/hosts/<host>.nix` |

## Key Facts

### fulcrum (desktop)
- RTX 3080 Ti · KDE Plasma + Niri (selectable at login)
- `/mnt/storage` — ext4 HDD, automounted
- `/mnt/games` — XFS NVMe, automounted
- ComfyUI at `http://127.0.0.1:8188` (CUDA, models in `/mnt/storage/comfyui/`)
- NFS server — exports `/mnt/storage` to `192.168.43.0/24`

### flanker (laptop)
- Hybrid NVIDIA+AMD · Niri WM only
- `/mnt/storage` — NFS mount from fulcrum (`192.168.43.152:/mnt/storage`)
- `/mnt/games` — local XFS NVMe

### Both machines
- **WM**: Niri · **Panel**: vibepanel · **Terminal**: Alacritty (`Mod+T`) · **Launcher**: Rofi (`Super+Space`) · **Files**: Dolphin (`Mod+E`)
- **Browser**: Yandex Browser (custom flake, GStreamer + Chrome 144 codecs)
- **Default apps**: images→qview, video/audio→VLC, archives→Ark, PDF→Firefox

## Debugging

| Error | Fix |
|---|---|
| Package not found | `nix search nixpkgs <name>` — check attribute path |
| Option does not exist | Read full path in error → search.nixos.org/options |
| home-manager file conflict | `rm ~/.file.backup && updhome` |
| Service fails | `systemctl status <svc>` · `journalctl -u <svc> -n 50` |
| Hash/dependency error | `nix flake update` |
| Git push fails | `gh auth login` then `git push` |
