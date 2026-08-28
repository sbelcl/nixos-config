#
# ~/.nixos/home/modules/settings/users/imnos.nix
#
{
  pkgs,
  inputs,
  ...
}: {
  imports = [inputs.nix-index-database.homeModules.nix-index];

  # Typing a command that isn't installed prints which package provides it,
  # and `, <cmd>` runs it once from that package without installing anything.
  #
  # This replaces NixOS's own command-not-found handler, which reads a
  # database shipped with nix-channels — a flakes-only system never populates
  # it, so the handler can only ever say "not found".
  #
  # The database comes from the nix-index-database flake input, so nothing is
  # indexed locally; see home/flake.nix.
  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.nix-index-database.comma.enable = true;

  programs.fzf = {
    enable = true;
    enableZshIntegration = true; # Ctrl+R history, Ctrl+T file, Alt+C dir
  };

  # `z <partial-dir>` jumps to the best-matching directory you have actually
  # visited, scored by frequency and recency. autocd (below) already turns a
  # bare path into a cd, so this only earns its place for the fuzzy case.
  #
  # The zsh hook shadows `cd` itself, which is why this is here rather than in
  # home.packages — the binary alone changes nothing.
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # Per-directory environments: cd into a dir with .envrc and its exports are
  # loaded, unloaded again on leaving. Home-manager rather than system, because
  # direnv is only useful through its shell hook and ~/.zshrc is generated here.
  #
  # nix-direnv replaces direnv's own `use nix`/`use flake` with versions that
  # cache the evaluated dev shell in .direnv/ and register it as a GC root, so
  # entering a project doesn't re-evaluate the flake and the weekly nix.gc
  # (modules/settings/maintenance.nix) doesn't collect it out from under you.
  #
  # An .envrc must be approved once with `direnv allow` before it runs — that
  # approval is per-path user state in ~/.local/share/direnv, not in this repo.
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    autocd = true;
    syntaxHighlighting.enable = true;
    initContent = ''
      eval "$(starship init zsh)"

      # Auto-start Hyprland on TTY1 (auto-login hosts). start-hyprland is
      # defined in modules/software/hyprland.nix behind desktop.hyprland.enable,
      # so the command check is what scopes this shared snippet to the hosts
      # that actually run it -- there is no host condition available here.
      # The check is load-bearing, not defensive: zsh does not survive an exec
      # of a missing command even when interactive, so on an auto-login TTY a
      # bare `exec` of an absent binary means the shell dies and getty
      # respawns it, forever.
      if [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ] \
         && command -v start-hyprland >/dev/null; then
        exec start-hyprland
      fi
    '';
    setOptions = [
      "APPEND_HISTORY"
      "HIST_IGNORE_ALL_DUPS"
    ];

    shellAliases = {
      l = "eza -l --icons=auto";
      la = "eza -la --icons=auto";
      ls = "eza --icons=auto";
      lt = "eza -T --icons=auto";
      lta = "eza -laT --icons=auto";
      cat = "bat";
      ".." = "cd ..";
      # updsys and updhome are set per-host in home/hosts/<hostname>.nix
    };
    history.size = 10000;
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };
      directory = {
        style = "bold #d4797a";
      };
      git_branch = {
        symbol = "🌱 ";
        style = "bold #c45454";
      };
      git_status = {
        style = "#ff4444";
      };
    };
  };

  # XDG uporabniške mape prek Home-Managerja
  xdg.userDirs = {
    enable = true;
    createDirectories = true;

    desktop = "$HOME/Namizje";
    documents = "$HOME/Dokumenti";
    download = "$HOME/Prenosi";
    music = "$HOME/Glasba";
    pictures = "$HOME/Slike";
    videos = "$HOME/Videi";
    publicShare = "$HOME/Javno";
    templates = "$HOME/Predloge";
    projects = "$HOME/Projekti";
  };

  # (ni nujno) Če želiš imeti tudi orodje na voljo:
  home.packages = [pkgs.xdg-user-dirs];
}
