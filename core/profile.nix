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

    hm = if isDarwin then home-manager.darwinModules.home-manager else home-manager.nixosModules.home-manager;

    modules = [
      ./.
    ] ++ ((import ./mkImports.nix) ../packages) ++ [
      hm {
        users.users.${username} = {
          name = username;
          home = homePath;
        };

        home-manager = {
          useGlobalPkgs = true;

          users.${username} = {
            # imports = [];

            home = {
              inherit username;
              homeDirectory = homePath;
              # For backward compatibility, see home-manager changelog before changing it
              stateVersion = "25.05";

            };
            programs.home-manager.enable = true;

            _module.args.profile = profile;
          };
        };
      }
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
