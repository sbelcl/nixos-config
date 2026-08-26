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
│   │   ├── binds.nix              # every keybind, as data (see below)
│   │   ├── menu.nix               # action menu + cheatsheet, generated from binds.nix
│   │   ├── screenshot.nix         # satty annotate + OCR capture scripts
│   │   └── qol.nix                # reminders, notices, idle toggle, dictation
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
| Add Hyprland keybind | `home/modules/hyprland/binds.nix`, then regenerate the docs (flanker only) |
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
- Sunshine host (`services.sunshine`, port 47990 web UI) — stream the whole desktop to Moonlight on flanker. Pair once via https://localhost:47990. Steam Remote Play still covers Steam-only streaming.
- `gpu-screen-recorder` — NVENC replay buffer, installed via `programs.gpu-screen-recorder` so capture needs no portal prompt

### flanker (laptop)
- Hybrid NVIDIA+AMD · **Hyprland only** — auto-login on TTY1, no greeter, hyprlock as auth gate
- `/mnt/storage` — NFS mount from fulcrum (`192.168.43.152:/mnt/storage`)
- `/mnt/games` — local XFS NVMe
- Moonlight client for fulcrum's Sunshine host

### Both machines
- **Terminal**: Alacritty · **Files**: Dolphin (GUI), ranger (TUI, SUPER+R) · **Browser**: Yandex Browser (custom flake, GStreamer + Chrome 144 codecs)
- **Default apps** (declared in `home/modules/packages.nix` → `xdg.mimeApps`): images→Loupe, video/audio→mpv, archives→Ark, PDF→Okular, HTML→Yandex Browser, directories→Dolphin
  - ranger does **not** use these: it opens files with its own launcher, `rifle`, which ignores xdg-mime entirely. `home/modules/ranger.nix` routes images through `xdg-open` so they follow the table above; everything else uses rifle's packaged rules.
- **System QOL** (`modules/settings/maintenance.nix`): zram swap (50% of RAM), fwupd firmware updates, `locate` via plocate, and `nh` for rebuilds (`nh os switch`). `nh.clean` is off on purpose — it and the existing `nix.gc.automatic` both install a GC timer and the module asserts if both are on.
- **`command-not-found` / `,`**: `programs.nix-index` + comma, fed by the `nix-index-database` flake input (`home/flake.nix`) so nothing is indexed locally.

### flanker-only (Hyprland stack)
- **WM**: Hyprland · **Panel**: Wayle · **Lock**: hyprlock · **Launcher**: Rofi / fuzzel
- **Session services** (gated on `HYPRLAND_INSTANCE_SIGNATURE`): cliphist, polkit-gnome, udiskie, gammastep (the only gamma setter — hyprsunset was removed; `SUPER+CTRL+N` stops/starts the unit) — in `home/modules/hyprland/services.nix`; voxtype dictation daemon in `qol.nix`; battery alerts (`home/modules/battery.nix`) use the same gate
- **Theme sync**: matugen watches wallpaper changes via HyprPanel and rewrites Alacritty/Rofi/fuzzel/kdeglobals color files
- **Keybinds**: `home/modules/hyprland/binds.nix` — every bind is one entry in a list, and three things are rendered from it: the `hl.bind()` calls in `config.nix`, the `SUPER+ALT+SPACE` action menu and `SUPER+K` cheatsheet (`menu.nix`), and `docs/keybindings.md`. Nothing writes into `~/.nixos` at activation, so regenerate the doc by hand after editing:
    - `nix eval --raw -f home/modules/hyprland/binds.nix docsMarkdown > docs/keybindings.md`
    - The file is plain Nix (no module args, no `lib`) precisely so that command needs no build. `keys = null` makes a documentation-only row; `menu = false` keeps an exec entry out of the menu; `label` overrides the displayed key.
    - Only `exec` entries reach the menu — running "focus left" from a launcher that just took focus is meaningless.
  - `SUPER+ALT+SPACE` action menu · `SUPER+K` keybinding cheatsheet (floating Alacritty, class `cheatsheet`)
  - Capture: `Print` region→clipboard · `SHIFT+Print` region→satty→clipboard/`~/Slike/Screenshots` · `SUPER+Print` whole screen · `SUPER+CTRL+Print` OCR (`ocr-region`, tesseract `slv+eng`) · `SUPER+SHIFT+Print` colour picker
  - `SUPER+CTRL+R` set reminder (fuzzel prompt; `remind 7 tea is ready` from a shell does the same) · `+ALT` list · `+SHIFT` clear
  - `SUPER+CTRL+ALT+T/B/W` time / battery / weather notice · `SUPER+CTRL+I` toggle idle inhibit · `SUPER+CTRL+N` toggle night light
  - Fullscreen family: `SUPER+F` real fullscreen · `SUPER+ALT+F` maximized (keeps gaps/bar) · `SUPER+CTRL+F` fake fullscreen (client told it's fullscreen, window unmoved)
  - Arrow family, modifier = how much moves: `SUPER+arrow` focus · `SUPER+SHIFT+arrow` move window · `SUPER+CTRL+←/→` move the whole column (`swapcol`, scrolling-only, wraps)
  - `SUPER+SHIFT+F` toggle floating · `SUPER+ALT+L` switch layout scrolling↔dwindle (`layout-toggle`). Not `SUPER+L` — that's hyprlock.
    - `hyprctl keyword` **does not work** with the Lua config ("can't work with non-legacy parsers"); runtime config changes go through `hyprctl eval 'hl.config{...}'`.
    - Same trap in `hyprctl dispatch`: it wraps its argument as `return hl.dispatch(<arg>)` and evaluates it, so `hyprctl dispatch exec foo` is a Lua syntax error. Spell it `hyprctl dispatch 'hl.dsp.exec_cmd([[foo]])'` (what `menu.nix` does).
    - Workspace 2 pins `layout = "dwindle"` in its workspace_rule, and a per-workspace rule outranks `general:layout`, so the toggle is a no-op there.
    - Unlike bind *options*, dispatcher table args (`mode`, `action`) **are** validated by `--verify-config` — an invalid mode is rejected loudly.
  - `SUPER+CTRL+X` toggle dictation · `F9` hold-to-talk. Needs a one-time `voxtype setup --download` (~1 GB model, runtime state not Nix).
  - Hyprland's Lua `hl.bind` takes options as a 3rd table arg (`{ release = true }` = hyprlang's `bindr`). **`Hyprland --verify-config` does not validate these keys** — a typo passes as "config ok" and is silently ignored.
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
