#
# ~/.nixos/home/modules/settings/users/imnos.nix
#
{
  pkgs,
  ...
}: {
  programs.fzf = {
    enable = true;
    enableZshIntegration = true; # Ctrl+R history, Ctrl+T file, Alt+C dir
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    autocd = true;
    syntaxHighlighting.enable = true;
    initContent = ''
      eval "$(starship init zsh)"

      # Auto-start Hyprland on TTY1 (flanker auto-login)
      if [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
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
