# Inspired by:
#
#   * https://nixos.mayflower.consulting/blog/2018/09/11/custom-images/
#   * http://blog.patapon.info/nixos-local-vm/#accessing-the-vm-with-ssh
#
# Build VM using:
#
#     NIX_PATH=.. nix-build '<nixpkgs/nixos>' -A vm --arg configuration ./configuration.nix
#
# The `./` is important, as it needs to be a nix path literal.
# Run VM using:
#
#     rm -f nixos.qcow2 && result/bin/run-nixos-vm
#
# Depending on your permissions you may have to use `sudo` for running.
# A QEMU window will pop up and you can log in as `root` with empty password.
#
# Even better, with SSH:
#
#     rm -f nixos.qcow2 && env QEMU_NET_OPTS=hostfwd=tcp::2221-:22
#
# Then you can ssh in using:
#
#     ssh -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no root@localhost -p 2221
#
# Note by default `ping` will not work, but other Internet stuff will, see
# https://wiki.qemu.org/Documentation/Networking#User_Networking_.28SLIRP.29
#
# The VM HD is stored in `./nixos.qcow2`. Delete it if you want to start from scratch.
# It is also important to delete it whenever you change this `configuration.nix`
# file, because `postBootCommands` below copies it into the VM only then,
# and even something benign like comments differing can result in the next
# `nixos-rebuild` in the VM requiring to download a lot of stuff instead of
# being a no-op.

{ pkgs, lib, config, ... }:

with lib;
let
  mount_guest_path = "/root/host-dir";
  mount_host_path = toString ../.; # our `nixos-vm-examples` dir
  mount_tag = "hostdir"; # just a label tag for qemu mounts
in
{
  imports = [
    <nixpkgs/nixos/modules/profiles/qemu-guest.nix>
    <nixpkgs/nixos/modules/virtualisation/qemu-vm.nix>
  ];

  config = {
    services.qemuGuest.enable = true;

    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
      autoResize = true;
    };

    boot = {
      growPartition = true;
      kernelParams = [ "console=ttyS0 boot.shell_on_fail" ];
      loader.timeout = 5;
      # Not set because `qemu-vm.nix` overrides it anyway:
      # loader.grub.device = "/dev/vda";

      # Mount nixpkgs submodule at `/root/nixpkgs` in guest.
      initrd.postMountCommands = ''
        mkdir -p "$targetRoot/${mount_guest_path}"
        mount -t 9p "${mount_tag}" "$targetRoot/${mount_guest_path}" -o trans=virtio,version=9p2000.L,cache=none
      '';

      # This is the functionality we want to test.
      # From inside the VM, you can run:
      #     cd host-dir
      #     NIX_PATH=.:nixos-config=$PWD/grub-test-vm/configuration.nix nixos-rebuild switch --install-bootloader --fast
      loader.grub.extraGrubInstallArgs = [
        # Uncomment to try this change:
        # "--modules=nativedisk ahci pata part_gpt part_msdos diskfilter mdraid1x lvm ext2"
      ];

      # Copy VM configuration into guest so that we can use `nixos-rebuild` in there.
      postBootCommands = ''
        cp ${./configuration.nix} /etc/nixos/configuration.nix
      '';
    };

    virtualisation = {
      diskSize = 8000; # MB
      memorySize = 2048; # MB
      qemu.options = [
        "-virtfs local,path=${mount_host_path},security_model=none,mount_tag=${mount_tag}"
      ];

      # We don't want to use tmpfs, otherwise the nix store's size will be bounded
      # by a fraction of available RAM.
      writableStoreUseTmpfs = false;

      # Because we want to test GRUB.
      # This may require `system-features = kvm` in your `nix.conf`, and your user
      # to be part of the `kvm` group, otherwise you may get:
      #     Could not access KVM kernel module: Permission denied
      useBootLoader = true;
    };

    # So that we can ssh into the VM, see e.g.
    # http://blog.patapon.info/nixos-local-vm/#accessing-the-vm-with-ssh
    services.openssh.enable = true;
    services.openssh.permitRootLogin = "yes";

    environment.systemPackages = with pkgs; [
      git
      htop
      vim
      nix-diff
    ];

    users.extraUsers.root.password = "";
    users.mutableUsers = false;

  };
}
