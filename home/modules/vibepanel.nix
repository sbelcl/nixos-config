#
# ~/.nixos/home/modules/vibepanel.nix
#
{
  pkgs,
  inputs,
  ...
}: let
  vp = inputs.vibepanel.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  home.packages = [vp];

  xdg.configFile."vibepanel/config.toml".text = ''
    [bar]
    position = "top"
    size = 36
    border_radius = 0
    background_opacity = 0.0

    [widgets]
    left   = ["workspaces", "window_title"]
    center = ["clock"]
    right  = ["custom-power", "brightness", "quick_settings", "battery", "tray", "notifications"]
    border_radius = 40
    background_opacity = 0.6

    [widgets.clock]
    format = "%H:%M  ·  %A, %-d %B"

    [widgets.custom-power]
    icon    = "system-shutdown-symbolic"
    tooltip = "Power menu"
    on_click = "rofi-power"

    [theme]
    mode   = "dark"
    accent = "#7fc8ff"

    [theme.icons]
    theme  = "gtk"

    [osd]
    enabled  = true
    position = "bottom"
  '';

  xdg.configFile."vibepanel/style.css".text = ''
    :root {
      --color-foreground:          #f0f0f8;
      --color-accent-primary:      #7fc8ff;
      --color-state-warning:       #f97316;
      --color-state-urgent:        #ec4899;
    }

    /* Quick settings / clock popovers */
    popover > contents,
    .vp-surface-popover {
      background-color: #0d0e1f;
      opacity: 1;
    }

    /* Notification toast windows */
    .notification,
    .toast,
    .app-notification {
      background-color: #0d0e1f;
    }
  '';

  systemd.user.services.vibepanel = {
    Unit = {
      Description = "vibepanel — GTK4 Wayland panel";
      After       = ["graphical-session.target"];
      PartOf      = ["graphical-session.target"];
      ConditionEnvironment = "NIRI_SOCKET";
    };
    Service = {
      ExecStart = "${vp}/bin/vibepanel";
      Restart   = "on-failure";
      RestartSec = "3s";
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
