{ pkgs, lib, ... }:

with lib;
let
  mount_guest_path = "/root/host-dir";
  mount_tag = "hostdir"; # just a label tag for qemu mounts
in
{
  imports = [
    <nixpkgs/nixos/modules/profiles/clone-config.nix>
  ];

  config = {
    # installer.cloneConfig = true; # Allows re-building in the live system, see https://nixos.org/nixos/manual/#sec-profile-clone-config
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
      loader.grub.device = "/dev/vda";

      # Mount nixpkgs submodule at `/root/nixpkgs` in guest.
      initrd.postMountCommands = ''
        mkdir -p "$targetRoot/${mount_guest_path}"
        mount -t 9p "${mount_tag}" "$targetRoot/${mount_guest_path}" -o trans=virtio,version=9p2000.L,cache=none
      '';

      # This is the functionality we want to test.
      loader.grub.extraGrubInstallArgs = [
        # "--modules=nativedisk ahci pata part_gpt part_msdos diskfilter mdraid1x lvm ext2"
      ];
    };

    environment.systemPackages = with pkgs; [
      git
      htop
      vim
    ];

    users.extraUsers.root.password = "";
    users.mutableUsers = false;

  };
}
