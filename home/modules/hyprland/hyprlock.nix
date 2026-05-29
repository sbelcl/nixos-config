#
# ~/.nixos/home/modules/hyprland/hyprlock.nix
#
# Visual style mirrors swaylock-effects: blurred screenshot + clock + input field
#
{ ... }: {
  programs.hyprlock = {
    enable = true;
    settings = {
      background = [{
        monitor = "";
        path = "screenshot";
        blur_passes = 2;
        blur_size = 8;
        brightness = 0.7;
      }];

      input-field = [{
        monitor = "";
        size = "300, 50";
        outline_thickness = 2;
        dots_size = 0.26;
        dots_spacing = 0.64;
        outer_color = "rgba(c45454aa)";
        inner_color = "rgba(1a0a0acc)";
        font_color = "rgb(e8d5d5)";
        fade_on_empty = true;
        placeholder_text = "<i>Password</i>";
        rounding = 10;
        check_color = "rgba(c45454ff)";
        fail_color = "rgba(ff4444ff)";
        fail_text = "<i>Auth Failed</i>";
        capslock_color = "rgba(f97316ff)";
        position = "0, -20";
        halign = "center";
        valign = "center";
      }];

      label = [
        # Clock
        {
          monitor = "";
          text = ''cmd[update:1000] echo "$(date +'%H:%M')"'';
          color = "rgba(ffffffff)";
          font_size = 72;
          font_family = "Inter";
          position = "0, 200";
          halign = "center";
          valign = "center";
        }
        # Date
        {
          monitor = "";
          text = ''cmd[update:60000] echo "$(date +'%A, %B %-d')"'';
          color = "rgba(ffffffcc)";
          font_size = 20;
          font_family = "Inter";
          position = "0, 120";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
