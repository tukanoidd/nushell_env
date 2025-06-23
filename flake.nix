{
  description = "Nushell env setup";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    nci = {
      url = "github:yusdacra/nix-cargo-integration";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        parts.follows = "parts";
      };
    };

    nushell = {
      url = "github:nushell/nushell";
      flake = false;
    };
    plugins = {
      url = "github:tukanoidd/nushell_plugins";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nci.follows = "nci";
        parts.follows = "parts";
      };
    };
    scripts.url = "github:tukanoidd/nushell_scripts";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    parts,
    nci,
    ...
  }:
    (parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux"];
      imports = [
        nci.flakeModule
      ];
      perSystem = {
        pkgs,
        config,
        ...
      }: let
        crateOutputs = config.nci.outputs.nu-cli;
      in {
        nci = {
          projects.nushell = {
            path = inputs.nushell;
          };

          crates = {
            "nu-cli" = {
              drvConfig = {
                mkDerivation = with pkgs; {
                  nativeBuildInputs = [pkg-config python3];

                  buildInputs = [
                    openssl
                    zstd
                    xorg.libX11
                  ];

                  checkPhase = ''
                    runHook preCheck
                    (
                      # The skipped tests all fail in the sandbox because in the nushell test playground,
                      # the tmp $HOME is not set, so nu falls back to looking up the passwd dir of the build
                      # user (/var/empty). The assertions however do respect the set $HOME.
                      set -x
                      HOME=$(mktemp -d) cargo test -j $NIX_BUILD_CORES --offline -- \
                        --test-threads=$NIX_BUILD_CORES \
                        --skip=repl::test_config_path::test_default_config_path \
                        --skip=repl::test_config_path::test_xdg_config_bad \
                        --skip=repl::test_config_path::test_xdg_config_empty
                    )
                    runHook postCheck
                  '';

                  passthru = {
                    shellPath = "/bin/nu";
                    tests.version = testers.testVersion {
                      package = nushell;
                    };
                    updateScript = nix-update-script {};
                  };

                  meta = with lib; {
                    description = "Modern shell written in Rust";
                    homepage = "https://www.nushell.sh/";
                    license = licenses.mit;
                    maintainers = with maintainers; [
                      Br1ght0ne
                      johntitor
                      joaquintrinanes
                    ];
                    mainProgram = "nu";
                  };
                };
              };
            };
            "nu-engine" = {};
            "nu-parser" = {};
            "nu-system" = {};
            "nu-cmd-base" = {};
            "nu-cmd-extra" = {};
            "nu-cmd-lang" = {};
            "nu-cmd-plugin" = {};
            "nu-command" = {};
            "nu-color-config" = {};
            "nu-explore" = {};
            "nu-json" = {};
            "nu-lsp" = {};
            "nu-pretty-hex" = {};
            "nu-protocol" = {};
            "nu-derive-value" = {};
            "nu-plugin" = {};
            "nu-plugin-core" = {};
            "nu-plugin-engine" = {};
            "nu-plugin-protocol" = {};
            "nu-plugin-test-support" = {};
            "nu_plugin_inc" = {};
            "nu_plugin_gstat" = {};
            "nu_plugin_example" = {};
            "nu_plugin_query" = {};
            "nu_plugin_custom_values" = {};
            "nu_plugin_formats" = {};
            "nu_plugin_polars" = {};
            "nu_plugin_stress_internals" = {};
            "nu-std" = {};
            "nu-table" = {};
            "nu-term-grid" = {};
            "nu-test-support" = {};
            "nu-utils" = {};
            "nuon" = {};
          };
        };

        devShells.default = crateOutputs.devShell;
        packages = {
          default = crateOutputs.packages.release;
          nushell = config.packages.default;
        };
        apps = {
          nu.program = config.packages.nushell;
        };
      };
    })
    // {
      plugins = inputs.plugins;
      scripts = inputs.scripts;
    };
}
