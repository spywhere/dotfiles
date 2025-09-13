{ lib, profile, config }: {
  mkPackage = name: spec:
  let
    inherit (lib) types;
    cfg = config.packages.${name};
    shouldInstall = !cfg.optional && (
      (lib.elem profile cfg.only) ||
      (!(lib.elem profile cfg.except))
    );
  in {
    options.packages.${name} = {
      optional = lib.mkOption {
        type = types.bool;
        default = false;
      };
      only = lib.mkOption {
        type = types.listOf types.str;
        default = [];
      };
      except = lib.mkOption {
        type = types.listOf types.str;
        default = [];
      };
    };

    config = lib.mkIf shouldInstall spec;
  };
}
