dir:
let
  isValidNix = name: name != "default.nix" && builtins.match ".*\\.nix" name != null;

  entries = builtins.attrNames (builtins.readDir dir);
  files = builtins.filter isValidNix entries;
in
  map (name: dir + ("/" + name)) files
