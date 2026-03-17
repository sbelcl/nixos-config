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
// Use setup + explicit destroy-signal cleanup to avoid "already disposed" errors
// when the Variable poll fires after a widget is destroyed from C code.

function Clock() {
  const timeVar = Variable("").poll(1000, "date '+%H:%M'")
  const dateVar = Variable("").poll(60000, "date '+%A, %-d %B %Y'")

  return (
    <box vertical halign={Gtk.Align.CENTER} spacing={4}
      onDestroy={() => { timeVar.drop(); dateVar.drop() }}>
      <label cssClasses={["clock"]} setup={self => {
        self.label = timeVar.get()
        const unsub = timeVar.subscribe(t => { self.label = t })
        self.connect("destroy", () => unsub())
      }} />
      <label cssClasses={["date"]} setup={self => {
        self.label = dateVar.get()
        const unsub = dateVar.subscribe(d => { self.label = d })
        self.connect("destroy", () => unsub())
      }} />
    </box>
  )
}

// ── App list ──────────────────────────────────────────────────────────────────
// Fully imperative via setup — avoids JSX reactive-children issues in GTK3.

function makeAppButton(app: Apps.Application): Gtk.Button {
  const btn = new Gtk.Button()
  btn.get_style_context().add_class("app-button")
  btn.tooltip_text = app.description || ""
  btn.visible = true

  const row = new Gtk.Box({ orientation: Gtk.Orientation.HORIZONTAL, spacing: 10, visible: true })
  const img = new Gtk.Image({ icon_name: app.icon_name || "application-x-executable", pixel_size: 24, visible: true })
  const lbl = new Gtk.Label({ label: app.name, xalign: 0, visible: true })

  row.pack_start(img, false, false, 0)
  row.pack_start(lbl, true, true, 0)
  btn.add(row)

  btn.connect("clicked", () => {
    app.launch()
    search.set("")
    App.toggle_window("launcher")
  })

  return btn
}

function AppGrid() {
  const A = Apps as any
  const apps = A.Apps ? new A.Apps() : (A.get_default?.() ?? { fuzzy_query: () => [] })
  return (
    <scrollable vexpand cssClasses={["app-scroll"]}>
      <box vertical cssClasses={["app-grid"]} setup={(container: Gtk.Box) => {
        const populate = (s: string) => {
          for (const child of container.get_children()) child.destroy()
          for (const app of apps.fuzzy_query(s || "").slice(0, 18)) {
            container.add(makeAppButton(app))
          }
          container.show_all()
        }
        populate(search.get())
        const unsub = search.subscribe(populate)
        container.connect("destroy", () => unsub())
      }} />
    </scrollable>
  )
}

// ── Status bar ───────────────────────────────────────────────────────────────

function Status() {
  // Log available names to diagnose GI namespace class naming
  console.log("Battery exports:", Object.getOwnPropertyNames(Battery).filter(k => !k.startsWith("_")).join(", "))
  console.log("Network exports:", Object.getOwnPropertyNames(Network).filter(k => !k.startsWith("_")).join(", "))
  console.log("Wp exports:", Object.getOwnPropertyNames(Wp).filter(k => !k.startsWith("_")).join(", "))

  const B = Battery as any
  const N = Network as any
  const W = Wp as any

  const battery = B.Battery?.get_default?.() ?? B.get_default?.() ?? null
  const network = N.Network?.get_default?.() ?? N.get_default?.() ?? null
  const wp      = W.Wp?.get_default?.()      ?? W.get_default?.() ?? null
  const audio   = wp?.audio ?? null

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
      {audio && (
        <box spacing={8}>
          <icon icon="audio-volume-high-symbolic" />
          <label label={bind(audio, "default_speaker").as(s =>
            s ? `${Math.round((s as any).volume * 100)}%` : "—"
          )} />
        </box>
      )}
    </box>
  )
}

// ── Media player ─────────────────────────────────────────────────────────────

function MediaPlayer() {
  const M = Mpris as any
  const mpris = M.Mpris?.get_default?.() ?? M.get_default?.() ?? null
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

// Module-scope reference prevents GJS GC of the window object.
let launcherWindow: Astal.Window

function Launcher() {
  let searchEntry: Gtk.Entry | undefined

  launcherWindow = (
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
  ) as Astal.Window
}

App.start({
  instanceName: "astal",
  css: style,
  main() {
    try {
      Launcher()
    } catch (e) {
      console.error("Launcher failed:", e)
    }
  },
})
