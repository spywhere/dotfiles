{ lib, config, username, ... }:
{
  options.profile = lib.mkOption {
    type = lib.types.enum [ "work" "personal" ];
    default = "personal";
    description = "Profile to be used as a preset";
  };

  options.nixpkgs.add = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [];
    description = "Nixpkgs to be installed";
  };

  # TODO: Add support to start service after installation
  #   see https://nix-darwin.github.io/nix-darwin/manual/index.html#opt-homebrew.brews
  options.brew.add = lib.mkOption {
    type = lib.types.attrsOf (lib.types.listOf lib.types.str);
    default = { taps = []; formula = []; casks = []; };
    description = "Homebrew items to be installed";
  };

  config = {
    environment.systemPackages = config.nixpkgs.add;

    system.primaryUser = username;
    system.stateVersion = 6;

    homebrew = {
      enable = true;
      global.autoUpdate = true;
      taps = config.brew.add.taps;
      brews = config.brew.add.formula;
      casks = config.brew.add.casks;

      onActivation = {
        autoUpdate = true;
        cleanup = "zap";
      };
    };
  };
}
