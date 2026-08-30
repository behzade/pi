{
  description = "Behzad's reviewed Pi coding-agent extensions";

  inputs.piNono.url = "github:behzade/pi-nono";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs =
    {
      nixpkgs,
      piNono,
      self,
    }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: import nixpkgs { inherit system; };
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          coreExtensions = pkgs.callPackage ./nix/pi-core-extensions.nix { };
          mcpAdapter = pkgs.callPackage ./nix/pi-mcp-adapter.nix { };
          sandbox = piNono.packages.${system}.default;
          denseTools = pkgs.callPackage ./nix/pi-dense-tools.nix { };
          openaiServerCompaction = pkgs.callPackage ./nix/pi-openai-server-compaction.nix { };
          projectTools = pkgs.callPackage ./nix/pi-project-tools.nix { };
          piTerminal = pkgs.callPackage ./nix/pi-terminal.nix { };
          pi = piTerminal;
          agent = pkgs.callPackage ./nix/pi-agent.nix {
            inherit
              coreExtensions
              denseTools
              mcpAdapter
              openaiServerCompaction
              piTerminal
              projectTools
              sandbox
              ;
          };
        in
        {
          inherit agent sandbox;
          core-extensions = coreExtensions;
          inherit pi;
          pi-terminal = piTerminal;
          mcp-adapter = mcpAdapter;
          dense-tools = denseTools;
          openai-server-compaction = openaiServerCompaction;
          project-tools = projectTools;
          default = agent;
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              git
              nix
              nixfmt-tree
              neovim
              nodejs
            ];
          };
        }
      );

      checks = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          coreExtensions = pkgs.callPackage ./nix/pi-core-extensions.nix { };
          denseTools = pkgs.callPackage ./nix/pi-dense-tools.nix { };
          mcpAdapter = pkgs.callPackage ./nix/pi-mcp-adapter.nix { };
          sandbox = piNono.packages.${system}.default;
          openaiServerCompaction = pkgs.callPackage ./nix/pi-openai-server-compaction.nix { };
          projectTools = pkgs.callPackage ./nix/pi-project-tools.nix { };
          piTerminal = pkgs.callPackage ./nix/pi-terminal.nix { };
          agent = pkgs.callPackage ./nix/pi-agent.nix {
            inherit
              coreExtensions
              denseTools
              mcpAdapter
              openaiServerCompaction
              piTerminal
              projectTools
              sandbox
              ;
          };
        in
        {
          agent-extension-layout = pkgs.runCommand "pi-agent-extension-layout-test" {
            nativeBuildInputs = [ piTerminal ];
          } ''
            test -f ${agent}/extensions/node_modules/effect/package.json
            test "$(readlink ${agent}/extensions/node_modules)" = ${coreExtensions}/node_modules
            test "$(readlink ${agent}/extensions/sandbox)" = ${sandbox}
            test -f ${agent}/extensions/sandbox/index.ts
            test -f ${agent}/extensions/pi-mcp-adapter/index.ts
            test -f ${agent}/extensions/codex-web-search.ts
            test -f ${agent}/extensions/lib/codex-web-search-core.ts
            test ! -e ${agent}/extensions/codex-web-search-core.ts
            test -f ${agent}/extensions/sandbox/node_modules/effect/package.json
            mkdir home
            HOME="$PWD/home" PI_OFFLINE=1 pi --no-extensions -e ${sandbox}/index.ts --list-models >/dev/null
            test -L ${agent}/prompts
            test -f ${agent}/prompts/commit.md
            test -f ${agent}/skills/mcp-scripting/SKILL.md
            touch "$out"
          '';
          core-extensions = pkgs.runCommand "pi-core-extensions-test" { nativeBuildInputs = [ pkgs.nodejs ]; } ''
            cp -R ${coreExtensions}/* .
            chmod -R u+w node_modules
            mkdir -p node_modules/@earendil-works
            ln -s ${piTerminal}/lib/pi-terminal/node_modules/@earendil-works/pi-ai node_modules/@earendil-works/pi-ai
            ln -s ${piTerminal}/lib/pi-terminal/node_modules/@earendil-works/pi-coding-agent node_modules/@earendil-works/pi-coding-agent
            ln -s ${piTerminal}/lib/pi-terminal/node_modules/typebox node_modules/typebox
            timeout 60 node --experimental-strip-types -e '
              await Promise.all([
                import("./notifications.ts"),
                import("./codex-web-search.ts"),
                import("./prompt-inspector.ts"),
                import("./session-hooks.ts"),
                import("./title-state.ts"),
                import("./user-input.ts"),
                import("./user-invocations.ts"),
              ])
            '
            touch "$out"
          '';

          mcp-adapter = pkgs.runCommand "pi-mcp-adapter-test" { nativeBuildInputs = [ piTerminal pkgs.nodejs ]; } ''
            test "$(node -p 'require(\"${mcpAdapter}/package.json\").version')" = "2.29.0"
            test -f ${mcpAdapter}/node_modules/@modelcontextprotocol/client/package.json
            mkdir home
            HOME="$PWD/home" PI_OFFLINE=1 pi --no-extensions -e ${mcpAdapter}/index.ts --list-models >/dev/null
            touch "$out"
          '';
          dense-tools = pkgs.runCommand "pi-dense-tools-test" { nativeBuildInputs = [ denseTools ]; } ''
            mkdir before after empty-before empty-after
            printf '%s\n' '{ lib, ... }:' 'let' '  oldValue = "before";' 'in' '{ inherit oldValue; }' > before/sample.nix
            printf '%s\n' '{ lib, ... }:' 'let' '  newValue = "after";' 'in' '{ inherit newValue; }' > after/sample.nix

            PI_DIFF_CACHE_DIR="$PWD/cache" PI_DIFF_CACHE_TRACE=1 pi-diff --width=140 before after > split 2> first-cache
            grep -F 'pi-diff cache miss' first-cache
            grep -F 'sample.nix' split
            grep -F '│' split
            grep -F $'\033[38;2;251;73;52' split

            PI_DIFF_CACHE_DIR="$PWD/cache" PI_DIFF_CACHE_TRACE=1 pi-diff --width=140 before after > split-cached 2> second-cache
            grep -F 'pi-diff cache hit' second-cache
            cmp split split-cached

            PI_DIFF_CACHE_DIR="$PWD/cache" pi-diff --width=80 before after > unified
            grep -F 'sample.nix' unified
            if grep -F '│' unified; then
              echo "narrow diffs must use the unified layout" >&2
              exit 1
            fi

            pi-diff empty-before empty-after > empty
            test ! -s empty
            touch "$out"
          '';
          pi-terminal = pkgs.runCommand "pi-terminal-test" { nativeBuildInputs = [ piTerminal ]; } ''
            test "$(pi --version)" = "0.84.2"
            touch "$out"
          '';
          openai-server-compaction-tests = pkgs.runCommand "pi-openai-server-compaction-tests" {
            nativeBuildInputs = [ pkgs.nodejs ];
          } ''
            cp -R ${openaiServerCompaction}/src ${openaiServerCompaction}/node_modules .
            chmod -R u+w node_modules
            mkdir -p node_modules/@earendil-works test
            ln -s ${piTerminal}/lib/pi-terminal/node_modules/@earendil-works/pi-agent-core node_modules/@earendil-works/pi-agent-core
            ln -s ${piTerminal}/lib/pi-terminal/node_modules/@earendil-works/pi-ai node_modules/@earendil-works/pi-ai
            ln -s ${piTerminal}/lib/pi-terminal/node_modules/@earendil-works/pi-coding-agent node_modules/@earendil-works/pi-coding-agent
            cp ${self}/extensions/openai-server-compaction/test/*.test.ts test/
            timeout 60 node --experimental-strip-types -e 'import("./src/index.ts")'
            timeout 60 node --experimental-strip-types --test test/openai-ws-connection.test.ts
            timeout 60 node --experimental-strip-types --test test/openai-ws-stream.test.ts
            timeout 60 node --experimental-strip-types --test test/continuation-compaction.test.ts
            touch "$out"
          '';
          project-tools-tests = pkgs.runCommand "pi-project-tools-tests" {
            nativeBuildInputs = [ pkgs.nodejs ];
          } ''
            cp -R ${projectTools}/src ${projectTools}/node_modules .
            mkdir test
            cp ${self}/extensions/project-tools/test/project-tools.test.ts test/
            node --experimental-strip-types --test test/project-tools.test.ts
            touch "$out"
          '';
          governance = pkgs.runCommand "pi-governance-tests" { nativeBuildInputs = [ pkgs.nodejs ]; } ''
            node --test \
              ${self}/tests/governance.test.ts \
              ${self}/tests/codex-web-search.test.ts \
              ${self}/tests/prompt-contract.test.ts \
              ${self}/tests/prompt-inspector.test.ts \
              ${self}/tests/theme-and-rendering.test.ts \
              ${self}/tests/theme-selection.test.ts \
              ${self}/tests/tui-only.test.ts \
              ${self}/tests/terminal-text.test.ts \
              ${self}/tests/user-invocations.test.ts
            touch "$out"
          '';
        }
      );

      formatter = forAllSystems (system: (pkgsFor system).nixfmt-tree);
    };
}
