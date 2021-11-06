{ nodejs_latest, mkZixDerivation, writeScriptBin, which }:

mkZixDerivation {
  name = "hello-world";
  buildInputs = [ nodejs_latest which ];
  # I would demonstrate with which zx if it wasn't for this bug:
  # https://github.com/google/zx/issues/248
  buildPhase = ''
    const helloWorld = `#!''${await $`which zx`}
     console.log('wazzup world!');
    `;
    await fs.writeFile("hello-world.mjs", helloWorld);
    await $`chmod +x hello-world.mjs`
  '';

  installPhase = ''
    await fs.mkdirp(process.env.out + "/bin");
    await fs.move("hello-world.mjs", process.env.out + "/bin/hello-world.mjs");
  '';
}
