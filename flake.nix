{
  description = "A packwiz installer implementation in Nix";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages = {
          buildPackwizModpack = pkgs.callPackage ./buildPackwizModpack.nix { };
          fetchPackwizPackage = pkgs.callPackage ./fetchPackwizPackage.nix { };
        };
      });
}
