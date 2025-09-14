{
  nixpkgs,
  darwin,
  home-manager,
  ...
}:
rec {
  inherit (nixpkgs) lib;
  mkProfile = {
    name,
    system, # TODO: Check if we could inferred from builtins.currentSystem
    username, # TODO: Check if we could inferred from builtins.getEnv "USER"
    mode ? "auto"
  }:
  let
    isAuto = mode == "auto";
    isDarwin = isAuto && lib.hasSuffix "-darwin" system;
    isNixos = isAuto && lib.hasSuffix "-linux" system;
    homePath = if isDarwin then "/Users/${username}" else "/home/${username}";
    profile = name;

    modules = [
      ./.
    ] ++ ((import ./mkImports.nix) ../packages) ++ [
      (
        if isAuto then
          if isDarwin then
            home-manager.darwinModules.home-manager
          else
            home-manager.nixosModules.home-manager
          {
            home-manager.users.${username} = {
              # imports = [];

              # For backward compatibility, see home-manager changelog before changing it
              home.stateVersion = "25.05";

              _module.args.profile = profile;
            };
            users.users.${username}.home = homePath;
          }
        else
        {
          home = {
            inherit username;
            homeDirectory = homePath;
          };
        }
      )
    ];
  in
    if isDarwin then
      {
        darwinConfigurations.${name} = darwin.lib.darwinSystem {
          inherit system modules;
          specialArgs = { inherit profile username; };
        };
      }
    else if isNixos then
      {
        nixosConfigurations.${name} = nixpkgs.lib.nixosSystem {
          inherit system modules;
          specialArgs = { inherit profile username; };
        };
      }
    else
      {
        homeConfigurations.${name} = home-manager.lib.homeManagerConfiguration {
          inherit system username modules;
          pkgs = import nixpkgs { inherit system; };
          extraSpecialArgs = { inherit profile username; };
        };
      };
  mkProfiles = {
    profiles
  }: lib.foldl' lib.recursiveUpdate {} (map mkProfile profiles);
}
