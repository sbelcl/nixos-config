#
# ~/.nixos/home/modules/vm-curator.nix
#
# vm-curator — a TUI for building and running QEMU/KVM guests directly, without
# libvirt in the middle. Comes from its own flake (see home/flake.nix); nixpkgs
# has no such package.
#
# The host side is already in place and none of it is this module's doing:
# /dev/kvm is world-accessible, imnos is in the libvirtd group, and
# modules/software/libvirt.nix brings qemu_kvm, swtpm and virt-viewer along
# with the edk2 firmware under /run/libvirt/nix-ovmf. vm-curator does not use
# libvirt, but it happily uses everything libvirt pulled in.
#
# What it does need is those helpers on its *own* PATH, since it shells out to
# them. qemu and virt-viewer are already system-wide; swtpm, passt and dnsmasq
# are not, and they are what Windows 11 guests (TPM 2.0), the passt network
# backend and managed-network DHCP respectively depend on. Wrapping keeps them
# out of the interactive PATH, where three daemons nobody types the names of
# would just be noise.
#
# --suffix, not --prefix: the system qemu wins if both exist, so a guest keeps
# running against the same binary libvirt uses rather than silently switching
# to a second copy on the next rebuild.
#
{ pkgs, lib, inputs, ... }: let
  vm-curator = inputs.vm-curator.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  home.packages = [
    (pkgs.symlinkJoin {
      name = "vm-curator-${vm-curator.version}";
      paths = [ vm-curator ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/vm-curator \
          --suffix PATH : ${lib.makeBinPath (with pkgs; [
            qemu_kvm
            swtpm
            passt
            dnsmasq
            virt-viewer
          ])}
      '';
    })
  ];
}
