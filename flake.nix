{
    description = "Zig - master";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        flake-utils.url = "github:numtide/flake-utils";
        zig.url = "github:mitchellh/zig-overlay";
    };

    outputs = { self, nixpkgs, flake-utils, ... } @ inputs:
    let
        overlays = [
            (final: prev: {
                zig = inputs.zig.packages.${prev.system}.master;
            })
        ];

        systems = builtins.attrNames inputs.zig.packages;
    in
    flake-utils.lib.eachSystem systems
        ( system:
            let
                pkgs = import nixpkgs {inherit overlays system;};
            in
            # rec
            {
                devShells.default = pkgs.mkShell {
                    nativeBuildInputs = with pkgs; [
                        zig
                    ];
                };
            }
        );
}
