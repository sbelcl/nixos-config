# STALKER GAMMA on NixOS — Installation Guide

> Tested on: NixOS unstable, NVIDIA RTX 3080 Ti, Ryzen 9 5900X, NTFS game drive

## Overview

STALKER GAMMA is a massive modpack for STALKER Anomaly. Most Linux guides use
Flatpak + Bottles. This guide goes the NixOS-native route: `nix shell` +
Lutris + GE-Proton, no Flatpak required.

The install has three phases:
1. **gamma-launcher** — downloads Anomaly + all GAMMA mods and assembles them (native Linux)
2. **Wine prefix** — set up via Lutris with GE-Proton + winetricks DLLs
3. **Mod Organizer 2 (MO2)** — Windows mod manager that launches the game

Total disk space needed: ~200 GB.

---

## Prerequisites

### NixOS system packages

Add to `hosts/<hostname>/fulcrum.nix` (or wherever your system packages live):

```nix
environment.systemPackages = with pkgs; [
  lutris
  protonup-qt
  wine
  winetricks
  unrar   # required by gamma-launcher — unfree, needs allowUnfree = true
];
```

`unrar` is unfree. Make sure `nixpkgs.config.allowUnfree = true` is set in your
host config, or use `NIXPKGS_ALLOW_UNFREE=1` when running `nix shell` commands.

### NTFS game drive (optional but recommended)

If your game drive is NTFS, add the `acl` mount option so Wine can handle
permissions correctly:

```nix
fileSystems."/mnt/games" = {
  device = "/dev/disk/by-uuid/<your-uuid>";
  fsType = "ntfs3";
  options = [
    "uid=1000"
    "gid=100"
    "umask=0022"
    "acl"                   # required for Wine/MO2 to work on NTFS
    "nofail"
    "x-systemd.automount"
  ];
};
```

Apply with `sudo nixos-rebuild switch --flake ~/.nixos#<hostname>`.

---

## Phase 1: Download GAMMA with gamma-launcher

### 1.1 Prepare directories and environment

```bash
mkdir -p /mnt/games/STALKER-GAMMA /mnt/games/gammatmp
export TMPDIR=/mnt/games/gammatmp   # /tmp (tmpfs) is too small — needs ~12 GB
export UNRAR_LIB_PATH=$(nix-build '<nixpkgs>' -A unrar --no-out-link)/lib/libunrar.so
```

### 1.2 Clone and install gamma-launcher

```bash
nix shell nixpkgs#python3 nixpkgs#git nixpkgs#unrar --extra-experimental-features 'nix-command flakes'

git clone https://github.com/Mord3rca/gamma-launcher
cd gamma-launcher
python -m venv venv && source venv/bin/activate
pip install .
```

### 1.3 Run the download

```bash
gamma-launcher full-install \
  --anomaly /mnt/games/STALKER-GAMMA/Anomaly \
  --gamma   /mnt/games/STALKER-GAMMA/GAMMA \
  --cache-directory /mnt/games/gammatmp/cache
```

This downloads ~100 GB from ModDB and takes a long time depending on your
connection. Leave it running.

---

## Phase 2: Wine prefix via Lutris

### 2.1 Install GE-Proton

Open **protonup-qt**:
- Create the Lutris runners folder first if it doesn't exist:
  ```bash
  mkdir -p ~/.local/share/lutris/runners/wine
  ```
- In protonup-qt: set folder to `~/.local/share/lutris/runners/wine`, launcher
  to **Lutris**, download **GE-Proton9-20**.

### 2.2 Create a Wine prefix

The prefix **must** be on an ext4 (Linux) filesystem — NTFS will hang
indefinitely during Wine prefix creation.

```bash
mkdir -p ~/.local/share/lutris/prefixes/stalker-gamma
```

### 2.3 Install DLL dependencies via winetricks

```bash
WINEPREFIX=~/.local/share/lutris/prefixes/stalker-gamma \
winetricks cmd d3dx9 dx8vb \
  d3dcompiler_42 d3dcompiler_43 d3dcompiler_46 d3dcompiler_47 \
  d3dx10_43 d3dx10 d3dx11_42 d3dx11_43 \
  dxvk quartz
```

Or use Lutris GUI: right-click the game → **Winetricks**.

### 2.4 Add STALKER GAMMA to Lutris

In Lutris, click **+** → **Add game manually**:

| Setting | Value |
|---------|-------|
| Name | STALKER GAMMA |
| Runner | Wine |
| Executable | `/mnt/games/STALKER-GAMMA/GAMMA/ModOrganizer.exe` |
| Wine version | `GE-Proton9-20` |
| Wine prefix | `~/.local/share/lutris/prefixes/stalker-gamma` |
| Prefix architecture | 64-bit |

---

## Phase 3: Mod Organizer 2 setup

### 3.1 First launch

Launch the game from Lutris. MO2 will open and ask for the game path. Point it
to:
```
/mnt/games/STALKER-GAMMA/Anomaly
```

### 3.2 Fix MO2 deployment method (critical on Linux/NTFS)

MO2's default USVFS virtual filesystem fails on Wine + NTFS with:
```
Error 87 ERROR_INVALID_PARAMETER — GetEffectiveRightsFromAclW()
```

Fix: **MO2 → Settings → Workarounds → Mod Deployment Method → Symlinks**

### 3.3 Launch the game

In the MO2 executable dropdown (top right), select:
- **AnomalyDX11AVX.exe** — if your CPU supports AVX (Ryzen 5000 series does)
- **AnomalyDX11.exe** — otherwise

Hit **Run**.

---

## Known issues and fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| Wine prefix creation hangs | NTFS doesn't support Unix file ops | Put prefix on ext4 (`~/.local/share/...`) |
| `libunrar.so` not found | Nix store not in venv PATH | Set `UNRAR_LIB_PATH` env var |
| `TMPDIR` too small | `/tmp` is tmpfs sized to RAM | `export TMPDIR=/mnt/games/gammatmp` |
| Python venv fails | Non-FHS environment | Run inside `nix shell nixpkgs#python3` |
| MO2 ERROR_INVALID_PARAMETER | USVFS ACL check fails on NTFS | Change deployment to Symlinks in MO2 settings |
| `gamemodeauto: dlopen failed` | GameMode lib not in standard path | Harmless warning, game runs fine |

---

## Notes

- The `gamemodeauto` warning is harmless — ncnn/Vulkan still uses the GPU fully.
- GAMMA is ~200 GB. The Games drive was 91% full at install time — watch disk space.
- MO2 maps the drive as `W:\` — this is expected.
