{ lib, pkgs, profile, config, ...}:
{
  options.packages.curl = {};
  config = {
    nixpkgs.add = [ pkgs.curl ];
  };
}
