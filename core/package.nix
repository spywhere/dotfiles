{ lib, profile, config, isDarwin }: {
  mkPackage = name: {
    optional ? false,
    only ? [],
    except ? [],
    platform ? [],
    config ? {},
  }:
  let
    inherit (lib) types;
    systemPlatform = if isDarwin then "darwin" else "linux";
    isEmpty = list: builtins.length list == 0;
    cfg = config.packages.${name} or { inherit optional only except platform; };
    shouldInstall = (
      !cfg.optional &&
      (isEmpty cfg.platform || lib.elem systemPlatform cfg.platform) &&
      (isEmpty cfg.only || lib.elem profile cfg.only) &&
      !(lib.elem profile cfg.except)
    );
  in {
    options.packages.${name} = {
      optional = lib.mkOption {
        type = types.bool;
        default = optional;
        description = "A flag indicated that only install when explicitly asked";
      };
      only = lib.mkOption {
        type = types.listOf types.str;
        default = only;
        description = "Allowed profiles (empty = all)";
      };
      except = lib.mkOption {
        type = types.listOf types.str;
        default = except;
        description = "Excluded profiles.";
      };
      platform = lib.mkOption {
        type = types.listOf types.str;
        default = platform;
        description = "Allowed platforms (empty = all).";
      };
    };

    config = lib.mkMerge [
      {
        assertions = [
          {
            assertion = !(lib.elem profile cfg.except && lib.elem profile cfg.only);
            message = "Package '${name}': profile '${profile}' is both included (only) and excluded (except).";
          }
        ];
      }

      (lib.mkIf shouldInstall config)
    ];
  };
}
