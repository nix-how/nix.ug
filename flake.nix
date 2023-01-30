{
  description = "A Flake for the nix.ug website";
  nixConfig = {
    extra-substituters = [ "https://matthewcroughan.cachix.org" ];
    extra-trusted-public-keys = [ "matthewcroughan.cachix.org-1:fON2C9BdzJlp1qPan4t5AF0xlnx8sB0ghZf8VDo7+e8=" ];
  };
  inputs = {
    homer-src = {
      url = "github:bastienwirtz/homer/v22.11.1";
      flake = false;
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    dream2nix.url = "github:nix-community/dream2nix";
    flake-parts.url = "github:hercules-ci/flake-parts";
    hercules-ci-effects.url = "github:hercules-ci/hercules-ci-effects";
  };
  outputs = { self, nixpkgs, flake-parts, dream2nix, homer-src, hercules-ci-effects }:
  flake-parts.lib.mkFlake { inherit self; } {
      imports = [
        dream2nix.flakeModuleBeta
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      flake = {
        herculesCI.ciSystems = [ "x86_64-linux" ];
        effects = let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          hci-effects = hercules-ci-effects.lib.withPkgs pkgs;
        in { branch, ... }: {
          gh-pages = hci-effects.runIf (branch == "master") (
            hci-effects.mkEffect {
              src = self;
              buildInputs = with nixpkgs.legacyPackages.x86_64-linux; [ openssh git ];
              secretsMap.token = { type = "GitToken"; };
              EMAIL = "hercules-ci[bot]@users.noreply.github.com";
              GIT_AUTHOR_NAME = "Hercules CI Effects";
              GIT_COMMITTER_NAME = "Hercules CI Effects";
              PAGER = "cat";
              userSetupScript = ''
                set -x
                echo "https://git:$(readSecretString token .token)@github.com/nix-how/nix.ug" >~/.git-credentials
                git config --global credential.helper store
              '';
              effectScript =
              ''
                cp -r --no-preserve=mode ${self.packages.x86_64-linux.default} ./gh-pages && cd gh-pages
                echo "nix.ug" > CNAME
                git init -b gh-pages
                git remote add origin https://github.com/nix-how/nix.ug
                git add .
                git commit -m "Deploy to gh-pages"
                git push -vvvvvv -f origin gh-pages:gh-pages
              '';
            }
          );
        };
      };
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        apps = {
          serve = {
            type = "app";
            program = pkgs.writeShellApplication
              {
                name = "serve";
                runtimeInputs = with pkgs; [
                  entr
                  simple-http-server
                  nixVersions.unstable
                ];
                text =
                  let
                    script = pkgs.writeShellScript "serve.sh" ''
                      simple-http-server --index --nocache \
                        $(nix build --print-out-paths --no-link)
                    '';
                  in
                  ''
                    find . -name "*" | entr -r ${script}
                  '';
              } + "/bin/serve";
          };
        };
        packages = {
          default =
            let
              distPath = self'.packages.homer + "/lib/node_modules/homer/dist";
              config = ./config.yml;
              services = (pkgs.formats.yaml {}).generate "" (import ./lists { inherit (pkgs) lib; });
            in
            pkgs.runCommand "nix.ug-dist" {} ''
              cp -r --no-preserve=mode ${distPath} $out
              cp --no-preserve=mode ${config} $out/assets/config.yml
              cp ${./assets/logo.svg} $out/logo.svg
              cp ${./assets/icons}/* $out/assets/icons
              for i in $(find "${self}/lists" -name "logo.*")
              do
                mkdir $out/assets/$(basename $(dirname $i))
                cp $i $out/assets/$(basename $(dirname $i))
              done
              cat ${services} >> $out/assets/config.yml
            '';
        };
        # define an input for dream2nix to generate outputs for
        dream2nix.inputs."homer" = {
          source = homer-src;
        };
      };
    };
}

