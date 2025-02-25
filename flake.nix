# Experimental flake interface to Nixpkgs.
# See https://github.com/NixOS/rfcs/pull/49 for details.
{
  description = "A collection of packages for the Nix package manager";

  outputs = { self }:
    let
      jobs = import ./pkgs/top-level/release.nix {
        nixpkgs = self;
      };

      lib = import ./lib;

      systems = lib.systems.supported.hydra;

      forAllSystems = f: lib.genAttrs systems (system: f system);

    in
    {
      lib = lib.extend (final: prev: {

        nixos = import ./nixos/lib { lib = final; };

        nixosSystem = { modules, ... } @ args:
          import ./nixos/lib/eval-config.nix (args // {
            modules =
              let
                moduleDeclarationFile =
                  let
                    # Even though `modules` is a mandatory argument for `nixosSystem`, it doesn't
                    # mean that the evaluator always keeps track of its position. If there
                    # are too many levels of indirection, the position gets lost at some point.
                    intermediatePos = builtins.unsafeGetAttrPos "modules" args;
                  in
                    if intermediatePos == null then null else intermediatePos.file;

                # Add the invoking file as error message location for modules
                # that don't have their own locations; presumably inline modules.
                addModuleDeclarationFile =
                  m: if moduleDeclarationFile == null then m else {
                    _file = moduleDeclarationFile;
                    imports = [ m ];
                  };

              in
              map addModuleDeclarationFile modules ++ [
                {
                  system.nixos.versionSuffix =
                    ".${final.substring 0 8 (self.lastModifiedDate or self.lastModified or "19700101")}.${self.shortRev or "dirty"}";
                  system.nixos.revision = final.mkIf (self ? rev) self.rev;

                  # NOTE: This assumes that `nixpkgs.config` is _not_ used when
                  #       nixpkgs.pkgs is set OR _module.args.pkgs is set.
                  nixpkgs.config.path = self.outPath;
                }
              ];
          });
      });

      checks.x86_64-linux.tarball = jobs.tarball;

      htmlDocs = {
        nixpkgsManual = jobs.manual;
        nixosManual = (import ./nixos/release-small.nix {
          nixpkgs = self;
        }).nixos.manual.x86_64-linux;
      };

      legacyPackages = forAllSystems (system: import ./. { inherit system; config.path = self.outPath; });

      nixosModules = {
        notDetected = import ./nixos/modules/installer/scan/not-detected.nix;
      };
    };
}
