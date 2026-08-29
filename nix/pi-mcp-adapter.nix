{
  fetchurl,
  importNpmLock,
  lib,
  makeWrapper,
  nodejs_24,
  stdenvNoCC,
}:

let
  version = "2.29.0";
  lockRoot = ./pi-mcp-adapter-lock;
  nodeModules = importNpmLock.buildNodeModules {
    npmRoot = lockRoot;
    nodejs = nodejs_24;
  };
in
stdenvNoCC.mkDerivation {
  pname = "pi-mcp-adapter";
  inherit version;

  src = fetchurl {
    url = "https://github.com/nicobailon/pi-mcp-adapter/archive/refs/tags/v${version}.tar.gz";
    hash = "sha256-MebMaqDhfkGjMcI8WTpvOvZqzMa6IwrL0EuSlkOKcc8=";
  };

  sourceRoot = "pi-mcp-adapter-${version}";
  nativeBuildInputs = [
    makeWrapper
    nodejs_24
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out" "$out/bin"
    cp package.json "$out/"
    node -e 'for (const file of require("./package.json").files) console.log(file)' |
      while IFS= read -r file; do
        cp -R "$file" "$out/"
      done
    cp -R ${nodeModules}/node_modules "$out/"

    makeWrapper ${nodejs_24}/bin/node "$out/bin/pi-mcp-adapter" \
      --add-flags "$out/cli.js"
    runHook postInstall
  '';

  meta = {
    description = "Token-efficient MCP adapter for Pi";
    homepage = "https://github.com/nicobailon/pi-mcp-adapter";
    license = lib.licenses.mit;
    mainProgram = "pi-mcp-adapter";
    platforms = lib.platforms.darwin ++ lib.platforms.linux;
  };
}
