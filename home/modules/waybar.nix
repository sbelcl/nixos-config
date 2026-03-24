#
# ~/.nixos/home/modules/waybar.nix
#
{pkgs, ...}: {
  programs.waybar = {
    enable = true;

    settings = [{
      layer    = "top";
      position = "bottom";
      height   = 40;
      spacing  = 2;

      modules-left   = [];
      modules-center = [];
      modules-right  = [
        "wireplumber"
        "network"
        "bluetooth"
        "battery"
        "custom/power-profile"
      ];

      wireplumber = {
        format        = "{icon} {volume}%";
        format-muted  = "󰝟 Muted";
        format-icons  = [ "󰕿" "󰖀" "󰕾" ];
        on-click      = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        on-scroll-up   = "swayosd-client --output-volume raise";
        on-scroll-down = "swayosd-client --output-volume lower";
        tooltip        = false;
      };

      network = {
        format-wifi        = "󰤨 {essid}";
        format-disconnected = "󰤭 Offline";
        format-ethernet    = "󰈀 Wired";
        tooltip-format-wifi = "{signalStrength}% · {frequency} MHz";
        on-click           = "rofi-wifi";
        on-click-right     = "nm-connection-editor";
      };

      bluetooth = {
        format           = "󰂯";
        format-connected = "󰂱 {device_alias}";
        format-off       = "󰂲";
        tooltip-format   = "{controller_alias} · {status}";
        tooltip-format-connected = "{device_enumerate}";
        tooltip-format-enumerate-connected = "{device_alias}";
        on-click       = "blueman-manager";
        on-click-right = "rfkill toggle bluetooth";
      };

      battery = {
        format          = "{icon} {capacity}%";
        format-charging = "󰂄 {capacity}%";
        format-icons    = [ "󰁺" "󰁼" "󰁾" "󰁹" ];
        states = { warning = 30; critical = 15; };
        tooltip-format  = "{timeTo} · {power}W";
      };

      "custom/power-profile" = {
        exec     = "powerprofilesctl get";
        interval = 30;
        format   = "⚡ {}";
        on-click = "rofi-power-profile";
        tooltip  = false;
      };
    }];

    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font", "Inter", sans-serif;
        font-size: 13px;
        border: none;
        border-radius: 0;
        min-height: 0;
        padding: 0;
      }

      window#waybar {
        background-color: rgba(13, 14, 31, 0.90);
        border-top: 2px solid #7fc8ff;
        color: #f0f0f8;
      }

      .modules-right {
        padding-right: 8px;
      }

      #wireplumber,
      #network,
      #bluetooth,
      #battery,
      #custom-power-profile {
        padding: 0 14px;
        color: #f0f0f8;
        background: transparent;
        border-radius: 8px;
        margin: 4px 2px;
        transition: background 0.15s ease;
      }

      #wireplumber:hover,
      #network:hover,
      #bluetooth:hover,
      #battery:hover,
      #custom-power-profile:hover {
        background: rgba(127, 200, 255, 0.12);
      }

      #battery.warning  { color: #f97316; }
      #battery.critical { color: #ec4899; }

      #bluetooth.off { color: #7878a8; }

      #custom-power-profile {
        color: #22d4e0;
      }
    '';
  };
}
