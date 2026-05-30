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

  # Force KDE/Qt apps (Dolphin, Okular, Ark…) to use the Binary Red palette
  xdg.configFile."kdeglobals".text = ''
    [General]
    ColorScheme=BinaryRed

    [KDE]
    LookAndFeelPackage=org.kde.breezedark.desktop

    [Colors:Window]
    BackgroundNormal=26,10,10
    ForegroundNormal=232,213,213
    BackgroundAlternate=42,18,21
    ForegroundInactive=136,112,112
    DecorationFocus=196,84,84
    DecorationHover=212,121,122

    [Colors:View]
    BackgroundNormal=26,10,10
    BackgroundAlternate=42,18,21
    ForegroundNormal=232,213,213
    ForegroundInactive=136,112,112
    DecorationFocus=196,84,84
    DecorationHover=212,121,122

    [Colors:Button]
    BackgroundNormal=42,18,21
    ForegroundNormal=232,213,213
    DecorationFocus=196,84,84
    DecorationHover=212,121,122

    [Colors:Selection]
    BackgroundNormal=196,84,84
    ForegroundNormal=26,10,10
    BackgroundAlternate=212,121,122

    [Colors:Tooltip]
    BackgroundNormal=42,18,21
    ForegroundNormal=232,213,213

    [Colors:Complementary]
    BackgroundNormal=26,10,10
    ForegroundNormal=232,213,213

    [Colors:Header]
    BackgroundNormal=26,10,10
    ForegroundNormal=232,213,213

    [WM]
    activeBackground=26,10,10
    activeForeground=232,213,213
    inactiveBackground=26,10,10
    inactiveForeground=136,112,112
    activeBlend=196,84,84
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
