{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    doorbots-config = {
      url = "git+ssh://git@github.com/DoESLiverpool/doorbots-config.git";
      flake = false;
    };
  };
  outputs = { ... }@inputs: rec {
    images = {
      pi = (inputs.self.nixosConfigurations.pi.extendModules {
        modules = [
          "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
          {
            disabledModules = [ "profiles/base.nix" ];
          }
        ];
      }).config.system.build.sdImage;
    };
    packages.x86_64-linux.pi-image = images.pi;
    packages.aarch64-linux.pi-image = images.pi;
    nixosConfigurations = {
      pi = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        system = "aarch64-linux";
        modules = [
          inputs.nixos-hardware.nixosModules.raspberry-pi-3
          "${inputs.nixpkgs}/nixos/modules/profiles/minimal.nix"
          ./configuration.nix
          ./base.nix
        ];
      };
    };
  };
}

