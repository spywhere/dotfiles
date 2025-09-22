{
  nixpkgs,
  darwin,
  homebrew,
  flake-utils,
  ...
}:
rec {
  systems = flake-utils.lib.system;
  inherit (nixpkgs) lib;

  mkProfile = {
    name,
    system ? systems.aarch64-darwin, # TODO: Check if we could inferred from builtins.currentSystem
    username, # TODO: Check if we could inferred from builtins.getEnv "USER"
  }:
  let
    isDarwin = lib.hasSuffix "-darwin" system;
    profile = name;

    modules = [
      ./.
    ] ++ ((import ./mkImports.nix) ../packages);
  in
    if isDarwin then
      {
        darwinConfigurations.${name} = darwin.lib.darwinSystem {
          inherit system;
          specialArgs = { inherit profile username isDarwin; };
          modules = modules ++ [
            homebrew.darwinModules.nix-homebrew {
              inherit lib;
              nix-homebrew = {
                enable = true;
                user = username;
              };
            }
          ];
        };
      }
    else
      {
        nixosConfigurations.${name} = nixpkgs.lib.nixosSystem {
          inherit system modules;
          specialArgs = { inherit profile username; };
        };
      };
  mkProfiles = {
    profiles
  }: lib.foldl' lib.recursiveUpdate {} (map mkProfile profiles);
}
