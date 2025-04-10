{ lib, stdenvNoCC, fetchurl }:

{ url, name ? "pack", hash, ... }@args:

let
  readToml = t: builtins.fromTOML (builtins.readFile t);
  packFile = fetchurl { inherit url hash; };
  pack = readToml packFile;
  genHash = format: hash: { "${format}" = hash; };
  getParent = path:
    let
      components = lib.strings.splitString "/" path;
      prefix = lib.init components;
    in lib.strings.concatStringsSep "/" prefix;
  replaceName = path: name: (getParent path) + "/" + name;
  fixurl = url: builtins.replaceStrings [ " " ] [ "%20" ] url;
  indexFile = let inherit (pack) index;
  in fetchurl ({
    url = fixurl (replaceName url index.file);
  } // (genHash index.hash-format index.hash));
  index = readToml indexFile;
  files = map ({ file, hash, hash-format ? index.hash-format, ... }: {
    inherit file;
    downloaded = fetchurl
      ({ url = fixurl (replaceName url file); } // (genHash hash-format hash));
  }) index.files;
in stdenvNoCC.mkDerivation {
  pname = name;
  inherit (pack) version;

  dontUnpack = true;
  dontConfigure = true;

  installPhase = let concat = lib.strings.concatMapStringsSep "\n";
  in (''
    mkdir -p $out
    cp ${packFile} $out/pack.toml
    cp ${indexFile} $out/${pack.index.file}
  '' + (concat ({ downloaded, file }: ''
    mkdir -p "$out/${getParent file}"
    cp "${downloaded}" "$out/${file}"
  '') files));
} // (builtins.removeAttrs args [ "url" "name" "hash" ])
