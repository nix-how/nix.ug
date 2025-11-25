{ lib }:
let
  inherit (lib) filterAttrs;
  inherit (builtins) readDir attrNames;
  moduleFolderNames = [
    "Conferences"
    "Sprints"
    "NUGs"
  ];
  moduleFolderPaths = map (x: (toString ./.) + "/" + x) moduleFolderNames;
in
{ services = (map (n: import n { inherit lib; name = baseNameOf n; }) moduleFolderPaths); }
