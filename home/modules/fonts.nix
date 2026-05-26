{config, pkgs, ...}: {
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

  qt = {
    enable = true;
    platformTheme.name = "kde";
    style.name = "breeze";
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
    gtk4.theme = config.gtk.theme;
  };

  # Apply the same cursor in Wayland sessions
  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
  };

  # Force KDE/Qt apps (Dolphin, Okular, Ark…) to use the dark Breeze palette
  xdg.configFile."kdeglobals".text = ''
    [General]
    ColorScheme=BreezeDark

    [KDE]
    LookAndFeelPackage=org.kde.breezedark.desktop
  '';

  home.packages = with pkgs; [
    # Qt/KDE theming
    kdePackages.breeze
    kdePackages.breeze-icons
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
