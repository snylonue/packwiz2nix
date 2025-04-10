{
  description = "A packwiz installer implementation in Nix";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages = {
          buildPackwizModpack = pkgs.callPackage ./buildPackwizModpack.nix { };
          fetchPackwizPackage = pkgs.callPackage ./fetchPackwizPackage.nix { };
          gto = self.packages.${system}.fetchPackwizPackage {
            url =
              "https://github.com/GregTech-Odyssey/GregTech-Odyssey/raw/refs/heads/main/pack.toml";
            hash = "sha256-cEiyNcpcDX3INHHPvPD0VNfXCS7oHTXtkQSPsyEkuhI=";
          };
        };
      });
}
