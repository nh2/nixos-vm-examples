# From https://nixos.mayflower.consulting/blog/2018/09/11/custom-images/
# Build VM using:
#     nix-build '<nixpkgs/nixos>' -A vm --arg configuration ./grub-test-vm-configuration.nix
# The `./` is important, as it needs to be a nix path literal.
# Run VM using:
#     result/bin/run-nixos-vm
# Depending on your permissions you may have to use `sudo` for running.
# A QEMU window will pop up and you can log in as `root` with empty password.
# Note by default `ping` will not work, but other Internet stuff will, see
# https://wiki.qemu.org/Documentation/Networking#User_Networking_.28SLIRP.29
# The VM HD is stored in `./nixos.qcow2`. Delete it if you want to start from scratch.

{ pkgs, lib, ... }:

with lib;
let
  mount_host_path = toString ../.; # our `nixos-vm-examples` dir
  mount_tag = "hostdir"; # just a label tag for qemu mounts
in
{
  imports = [
    <nixpkgs/nixos/modules/profiles/qemu-guest.nix>
    # The system's configuration.nix; split into a separate file so that we
    # can easily copy it to `/etc/nixos/configuration.nix` in the guest
    # without the `virtualisation` options below which are not valid inside.
    ./grub-test-vm-configuration.nix
  ];

  config = {

    virtualisation = {
      diskSize = 4096; # MB
      memorySize = 2048; # MB
      qemu.options = [
        "-virtfs local,path=${mount_host_path},security_model=none,mount_tag=${mount_tag}"
      ];

      # Because we want to test GRUB.
      # This may require `system-features = kvm` in your `nix.conf`, and your user
      # to be part of the `kvm` group, otherwise you may get:
      #     Could not access KVM kernel module: Permission denied
      useBootLoader = true;
    };

    # Copy VM configuration into guest so that we can use `nixos-rebuild` in there.
    boot.postBootCommands = ''
      cp ${./grub-test-vm-configuration.nix} /etc/nixos/configuration.nix
    '';

  };
}
