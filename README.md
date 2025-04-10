# packwiz2nix

A packwiz installer implementation in Nix.

`packwiz2nix` provides `buildPackwizModpack` and `fetchPackwizPackage` to help you create modpack from packwiz package.

## Difference between existing implementation

`fetchPackwizModpack` in [`nix-minecraft`](https://github.com/Infinidoge/nix-minecraft) uses `packwiz-installer` to create a FOD, so it needs hash of the final modpack. Instead, `buildPackwizModpack` parses packwiz package and download all the files by nix with hash in metadata.

[`getchoo/packwiz2nix`](https://github.com/getchoo/packwiz2nix) does not support fetch curseforge mods and requires to generate extra sha256 checksum. `buildPackwizModpack` generates download link according to curseforge file-id and filename and uses hash provided by packwiz (sha1 is supported).