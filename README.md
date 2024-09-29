# Usage

Simply `nix build .#images.pi` and flash the result with `zstdcat` to an SD Card

If wanting to deploy changes

`nixos-rebuild switch --flake .#pi --target-host username@remote-host`
