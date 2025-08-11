{ lib, stdenvNoCC, fetchurl, writeScript }:

{ src, name ? "modpack", side ? "server", allowMissingFile ? false
, allowMissingFilePred ? _: allowMissingFile, ... }@args:

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
in stdenvNoCC.mkDerivation ({
  inherit src;
  inherit (pack) version;
  pname = name;

  dontConfigure = true;

  installPhase = let
    concat = lib.strings.concatMapStringsSep "\n";
    script = (''
      mkdir -p $out
    '' + (concat (f: ''
      mkdir -p "$out/${getParent f}"
      cp "./${f}" "$out/${f}"${
        lib.optionalString (allowMissingFilePred f) " || true"
      }
    '') staticFiles) + (concat ({ path, file, ... }: ''
      mkdir -p "$out/${getParent path}"
      ln -s "${file}" "$out/${path}"${
        lib.optionalString (allowMissingFilePred path) " || true"
      }
    '') metaFiles));
  in "${writeScript "install" script}";
} // (builtins.removeAttrs args [
  "src"
  "name"
  "side"
  "allowMissingFile"
  "allowMissingFilePred"
]))
