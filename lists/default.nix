{ lib }:
let
  inherit (lib) filterAttrs;
  inherit (builtins) readDir attrNames;
  moduleFolderNames = attrNames (filterAttrs (n: v: v == "directory") (readDir (toString ./.)));
  moduleFolderPaths = map (x: (toString ./.) + "/" + x) moduleFolderNames;
in
{ services = (map (n: import n { inherit lib; name = baseNameOf n; }) moduleFolderPaths); }
