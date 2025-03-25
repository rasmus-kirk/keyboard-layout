{
  description = "My keyboard layout.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.klfc.url = "github:rasmus-kirk/klfc";

  outputs = {
    nixpkgs,
    klfc,
    ...
  }: let
    supportedSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forAllSystems = f:
      nixpkgs.lib.genAttrs supportedSystems (system:
        f {
          pkgs = import nixpkgs {inherit system;};
        });
  in {
    formatter = forAllSystems ({pkgs}: pkgs.alejandra);

    packages = forAllSystems ({pkgs}: let
      klfcPkg = klfc.packages.${pkgs.system}.default;
      rk = pkgs.stdenv.mkDerivation rec {
        name = "rk";
        src = ./.;
        buildInputs = [ klfcPkg ];
        phases = ["unpackPhase" "buildPhase"];
        buildPhase = ''
          mkdir -p $out
          ${pkgs.lib.getExe klfcPkg} --from-json ${./rk.json} --xkb "$out"

          # Make a wrapper script, so we can run `nix run`
          mkdir $out/bin
          echo -e "#!/usr/bin/env bash\ncd $out; ./install-system.sh" > "$out/bin/${name}"
          chmod 555 $out/bin/${name}
        '';
      };
      zi = pkgs.stdenv.mkDerivation rec {
        name = "zi";
        src = ./.;
        buildInputs = [ klfcPkg ];
        phases = ["unpackPhase" "buildPhase"];
        buildPhase = ''
          mkdir -p $out
          ${pkgs.lib.getExe klfcPkg} --from-json ${./zi.json} --xkb "$out"

          # Make a wrapper script, so we can run `nix run`
          mkdir $out/bin
          ln -s "$out/install-system.sh" "$out/bin/${name}" 
        '';
      };
      in {
        rk = rk;
        zi = zi;
        default = rk;
      });
  };
}
