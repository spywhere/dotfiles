{ config, lib, pkgs, profile, ...}:
let
  package = import ../core/package.nix {
    inherit lib;
    inherit profile;
    inherit config;
  };
  inherit (package) mkPackage;
in mkPackage "curl" {
  config = {
    nixpkgs.add = [ pkgs.curl ];
  };
}
