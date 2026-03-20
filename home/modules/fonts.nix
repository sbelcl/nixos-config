{pkgs, ...}: {
  fonts.fontconfig = {
    enable = true;
    antialiasing = true;
    hinting = "slight";          # subtle hinting — preserves letterforms
    subpixelRendering = "rgb";   # standard LCD; change to "none" on OLED
    defaultFonts = {
      serif      = [ "Noto Serif"              "Noto Color Emoji" ];
      sansSerif  = [ "Inter"   "Noto Sans"     "Noto Color Emoji" ];
      monospace  = [ "JetBrainsMono Nerd Font" "Fira Code" "Noto Color Emoji" ];
      emoji      = [ "Noto Color Emoji" ];
    };
  };

  gtk = {
    enable = true;
    font = {
      name = "Inter";
      size = 11;
    };
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
    };
  };

  # Apply the same cursor in Wayland sessions
  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
  };

  home.packages = with pkgs; [
    # UI & system fonts
    inter                           # clean modern UI font
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    liberation_ttf
    # Monospace
    fira-code
    fira-code-symbols
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.hack
    nerd-fonts.iosevka
    nerd-fonts.noto                 # Noto with Nerd Font glyphs (good AGS fallback)
    # Decorative / specialty
    mplus-outline-fonts.githubRelease
    dina-font
    texlivePackages.cormorantgaramond
    cinzel
  ];
}
