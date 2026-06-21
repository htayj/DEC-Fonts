{
  description = "DEC VT220 bitmap fonts";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      sbclWithDepsFor = pkgs: pkgs.sbcl.withPackages (ps: [
        ps.array-operations
        ps.png
      ]);
      mkboldMkitalicFor = pkgs: pkgs.stdenv.mkDerivation rec {
        pname = "mkbold-mkitalic";
        version = "0.11";
        src = pkgs.fetchurl {
          url = "https://gitlab.com/unshumikan/mkbold-mkitalic/-/archive/${version}/mkbold-mkitalic-${version}.tar.bz2";
          hash = "sha256-995gi/tWKakJW+0ks9ndZQ8vm74QEysMcCctkPc7hA4=";
        };
        dontConfigure = true;
        buildPhase = ''
          runHook preBuild
          make
          runHook postBuild
        '';
        installPhase = ''
          runHook preInstall
          make prefix="$out" install
          install -Dm644 LICENSE "$out/share/licenses/mkbold-mkitalic/LICENSE"
          install -Dm644 README "$out/share/doc/mkbold-mkitalic/README"
          runHook postInstall
        '';
      };
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          sbclWithDeps = sbclWithDepsFor pkgs;
          mkboldMkitalic = mkboldMkitalicFor pkgs;
        in
        rec {
          dec-fonts = pkgs.stdenvNoCC.mkDerivation {
            pname = "dec-fonts";
            version = "0+git.${self.shortRev or self.dirtyShortRev or "local"}";
            src = self;
            strictDeps = true;
            nativeBuildInputs = [
              mkboldMkitalic
              pkgs.bdf2psf
              pkgs.fontconfig
              pkgs.python3
              sbclWithDeps
              pkgs.fonttosfnt
              pkgs.mkfontdir
              pkgs.mkfontscale
            ];
            dontConfigure = true;
            postPatch = ''
              patchShebangs scripts convert.bash
            '';
            buildPhase = ''
              runHook preBuild
              export HOME="$TMPDIR"
              export DEC_FONTS_ASDF_LOAD_MODE=asdf
              export BDF2PSF_EQUIVALENTS=${pkgs.bdf2psf}/share/bdf2psf/standard.equivalents
              export SOURCE_DATE_EPOCH=''${SOURCE_DATE_EPOCH:-1731361680}
              ./scripts/build-fonts.sh
              runHook postBuild
            '';
            installPhase = ''
              runHook preInstall
              install -d \
                "$out/share/fonts/dec-fonts/bdf" \
                "$out/share/fonts/dec-fonts/otb" \
                "$out/share/kbd/consolefonts/dec-fonts"
              install -m 0644 dist/fonts/bdf/*.bdf "$out/share/fonts/dec-fonts/bdf/"
              install -m 0644 dist/fonts/bdf/fonts.dir dist/fonts/bdf/fonts.scale "$out/share/fonts/dec-fonts/bdf/"
              install -m 0644 dist/fonts/otb/*.otb "$out/share/fonts/dec-fonts/otb/"
              install -m 0644 dist/fonts/psf/*.psf "$out/share/kbd/consolefonts/dec-fonts/"
              install -Dm644 dist/dec.set "$out/share/dec-fonts/dec.set"
              install -Dm644 README.org "$out/share/doc/dec-fonts/README.org"
              install -d "$out/share/fontconfig/conf.avail" "$out/etc/fonts/conf.d"
              cat > "$out/share/fontconfig/conf.avail/75-dec-fonts.conf" <<XML
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <description>DEC VT220 bitmap fonts</description>
  <dir>$out/share/fonts/dec-fonts</dir>
  <dir>$out/share/fonts/dec-fonts/bdf</dir>
  <dir>$out/share/fonts/dec-fonts/otb</dir>
  <selectfont>
    <acceptfont>
      <pattern>
        <patelt name="family"><string>vt220</string></patelt>
      </pattern>
    </acceptfont>
  </selectfont>
</fontconfig>
XML
              ln -s "$out/share/fontconfig/conf.avail/75-dec-fonts.conf" \
                "$out/etc/fonts/conf.d/75-dec-fonts.conf"
              runHook postInstall
            '';
            meta = with pkgs.lib; {
              description = "DEC VT220 bitmap fonts";
              homepage = "https://github.com/htayj/DEC-Fonts";
              license = licenses.mit;
              platforms = platforms.linux;
            };
          };
          default = dec-fonts;
        });

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          sbclWithDeps = sbclWithDepsFor pkgs;
          mkboldMkitalic = mkboldMkitalicFor pkgs;
        in
        {
          default = pkgs.mkShell {
            packages = [
              mkboldMkitalic
              pkgs.bdf2psf
              pkgs.fontconfig
              pkgs.gnumake
              pkgs.python3
              sbclWithDeps
              pkgs.fonttosfnt
              pkgs.mkfontdir
              pkgs.mkfontscale
            ];
            DEC_FONTS_ASDF_LOAD_MODE = "asdf";
            BDF2PSF_EQUIVALENTS = "${pkgs.bdf2psf}/share/bdf2psf/standard.equivalents";
            shellHook = ''
              echo "DEC-Fonts dev shell: run make fonts or nix build .#dec-fonts"
            '';
          };
        });

      checks = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.runCommand "dec-fonts-nix-check" {
            nativeBuildInputs = [
              pkgs.coreutils
              pkgs.findutils
              pkgs.fontconfig
              pkgs.gnugrep
            ];
          } ''
            package=${self.packages.${system}.dec-fonts}
            test -s "$package/share/dec-fonts/dec.set"
            test -d "$package/share/fonts/dec-fonts/bdf"
            test -d "$package/share/fonts/dec-fonts/otb"
            test -d "$package/share/kbd/consolefonts/dec-fonts"
            test -s "$package/share/fonts/dec-fonts/bdf/fonts.dir"
            test -s "$package/share/fonts/dec-fonts/bdf/fonts.scale"
            otb_file=$(find "$package/share/fonts/dec-fonts/otb" -maxdepth 1 -type f -name '*.otb' | sort | head -n 1)
            test -n "$otb_file"
            fc-query --format 'family=%{family}\nfullname=%{fullname}\nfoundry=%{foundry}\nfontformat=%{fontformat}\n' "$otb_file" > "$out"
            grep -Eiq 'vt220|digital|digi' "$out"
          '';
        });
    };
}
