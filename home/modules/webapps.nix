#
# ~/.nixos/home/modules/webapps.nix
#
# Sites that behave like applications, given their own launcher entry and
# their own window. Chromium's --app= drops the tab strip and the omnibox,
# so what is left is the page.
#
# Declarative, which is the whole difference from Omarchy's
# omarchy-webapp-install: entries are this list, not files written into
# ~/.local/share/applications by a script, and the icons are pinned rather
# than fetched from the live site at install time. Both machines get the
# same set from a `git pull`, and an icon cannot rot because a site
# redesigned its favicon.
#
# Adding one is a line. `icon` is either:
#   * an icon-theme name  — "github", resolved from Papirus at display time
#   * a path              — ./webapps/icons/foo.png, copied into the store
#
# The images in webapps/icons/ are 128px PNGs, normalised with ImageMagick
# from each service's own icon (Yandex's favicons are .ico, which not every
# icon loader will read). They are committed because a fetchurl would put a
# live URL in the build path: content-pinned by hash, yes, but still a
# rebuild that fails the day the URL moves.
#
{ lib, ... }: let
  flags = import ./yandex-flags.nix;

  apps = [
    {
      id = "claude";
      name = "Claude";
      url = "https://claude.ai";
      icon = ./webapps/icons/claude.png;
    }
    {
      id = "chatgpt";
      name = "ChatGPT";
      url = "https://chatgpt.com";
      icon = ./webapps/icons/chatgpt.png;
    }
    {
      id = "yandex-mail";
      name = "Yandex Mail";
      url = "https://mail.yandex.com";
      icon = ./webapps/icons/yandex-mail.png;
      # Thunderbird still owns mailto: and workspace 3 — this is the webmail
      # for when the desktop client is the wrong tool, not a replacement.
    }
    {
      id = "yandex-calendar";
      name = "Yandex Calendar";
      url = "https://calendar.yandex.com";
      icon = ./webapps/icons/yandex-calendar.png;
    }
    {
      id = "github";
      name = "GitHub";
      url = "https://github.com";
      icon = "github";
      categories = [ "Development" ];
    }
    {
      # pma.test resolves through networking.extraHosts in
      # hosts/flanker/flanker.nix, along with mail.test, mcp.test and the
      # project domains — each of which is a line here away from being a
      # launcher entry too.
      id = "phpmyadmin";
      name = "phpMyAdmin";
      url = "http://pma.test";
      icon = "phpmyadmin";
      categories = [ "Development" ];
    }
  ];

  # A path icon is copied into a store path of its own rather than
  # interpolated directly: bare `./icons/x.png` resolves through the flake
  # source, so Icon= would name a path containing the entire repo and would
  # change every time any unrelated file in it changed. builtins.path pins
  # just the image, and the .png suffix stays on the store name because not
  # every icon loader sniffs content.
  #
  # A theme name is already the string the .desktop wants, so it passes
  # through untouched.
  iconOf = app:
    if builtins.isPath app.icon
    then toString (builtins.path { path = app.icon; name = "webapp-${app.id}.png"; })
    else app.icon;

  mkEntry = app: lib.nameValuePair "webapp-${app.id}" {
    name = app.name;
    genericName = "Web app";
    exec = "yandex-browser-beta ${flags} --app=${app.url}";
    icon = iconOf app;
    categories = [ "Network" ] ++ (app.categories or [ ]);
    startupNotify = true;
    terminal = false;
  };
in {
  xdg.desktopEntries = lib.listToAttrs (map mkEntry apps);
}
