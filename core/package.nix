{ lib, profile, config }: {
  mkPackage = name: {
    optional ? false,
    only ? [],
    except ? [],
    config ? {},
  }:
  let
    inherit (lib) types;
    isEmpty = list: builtins.length list == 0;
    cfg = config.packages.${name} or { inherit optional only except; };
    shouldInstall = (
      !cfg.optional &&
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
