{
  description = "Personal modular flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable"; # nixos-25.05
    flake-utils.url = "github:numtide/flake-utils";

    darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{
    flake-utils,
    ...
  }:
  let
    profile = import ./core/profile.nix (builtins.removeAttrs inputs [ "self" ]);
    inherit (profile) mkProfiles;
    inherit (flake-utils.lib) system;

    profiles = [
      { name = "personal"; system = system.aarch64-darwin; username = "spywhere"; }
      { name = "work"; system = system.aarch64-darwin; username = "slueangsaksr"; }
    ];
  in mkProfiles { inherit profiles; };
}
