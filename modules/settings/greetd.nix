#
# ~/.nixos/modules/settings/greetd.nix
#
# greetd display manager with ReGreet graphical greeter
#
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; {
  options.displayManager.greetd = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable greetd display manager with ReGreet graphical greeter";
    };
  };

  config = mkIf config.displayManager.greetd.enable {
    services.greetd = {
      enable = true;
      settings.default_session = {
        user = "greeter";
        # XKB_DEFAULT_LAYOUT must be in cage's own env (wlroots reads it at startup)
        command = "${pkgs.coreutils}/bin/env XKB_DEFAULT_LAYOUT=si ${pkgs.dbus}/bin/dbus-run-session ${pkgs.cage}/bin/cage -s -d -- ${pkgs.regreet}/bin/regreet";
      };
    };

    programs.regreet = {
      enable = true;
      settings = {
        GTK = lib.mkForce {
          application_prefer_dark_theme = true;
          font_name = "Inter 11";
          icon_theme_name = "Papirus";
          cursor_theme_name = "Bibata-Modern-Classic";
        };
        background = {
          path = "${../../assets/wallpapers/default.png}";
          fit = "Cover";
        };
      };
      extraCss = ''
        window {
          background-color: #0d0d0d;
        }
        headerbar {
          background-color: transparent;
          border-bottom: none;
          box-shadow: none;
        }
        /* Login card */
        .container {
          background-color: rgba(18, 18, 18, 0.92);
          border-radius: 20px;
          border: 1px solid rgba(255, 255, 255, 0.07);
          box-shadow: 0 16px 48px rgba(0, 0, 0, 0.8);
          padding: 40px 48px;
          min-width: 380px;
        }
        label, .label {
          color: #e0e0e0;
        }
        entry {
          background-color: rgba(255, 255, 255, 0.05);
          border: 1px solid rgba(255, 255, 255, 0.1);
          border-radius: 10px;
          color: #ffffff;
          caret-color: #7fc8ff;
          padding: 10px 14px;
        }
        entry:focus {
          border-color: #7fc8ff;
          background-color: rgba(127, 200, 255, 0.07);
          box-shadow: 0 0 0 3px rgba(127, 200, 255, 0.18);
        }
        /* Login / confirm buttons — blue gradient */
        button.suggested-action,
        button.destructive-action {
          background: linear-gradient(135deg, #5bafd6, #7fc8ff);
          border: none;
          border-radius: 10px;
          color: #0d0d0d;
          font-weight: bold;
          padding: 10px 20px;
        }
        button.suggested-action:hover,
        button.destructive-action:hover {
          background: linear-gradient(135deg, #7fc8ff, #a8d8f0);
        }
        /* Session selector — subtle, since there's only one session */
        dropdown, combobox {
          background-color: rgba(255, 255, 255, 0.04);
          border: 1px solid rgba(255, 255, 255, 0.08);
          border-radius: 10px;
          color: #888;
          font-size: 0.85em;
        }
        dropdown button, combobox button {
          background: transparent;
          border: none;
          color: #888;
        }
        popover > contents {
          background-color: #1a1a1a;
          border: 1px solid rgba(255, 255, 255, 0.08);
          border-radius: 10px;
        }
        popover modelbutton {
          color: #e0e0e0;
          padding: 8px 16px;
          border-radius: 6px;
        }
        popover modelbutton:hover {
          background-color: rgba(127, 200, 255, 0.15);
        }
      '';
    };

    # Needed so regreet/cage can access GPU and input devices
    hardware.graphics.enable = lib.mkDefault true;

    # Unlock GNOME Keyring on login
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.greetd.enableGnomeKeyring = true;

    # Icon and cursor themes need to be available system-wide for the greeter
    environment.systemPackages = with pkgs; [
      papirus-icon-theme
      bibata-cursors
      inter
    ];
  };
}
