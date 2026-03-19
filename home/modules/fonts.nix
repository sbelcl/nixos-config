{pkgs, ...}: {
  fonts.fontconfig.enable = true;

  # Enables GTK config management and keeps the icon cache up to date
  gtk.enable = true;
  home.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.hack
    nerd-fonts.iosevka
    #proggyfonts
    texlivePackages.cormorantgaramond
    cinzel
  ];
}
