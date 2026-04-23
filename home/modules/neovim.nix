{pkgs, ...}: {
  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
    withRuby = true;
    withPython3 = true;
    extraConfig = ''
      set number relativenumber
      set syntax
      set shiftwidth=2
      set expandtab
      set tabstop=2
    '';
  };
}
