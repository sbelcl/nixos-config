#
# ~/.nixos/home/modules/settings/users/imnos.nix
#
{
  config,
  pkgs,
  ...
}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    autocd = true;
    syntaxHighlighting.enable = true;
    initContent = ''eval "$(starship init zsh)"'';
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
        style = "cyan";
      };
      git_branch = {
        symbol = "🌱 ";
        style = "bold purple";
      };
      git_status = {
        style = "red";
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
    # po želji še:
    # publicShare = "$HOME/Javno";
    # templates   = "$HOME/Predloge";
  };

  # (ni nujno) Če želiš imeti tudi orodje na voljo:
  home.packages = [pkgs.xdg-user-dirs];
}
