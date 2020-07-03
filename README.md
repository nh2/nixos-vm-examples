# nixos-vm-examples

Some examples of how to declare VMs running [NixOS](https://nixos.org), building them with nix, and doing things inside.


## Motivation

NixOS makes it easy to build and run all kinds of VM images. This is especially when

* testing configuration changes before applying them to real hardware
* testing changes to NixOS code itself
* building reproducible environments for others to reproduce issues or results

While the individual NixOS modules involved are well-documented, a set of good examples can help you to build a VM for your use case.


## Examples

* [`grub-test-vm`](./grub-test-vm/):

    QEMU VM in which you can run `nixos-rebuild` to test changes to NixOS's GRUB bootloader installer.

Contributions of more examples are welcome!

They should be well-commented and contain running instructions for beginners (see the existing examples).


## Usage

Clone this repo with `git clone --recursive`, because it contains a submodule to pin `nixpkgs`.

After switching branches/commits, run `git submodule update --init --recursive` to ensure the submodule is updated.
Alternatively, run `./setup-git-hooks` to enable automatic submodule updating upon `git checkout` and `git rebase`.
