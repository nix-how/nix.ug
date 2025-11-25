{ lib, name }:
let
  inherit (lib) filterAttrs;
  inherit (builtins) readDir attrNames;
  moduleFolderNames = attrNames (filterAttrs (n: v: v == "directory") (readDir (toString ./.)));
  moduleFolderPaths = map (x: (toString ./.) + "/" + x) moduleFolderNames;
  find = pattern: dir: (builtins.filter
    (x: ((builtins.match pattern (toString x)) != null))
      (lib.filesystem.listFilesRecursive dir)
  );
in
{
  inherit name;
  items = map (n: (import n) // rec { icon = if logo == "" then "fas fa-snowflake" else ""; logo = if ((find ".+logo\.+" n) == []) then "" else "assets/${baseNameOf n}/${baseNameOf (toString (map toString (find ".+logo\.+" n)))}"; } ) moduleFolderPaths;
}
