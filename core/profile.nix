{
  nixpkgs,
  darwin,
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
    homePath = if isDarwin then "/Users/${username}" else "/home/${username}";
    profile = name;

    modules = [
      ./.
    ] ++ ((import ./mkImports.nix) ../packages);
  in
    if isDarwin then
      {
        darwinConfigurations.${name} = darwin.lib.darwinSystem {
          inherit system modules;
          specialArgs = { inherit profile username; };
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
