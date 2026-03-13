{
  config,
  pkgs,
  inputs,
  ...
}: {
  # Install yandex-browser directly from the flake's package output
  # The flake uses old nixpkgs internally, so it has compatible dependencies
  home.packages = [
    inputs.yandex-browser.packages.${pkgs.stdenv.hostPlatform.system}.yandex-browser-beta
  ];
}
