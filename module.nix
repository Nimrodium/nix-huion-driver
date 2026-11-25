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
  options.programs.huionDriver = with lib; {
    enable = mkEnableOption "Enable Huion tablet driver and udev rules";
    # to enable self user updating in case the flake is outdated.
    version = mkDefault "15.0.0.175";
    hash = mkDefault "UNKNOWN";
    useCN = mkDefault false;
    package = mkOption {
      type = types.package;
      default = pkgs.callPackage ./package.nix { inherit version hash useCN;};
      description = "The package of Huion tablet driver";
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
