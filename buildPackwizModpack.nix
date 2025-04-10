{ lib, stdenvNoCC, fetchurl }:

{ src, name ? "modpack", side ? "server", ... }@args:

let
  readToml = t: builtins.fromTOML (builtins.readFile t);
  getParent = path:
    let
      components = lib.strings.splitString "/" path;
      prefix = lib.init components;
    in lib.strings.concatStringsSep "/" prefix;
  replaceName = path: name: (getParent path) + "/" + name;
  fetchMetaFile = { filename, download, ... }@f:
    fetchurl {
      name = filename;
      "${download.hash-format}" = "${download.hash}";
      url = builtins.replaceStrings [ " " ] [ "%20" ]
        (if builtins.hasAttr "url" download then
          download.url
        else
          let file-id = toString f.update.curseforge.file-id;
          in "https://edge.forgecdn.net/files/${
            builtins.substring 0 4 file-id
          }/${
            builtins.substring 4 (builtins.stringLength file-id - 4) file-id
          }/${filename}");
    };
  pack = readToml "${src}/pack.toml";
  index = readToml "${src}/${pack.index.file}";
  partition =
    lib.lists.partition ({ metafile ? false, ... }: metafile) index.files;
  metaFiles = builtins.filter (f: f.side == "both" || f.side == side) (map
    ({ file, ... }:
      let f = readToml "${src}/${file}";
      in {
        path = replaceName file f.filename;
        file = fetchMetaFile f;
        inherit (f) side;
      }) partition.right);
  staticFiles = map ({ file, ... }: file) partition.wrong;
in stdenvNoCC.mkDerivation {
  pname = name;
  inherit (pack) version;

  dontUnpack = true;
  dontConfigure = true;

  installPhase = let concat = lib.strings.concatMapStringsSep "\n";
  in (''
    mkdir -p $out
  '' + (concat (f: ''
    mkdir -p "$out/${getParent f}"
    cp "${src}/${f}" "$out/${f}"
  '') staticFiles) + (concat ({ path, file, ... }: ''
    mkdir -p "$out/${getParent path}"
    ln -s "${file}" "$out/${path}"
  '') metaFiles));
} // (builtins.removeAttrs args [ "src" "name" "side" ])

