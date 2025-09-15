{
  description = "Personal modular flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable"; # nixos-25.05
    flake-utils.url = "github:numtide/flake-utils";

    darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
  let
    profile = import ./core/profile.nix (builtins.removeAttrs inputs [ "self" ]);
    inherit (profile) mkProfiles;

    profiles = [
      { name = "personal"; username = "spywhere"; }
      { name = "work"; username = "slueangsaksr"; }
    ];
  in mkProfiles { inherit profiles; };
}
