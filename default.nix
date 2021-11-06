pkgs:

let
  nodejs = pkgs.nodejs_latest;
  nodeEnv = import ./node-env.nix {
    inherit (pkgs) stdenv lib python2 runCommand writeTextFile writeShellScript;
    inherit pkgs nodejs;
    libtool = if pkgs.stdenv.isDarwin then pkgs.darwin.cctools else null;
  };
  nodePkgs = import ./node-packages.nix {
    inherit (pkgs) fetchurl nix-gitignore stdenv lib fetchgit;
    inherit nodeEnv;
  };
  zx = nodePkgs.zx.override {
    dontNpmInstall = true;
    postInstall = ''
      mkdir -p $out/bin
      ln -s $out/lib/node_modules/zx/zx.mjs $out/bin/zx
    '';
  };
  zix-builder = { zxShell }: pkgs.writeTextFile {
    name = "zix-builder";
    executable = true;
    text = ''#!${toString zx}/bin/zx --shell=${zxShell}
      // fix: strangely .cwd() returns undefined by default
      process.env.pwd = process.env.PWD;
      process.chdir(process.env.pwd);

      const buildPhase = process.argv[3];
      const installPhase = process.argv[4];
      const checkPhase = process.argv[5];
      let __phaseCnt = 0;
      async function runHook(phase) {
        if (phase) {
          __phaseCnt += 1;
          await fs.writeFile(".zix-hook.mjs", phase);
          await import("file://" + process.cwd() + "/.zix-hook.mjs?cnt=" + __phaseCnt);
        }
      }

      await runHook(buildPhase);
      await runHook(installPhase);
      await runHook(checkPhase);
    '';
  };
in {
  mkZixDerivation = {
      name,
      buildInputs ? [],
      buildPhase ? "",
      installPhase ? "",
      checkPhase ? "",
      zxShell ? "${pkgs.bash}/bin/bash"
  }:
    let path = (pkgs.lib.makeBinPath
      ([ zx pkgs.coreutils ] ++ buildInputs));
    in derivation {
      inherit buildInputs name path;
      system = builtins.currentSystem;
      builder = "${zx}/bin/zx";
      args = [
        (zix-builder { inherit zxShell; })
        buildPhase
        installPhase
        checkPhase
      ];
      PATH = path;
    };
}
