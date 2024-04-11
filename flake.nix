{
  description = "A command line based editor inspired by Vim.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # <https://github.com/nix-systems/nix-systems>
    systems.url = "github:nix-systems/default-linux";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    systems,
    ...
  }: let
    inherit (nixpkgs) lib;
    eachSystem = lib.genAttrs (import systems);
    pkgsFor = eachSystem (system:
      import nixpkgs {
        localSystem = system;
        overlays = with self.overlays; [
          hyprland-packages
          hyprland-extras
        ];
      });
  in {
    overlays = import ./nix/overlays.nix {inherit self lib inputs;};

    checks = eachSystem (system:
      (lib.filterAttrs
        (n: _: (lib.hasPrefix "moe" n))
        self.packages.${system})
      // {
        inherit (self.packages.${system}) xdg-desktop-portal-hyprland;
      });

    packages = eachSystem (system: {
      default = self.packages.${system}.hyprland;
      inherit
        (pkgsFor.${system})
        # moe-packages
	moe
        ;
    });

    devShells = eachSystem (system: {
      default =
        pkgsFor.${system}.mkShell.override {
          stdenv = pkgsFor.${system}.gcc13Stdenv;
        } {
          name = "moe-shell";
          nativeBuildInputs = with pkgsFor.${system}; [
	    nim
	    ncurses.dev
	  ];
        };
    });

    formatter = eachSystem (system: nixpkgs.legacyPackages.${system}.alejandra);
  };
}
