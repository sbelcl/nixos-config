#
# ~/.nixos/home/modules/yandex-flags.nix
#
# Yandex Browser's launch flags, kept in one place because two modules need
# the same string: yandex.nix's .desktop entry (normal browsing, %U) and
# webapps.nix's --app= windows.
#
# packages.nix launches the browser through gtk-launch on its .desktop
# precisely so these flags stay defined once. Web apps cannot do that —
# --app= is a flag, and gtk-launch only forwards URLs — so they read the
# string from here instead of carrying a second copy that would drift.
#
# See yandex.nix for why --ozone-platform=wayland is required on NixOS, and
# for the --use-angle=gl flag that used to sit beside it.
#
# Plain Nix, not a module: it is a value, not configuration.
#
"--ozone-platform=wayland"
