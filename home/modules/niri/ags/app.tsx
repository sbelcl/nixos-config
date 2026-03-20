import { App, Astal, Gtk, Gdk } from "astal/gtk3"
import { Variable, bind, execAsync, GLib, readFile } from "astal"
import Battery from "gi://AstalBattery"
import Network from "gi://AstalNetwork"
import Wp from "gi://AstalWp"
import Mpris from "gi://AstalMpris"
import Apps from "gi://AstalApps"
import Tray from "gi://AstalTray"

const style = readFile(`${GLib.get_home_dir()}/.config/ags/style.css`)
const search = Variable("")

// ── Helpers ───────────────────────────────────────────────────────────────────

function clamp(v: number, min: number, max: number) {
  return Math.max(min, Math.min(max, v))
}

// ── Clock ─────────────────────────────────────────────────────────────────────

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
          for (const app of apps.fuzzy_query(s || "").slice(0, 18))
            container.add(makeAppButton(app))
          container.show_all()
        }
        populate(search.get())
        const unsub = search.subscribe(populate)
        container.connect("destroy", () => unsub())
      }} />
    </scrollable>
  )
}

// ── System tray ───────────────────────────────────────────────────────────────

function SystemTray() {
  const T = Tray as any
  const tray = T.Tray?.get_default?.() ?? T.get_default?.() ?? null
  if (!tray) return <box />

  return (
    <box cssClasses={["tray"]} spacing={4} setup={(self: Gtk.Box) => {
      const rebuild = () => {
        for (const ch of self.get_children()) ch.destroy()
        const items: any[] = tray.items ?? []
        for (const item of items) {
          // Outer event box catches scroll and right-click
          const eb = new Gtk.EventBox({ visible: true })
          eb.get_style_context().add_class("tray-button")
          eb.add_events(
            Gdk.EventMask.SCROLL_MASK |
            Gdk.EventMask.BUTTON_PRESS_MASK
          )

          const img = new Gtk.Image({ pixel_size: 18, visible: true })
          // Prefer gicon, fall back to icon-name
          try { img.gicon = item.gicon } catch (_) {}
          if (!img.gicon) img.icon_name = item.icon_name || "image-missing"
          eb.add(img)

          // Left-click: activate
          eb.connect("button-press-event", (_: any, ev: Gdk.EventButton) => {
            const [, x, y] = ev.get_root_coords()
            const btn = ev.get_button()[1]
            if (btn === 1) item.activate(x, y)
            if (btn === 3) {
              // try both method names across astal versions
              try { (item as any).context_menu(x, y) }
              catch (_) { try { (item as any).secondary_activate(x, y) } catch (_) {} }
            }
            return false
          })
          self.add(eb)
        }
        self.show_all()
      }
      rebuild()
      const a = tray.connect("item-added",   () => rebuild())
      const r = tray.connect("item-removed", () => rebuild())
      self.connect("destroy", () => { tray.disconnect(a); tray.disconnect(r) })
    }} />
  )
}

// ── Volume (scrollable) ───────────────────────────────────────────────────────

function VolumeControl() {
  const W = Wp as any
  const wp    = W.Wp?.get_default?.() ?? W.get_default?.() ?? null
  const audio = wp?.audio ?? null
  if (!audio) return <box />

  const getVol = () => {
    const s = audio.default_speaker
    return s ? Math.round((s as any).volume * 100) : 0
  }
  const getMuted = () => {
    const s = audio.default_speaker
    return (s as any)?.mute ?? false
  }

  const volVar   = Variable(getVol())
  const mutedVar = Variable(getMuted())

  // Keep vars in sync when default speaker changes
  const syncId = audio.connect("notify::default-speaker", () => {
    volVar.set(getVol())
    mutedVar.set(getMuted())
  })

  const eb = (
    <eventbox
      cssClasses={["status-item"]}
      onDestroy={() => { audio.disconnect(syncId); volVar.drop(); mutedVar.drop() }}
      onScrollEvent={(_: any, ev: Gdk.EventScroll) => {
        const dir = ev.get_scroll_direction()[1]
        const delta = dir === Gdk.ScrollDirection.UP ? 5 : -5
        execAsync(["swayosd-client", "--output-volume",
          delta > 0 ? "raise" : "lower"])
        volVar.set(clamp(volVar.get() + delta, 0, 100))
        return true
      }}
    >
      <box spacing={6}>
        <icon setup={self => {
          const update = () => {
            self.icon = mutedVar.get()
              ? "audio-volume-muted-symbolic"
              : volVar.get() > 50
                ? "audio-volume-high-symbolic"
                : "audio-volume-low-symbolic"
          }
          update()
          const u1 = volVar.subscribe(update)
          const u2 = mutedVar.subscribe(update)
          self.connect("destroy", () => { u1(); u2() })
        }} />
        <label setup={self => {
          const update = () => {
            self.label = mutedVar.get() ? "Muted" : `${volVar.get()}%`
          }
          update()
          const u1 = volVar.subscribe(update)
          const u2 = mutedVar.subscribe(update)
          self.connect("destroy", () => { u1(); u2() })
        }} />
      </box>
    </eventbox>
  )
  return eb
}

