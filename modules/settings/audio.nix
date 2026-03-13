#
# ~/.nixos/modules/settings/audio.nix
#
{
  # Omogoči RealtimeKit – PipeWire/JACK potem lahko dobi real-time scheduling
  security.rtkit.enable = true;

  services.pulseaudio.enable = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;

    # Add this section!
    wireplumber.enable = true;
  };
}

