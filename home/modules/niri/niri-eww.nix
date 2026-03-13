{ config, pkgs, ... }:

let
  ewwDir = "${config.home.homeDirectory}/.config/eww";

  # --- Bash skripta za aplikacije (.desktop -> JSON)
  appsJsonScript = pkgs.writeScript "apps-json" ''
    #!/usr/bin/env bash
    set -euo pipefail

    dirs=(
      "/run/current-system/sw/share/applications"
      "/etc/profiles/per-user/$USER/share/applications"
      "$HOME/.local/share/applications"
      "/usr/share/applications"
    )

    printf '['
    first=1
    for f in $(find "''${dirs[@]}" -maxdepth 1 -type f -name '*.desktop' | sort); do
      name=$(grep -m1 '^Name=' "$f" | cut -d= -f2-)
      exec=$(grep -m1 '^Exec=' "$f" | cut -d= -f2- | sed 's/ *%[fFuUdDnNickvm]//g')
      id=$(basename "$f" .desktop)

      [ -z "$name" ] && continue
      [ $first -eq 0 ] && printf ','
      printf '{"id":"%s","name":"%s","exec":"%s"}' "$id" "$name" "$exec"
      first=0
    done
    printf ']'
  '';

  # --- Skripta za togglanje Eww overview
  toggleOverviewScript = pkgs.writeScript "toggle-eww-overview" ''
    #!/usr/bin/env bash
    if eww windows | grep -q "overview-window"; then
      eww close overview-window
    else
      eww open overview-window
      sleep 0.1
      eww update overview-class="visible"
    fi
  '';

in {
  home.packages = with pkgs; [ eww jq ];

  xdg.configFile = {
    # =========================
    # EWW.YUCK
    # =========================
    "eww/eww.yuck".text = ''
	;; =========================
	;; VARIABLES
	;; =========================
	(defpoll apps :interval "120s" "''${appsJsonScript}")
	(defvar search "")
	(defvar time "")
	(defvar overview-class "")
	(deflisten battery "cat /sys/class/power_supply/BAT0/capacity")

      ;; =========================
      ;; WIDGETS
      ;; =========================
      (defwidget app-button [app]
        (button
          :class "app"
          :onclick "''${app.exec}"
          (box :orientation "v" :halign "center"
            (label :class "app-name" :text "''${app.name}"))))

      (defwidget app-grid []
        (flowbox :min-children-per-line 6 :max-children-per-line 6 :column-spacing 20 :row-spacing 12
          (for app in apps
            (if (str-contains? (downcase search) (downcase app.name))
                (app-button :app app)))))

      (defwidget overview []
        (box :orientation "v" :class "overview"
          (label :class "time" :text "''${time}")
          (label :class "date" :text "{{ date +'%A, %d %B %Y' }}")
          (entry :class "search" :text search :onchange "eww update search={}")
          (scroll :vexpand true :class "apps"
            (app-grid))
          (box :class "footer" :orientation "h" :halign "center" :spacing 20
            (label :text "🔋 ''${battery}%")
            (button :onclick "systemctl reboot" (label :text "🔄 Restart"))
            (button :onclick "systemctl poweroff" (label :text "⏻ Power Off"))
            (button :onclick "loginctl terminate-user $USER" (label :text "🚪 Logout"))
          )
        ))

      ;; =========================
      ;; WINDOW
      ;; =========================
      (defwindow overview-window
        :geometry (geometry :x "0%" :y "0%" :width "100%" :height "100%")
        :stacking "overlay" :focusable true :exclusive false
        :class "''${overview-class}"
        (overview))
    '';

    # =========================
    # EWW.SCSS (Blur + fade)
    # =========================
    "eww/eww.scss".text = ''
      .overview {
        background: rgba(25, 25, 25, 0.4);
        backdrop-filter: blur(25px);
        -webkit-backdrop-filter: blur(25px);
        color: #f0f0f0;
        font-family: "JetBrains Mono", sans-serif;
        align-items: center;
        justify-content: flex-start;
        padding: 4em;
        transition: all 0.3s ease-in-out;
        border-radius: 20px;
        box-shadow: 0 0 60px rgba(0,0,0,0.5);
      }

      .time {
        font-size: 4em;
        font-weight: 700;
        margin-bottom: 0.2em;
        background: linear-gradient(180deg, rgba(255,255,255,0.9) 0%, rgba(255,255,255,0.4) 100%);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
      }
      .date {
        font-size: 1.3em;
        margin-bottom: 2em;
        opacity: 0.85;
      }

      .search {
        background: rgba(255, 255, 255, 0.1);
        border-radius: 10px;
        padding: 0.5em 1em;
        font-size: 1.2em;
        color: white;
        margin-bottom: 2em;
        border: 1px solid rgba(255,255,255,0.15);
      }

      .apps {
        min-height: 300px;
        padding: 1em;
      }
      .app {
        background: rgba(255,255,255,0.08);
        border-radius: 12px;
        padding: 1em 1.2em;
        transition: background 0.2s;
      }
      .app:hover {
        background: rgba(255,255,255,0.25);
      }
      .app-name {
        font-size: 1em;
      }

      .footer {
        margin-top: 2em;
        font-size: 1.1em;
      }
      .footer button {
        background: rgba(255,255,255,0.12);
        border-radius: 8px;
        padding: 0.5em 1em;
      }
      .footer button:hover {
        background: rgba(255,255,255,0.35);
      }

      window#overview-window {
        transition: opacity 0.35s ease-in-out;
        opacity: 0;
      }
      window#overview-window.visible {
        opacity: 1;
      }
    '';

    "eww/bin/apps-json".source = appsJsonScript;
    "eww/bin/toggle-eww-overview".source = toggleOverviewScript;
  };

  # --- Systemd servisi (daemon + ura)
  systemd.user.services = {
    "eww-daemon" = {
      Unit = {
        Description = "Eww Daemon";
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.eww}/bin/eww daemon";
        Restart = "on-failure";
      };
      Install = { WantedBy = [ "default.target" ]; };
    };

    "eww-time-updater" = {
      Unit = {
        Description = "Eww time updater";
        After = [ "eww-daemon.service" ];
      };
      Service = {
        ExecStart = "${pkgs.bash}/bin/bash -c 'while true; do eww update time=\"$(date +%H:%M)\"; sleep 30; done'";
        Restart = "always";
      };
      Install = { WantedBy = [ "default.target" ]; };
    };
  };
}

