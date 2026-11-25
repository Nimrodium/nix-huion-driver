self:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;

  # driver-default = self.packages.${system}.default;
  cfg = config.programs.huionDriver;
in
{

  options.programs.huionDriver = {
    enable = lib.mkEnableOption "Huion tablet driver and udev rules";

    version = lib.mkOption {
      type = lib.types.str;
      default = "15.0.0.175";
    };

    hash = lib.mkOption {
      type = lib.types.str;
      default = lib.fakeHash;
    };

    useCN = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix {
        inherit (cfg) version hash useCN;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    services.udev.packages = [ cfg.package ];

    # services.udev.extraRules = ''
    #   KERNEL=="uinput", MODE="0666"
    # '';
  };
}