// ── Brightness (scrollable) ───────────────────────────────────────────────────

function BrightnessControl() {
  const brightnessVar = Variable(50)

  // Read current brightness on init
  execAsync(["brightnessctl", "get"]).then(cur => {
    execAsync(["brightnessctl", "max"]).then(max => {
      brightnessVar.set(Math.round((Number(cur.trim()) / Number(max.trim())) * 100))
    }).catch(() => {})
  }).catch(() => {})

  return (
    <eventbox
      cssClasses={["status-item"]}
      onDestroy={() => brightnessVar.drop()}
      onScrollEvent={(_: any, ev: Gdk.EventScroll) => {
        const dir = ev.get_scroll_direction()[1]
        const delta = dir === Gdk.ScrollDirection.UP ? 5 : -5
        execAsync(["brightnessctl", "set", `${delta > 0 ? "+" : ""}${delta}%`])
          .then(() => execAsync(["brightnessctl", "get"]).then(cur =>
            execAsync(["brightnessctl", "max"]).then(max =>
              brightnessVar.set(Math.round((Number(cur.trim()) / Number(max.trim())) * 100))
            )
          ))
          .catch(() => {})
        return true
      }}
    >
      <box spacing={6}>
        <icon icon="display-brightness-symbolic" />
        <label setup={self => {
          self.label = `${brightnessVar.get()}%`
          const unsub = brightnessVar.subscribe(v => { self.label = `${v}%` })
          self.connect("destroy", () => unsub())
        }} />
      </box>
    </eventbox>
  )
}

// ── Network ───────────────────────────────────────────────────────────────────

function NetworkStatus() {
  const N = Network as any
  const network = N.Network?.get_default?.() ?? N.get_default?.() ?? null
  if (!network) return <box />

  return (
    <box cssClasses={["status-item"]} spacing={6}>
      <icon icon="network-wireless-symbolic" />
      <label label={bind(network, "wifi").as(w => (w as any)?.ssid || "Offline")} />
    </box>
  )
}

// ── Battery ───────────────────────────────────────────────────────────────────

function BatteryStatus() {
  const B = Battery as any
  const battery = B.Battery?.get_default?.() ?? B.get_default?.() ?? null
  if (!battery) return <box />

  return (
    <box cssClasses={["status-item"]} spacing={6}>
      <icon icon={bind(battery, "icon_name")} />
      <label label={bind(battery, "percentage").as(p => `${Math.round(p * 100)}%`)} />
    </box>
  )
}

// ── Status bar ────────────────────────────────────────────────────────────────

function StatusBar() {
  return (
    <box cssClasses={["status-bar"]} spacing={16} halign={Gtk.Align.CENTER}>
      <BatteryStatus />
      <NetworkStatus />
      <VolumeControl />
      <BrightnessControl />
    </box>
  )
}

// ── Media player ──────────────────────────────────────────────────────────────

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

// ── Launcher window ───────────────────────────────────────────────────────────

let launcherWindow: Astal.Window

function Launcher() {
  let searchEntry: Gtk.Entry | undefined

  // 80% of screen via widthRequest/heightRequest on the content box
  const gdkScreen = Gdk.Screen.get_default()
  const screenW   = gdkScreen?.get_width()  ?? 1920
  const screenH   = gdkScreen?.get_height() ?? 1080

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
      {/* EventBox gives GTK3 a GdkWindow to paint the background on */}
      <eventbox
        cssClasses={["launcher"]}
        halign={Gtk.Align.CENTER}
        valign={Gtk.Align.CENTER}
        widthRequest={Math.round(screenW * 0.8)}
        heightRequest={Math.round(screenH * 0.8)}
      >
        {/* Two-column layout inside */}
        <box hexpand vexpand spacing={40} cssClasses={["launcher-inner"]}>

          {/* Left: clock + search + app list */}
          <box vertical hexpand vexpand spacing={20}>
            <Clock />
            <entry
              cssClasses={["search-entry"]}
              placeholderText="Search apps..."
              text={bind(search)}
              onChanged={self => search.set(self.text)}
              setup={self => (searchEntry = self)}
            />
            <AppGrid />
          </box>

          {/* Divider */}
          <box cssClasses={["col-divider"]} />

          {/* Right: status + tray + media + power */}
          <box vertical spacing={24} cssClasses={["col-right"]} valign={Gtk.Align.FILL}>
            <StatusBar />
            <SystemTray />
            <MediaPlayer />
            <box vexpand />
            <PowerButtons />
          </box>

        </box>
      </eventbox>
    </window>
  ) as Astal.Window
}

App.start({
  instanceName: "astal",
  css: style,
  main() {
    try { Launcher() } catch (e) { console.error("Launcher failed:", e) }
  },
})
