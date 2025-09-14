{...}:
{
  imports = (import ../core/mkImports.nix) ./.;

  packages = {
    curl = {};
  };
}
