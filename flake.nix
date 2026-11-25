{
  description = "Huion tablet linux driver and udev rules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      eachSystem = nixpkgs.lib.genAttrs [ "x86_64-linux" ];
    in
    {
      nixosModules = {
        huionDriver = import ./module.nix self;
        default = self.nixosModules.huionDriver;
      };

      overlays.default = import ./overlay.nix;

      packages = eachSystem (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

        in
        {
          # newpkg = pkgs.callPackage ./newpackage.nix {
          #   version = "15.0.0.175";
          #   hash = "sha256-sCUztiMQ+CVlM1SxaQa/5vcK417GSUxB6JgBoilsPAY=";
          #   useCN = false;
          # };

          huionDriver = pkgs.callPackage ./package.nix { version = "15.0.0.175"; hash = "sha256-sCUztiMQ+CVlM1SxaQa/5vcK417GSUxB6JgBoilsPAY="; useCN = false;};
          huionDriverCN = pkgs.callPackage ./package.nix { version = "15.0.0.C159"; hash = "sha256-iAcUBJxgQ5d35aROIxVJ2Dx/9nf70DBSwNYpmterpFo="; useCN = true; };

          default = self.packages.${system}.huionDriver;
        }
      );
    };
}
