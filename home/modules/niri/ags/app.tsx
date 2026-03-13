import { App, Astal, Gtk, Gdk } from "astal/gtk3"
import { Variable } from "astal"

// Minimal launcher skeleton — to be expanded with clock, battery, network, volume, media
function Launcher() {
  return (
    <window
      name="launcher"
      application={App}
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.ON_DEMAND}
      visible={false}
      onKeyPressEvent={(_, event) => {
        if (event.get_keyval()[1] === Gdk.KEY_Escape)
          App.toggle_window("launcher")
      }}
    >
      <box cssClasses={["launcher"]} vertical halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER}>
        <label label="Launcher — work in progress" />
      </box>
    </window>
  )
}

App.start({
  instanceName: "astal",
  main() {
    Launcher()
  },
})
