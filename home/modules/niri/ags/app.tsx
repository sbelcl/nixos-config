import { App, Astal, Gtk, Gdk } from "astal/gtk3"
import { Variable, bind, execAsync, GLib, readFile } from "astal"
import Battery from "gi://AstalBattery"
import Network from "gi://AstalNetwork"
import Wp from "gi://AstalWp"
import Mpris from "gi://AstalMpris"
import Apps from "gi://AstalApps"

const style = readFile(`${GLib.get_home_dir()}/.config/ags/style.css`)
const search = Variable("")

// ── Clock ────────────────────────────────────────────────────────────────────

function Clock() {
  const time = Variable("").poll(1000, "date '+%H:%M'")
  const date = Variable("").poll(60000, "date '+%A, %-d %B %Y'")
  return (
    <box vertical halign={Gtk.Align.CENTER} spacing={4}
      onDestroy={() => { time.drop(); date.drop() }}>
      <label cssClasses={["clock"]} label={bind(time)} />
      <label cssClasses={["date"]} label={bind(date)} />
    </box>
  )
}

// ── App grid ─────────────────────────────────────────────────────────────────

function AppGrid() {
  const apps = new Apps.Apps()
  return (
    <scrollable vexpand cssClasses={["app-scroll"]}>
      <flowbox
        cssClasses={["app-grid"]}
        homogeneous
        columnSpacing={8}
        rowSpacing={8}
        maxChildrenPerLine={6}
        minChildrenPerLine={3}
        selectionMode={Gtk.SelectionMode.NONE}
      >
        {bind(search).as(s =>
          apps.fuzzy_query(s || "").slice(0, 24).map(app => (
            <flowboxchild canFocus={false}>
              <button
                cssClasses={["app-button"]}
                tooltipText={app.description || ""}
                onClicked={() => {
                  app.launch()
                  search.set("")
                  App.toggle_window("launcher")
                }}
              >
                <box vertical halign={Gtk.Align.CENTER} spacing={4}>
                  <icon icon={app.icon_name || "application-x-executable"} pixelSize={32} />
                  <label
                    label={app.name}
                    maxWidthChars={10}
                    ellipsize={3}
                    justify={Gtk.Justification.CENTER}
                  />
                </box>
              </button>
            </flowboxchild>
          ))
        )}
      </flowbox>
    </scrollable>
  )
}

// ── Status bar ───────────────────────────────────────────────────────────────

function Status() {
  const battery = Battery.Battery.get_default()
  const network = Network.Network.get_default()
  const wp = Wp.Wp.get_default()

  return (
    <box cssClasses={["status-bar"]} spacing={32} halign={Gtk.Align.CENTER}>
      {battery && (
        <box spacing={8}>
          <icon icon={bind(battery, "icon_name")} />
          <label label={bind(battery, "percentage").as(p => `${Math.round(p * 100)}%`)} />
        </box>
      )}
      {network && (
        <box spacing={8}>
          <icon icon="network-wireless-symbolic" />
          <label label={bind(network, "wifi").as(w => (w as any)?.ssid || "Offline")} />
        </box>
      )}
      {wp && (
        <box spacing={8}>
          <icon icon="audio-volume-high-symbolic" />
          <label label={bind(wp.audio, "default_speaker").as(s =>
            s ? `${Math.round((s as any).volume * 100)}%` : "—"
          )} />
        </box>
      )}
    </box>
  )
}

// ── Media player ─────────────────────────────────────────────────────────────

function MediaPlayer() {
  const mpris = Mpris.Mpris.get_default()
  if (!mpris) return <box />

  return (
    <box>
      {bind(mpris, "players").as(players => {
        const player = players[0]
        if (!player) return []
        return [
          <box cssClasses={["media-player"]} spacing={12} halign={Gtk.Align.CENTER}>
            <button cssClasses={["media-button"]} onClicked={() => (player as any).previous()}>
              <icon icon="media-skip-backward-symbolic" />
            </button>
            <button cssClasses={["media-button"]} onClicked={() => (player as any).play_pause()}>
              <icon icon={bind(player, "playback_status").as(s =>
                s === "Playing" ? "media-playback-pause-symbolic" : "media-playback-start-symbolic"
              )} />
            </button>
            <button cssClasses={["media-button"]} onClicked={() => (player as any).next()}>
              <icon icon="media-skip-forward-symbolic" />
            </button>
            <label
              label={bind(player, "title").as(t =>
                t ? `${(player as any).artist ? (player as any).artist + " — " : ""}${t}` : ""
              )}
              maxWidthChars={40}
              ellipsize={3}
            />
          </box>
        ]
      })}
    </box>
  )
}

// ── Power buttons ─────────────────────────────────────────────────────────────

function PowerButtons() {
  return (
    <box cssClasses={["power-row"]} spacing={8} halign={Gtk.Align.CENTER}>
      <button cssClasses={["power-button"]}
        onClicked={() => execAsync(["loginctl", "terminate-user", GLib.get_user_name()])}>
        <label label="Logout" />
      </button>
      <button cssClasses={["power-button"]}
        onClicked={() => execAsync(["systemctl", "reboot"])}>
        <label label="Restart" />
      </button>
      <button cssClasses={["power-button", "shutdown"]}
        onClicked={() => execAsync(["systemctl", "poweroff"])}>
        <label label="Shutdown" />
      </button>
    </box>
  )
}

// ── Main window ───────────────────────────────────────────────────────────────

function Launcher() {
  let searchEntry: Gtk.Entry | undefined

  return (
    <window
      name="launcher"
      application={App}
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.ON_DEMAND}
      visible={false}
      onShow={() => searchEntry?.grab_focus()}
      onKeyPressEvent={(_, event) => {
        if (event.get_keyval()[1] === Gdk.KEY_Escape) {
          search.set("")
          App.toggle_window("launcher")
        }
      }}
    >
      <box cssClasses={["launcher"]} vertical halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER} spacing={20}>
        <Clock />
        <entry
          cssClasses={["search-entry"]}
          placeholderText="Search apps..."
          text={bind(search)}
          onChanged={self => search.set(self.text)}
          setup={self => (searchEntry = self)}
        />
        <AppGrid />
        <Status />
        <MediaPlayer />
        <PowerButtons />
      </box>
    </window>
  )
}

App.start({
  instanceName: "astal",
  css: style,
  main() {
    Launcher()
  },
})
