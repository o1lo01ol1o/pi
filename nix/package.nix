{ pkgs, srcRoot }:

let
  lib = pkgs.lib;
  nodejs = import ./nodejs.nix { inherit pkgs; };
  npmPackage =
    if builtins.elem "npm" (nodejs.outputs or [ ]) then
      lib.getOutput "npm" nodejs
    else
      nodejs;
  codingAgentPackage = builtins.fromJSON (builtins.readFile (srcRoot + "/packages/coding-agent/package.json"));
  releaseSourceSpecs = {
    "0.79.6" = {
      url = "https://github.com/earendil-works/pi/archive/refs/tags/v0.79.6.tar.gz";
      hash = "sha256-ZJv4YCqt10DnuS3oCwwJ9Byix0u4CDFuiVaQd01Ryhs=";
    };
    "0.82.1" = {
      url = "https://github.com/earendil-works/pi/releases/download/v0.82.1/pi-0.82.1-source.tar.gz";
      hash = "sha256-h7DgnSj10WTS2TAM2hkNNC8dY6oqmnSeCg7+4wVbzzg=";
    };
    "0.84.2" = {
      url = "https://github.com/earendil-works/pi/releases/download/v0.84.2/pi-0.84.2-source.tar.gz";
      hash = "sha256-UJr6NAfjKM/xldjmyx4W28K9I8jJz/dh3vz6eLi1I40=";
    };
  };
  releaseSource =
    if builtins.hasAttr codingAgentPackage.version releaseSourceSpecs then
      let
        source = releaseSourceSpecs.${codingAgentPackage.version};
      in
        pkgs.fetchzip {
          url = source.url;
          hash = source.hash;
          stripRoot = true;
        }
    else
      pkgs.lib.warn "Missing release-source metadata for pi ${codingAgentPackage.version}; using local source data." srcRoot;
  packageSource = import ./package-source.nix { inherit lib srcRoot; };
  runtimePackages = [
    pkgs.fd
    pkgs.git
    pkgs.gnutar
    nodejs
    npmPackage
    pkgs.ripgrep
    pkgs.unzip
  ];
in
pkgs.buildNpmPackage {
  pname = "pi";
  version = codingAgentPackage.version;
  src = packageSource;

  npmDeps = pkgs.importNpmLock { npmRoot = packageSource; };
  npmConfigHook = pkgs.importNpmLock.npmConfigHook;
  npmFlags = [ "--ignore-scripts" ];
  npmRebuildFlags = [ "--ignore-scripts" ];

  nativeBuildInputs = [ pkgs.makeBinaryWrapper ];

  PI_NIX_ASSERT_RUNTIME_PATH = ./scripts/assert-runtime-path.cjs;
  PI_NIX_MODEL_DATA = "${releaseSource}/packages/ai/src/providers/data";
  PI_NIX_MODEL_DATA_OVERRIDES = ./model-data-overrides;
  PI_NIX_NODE = "${nodejs}/bin/node";
  PI_NIX_RUNTIME_PATH = lib.makeBinPath runtimePackages;
  PI_NIX_UPDATE_MODEL_DATA_MANIFEST = ./scripts/update-model-data-manifest.cjs;

  buildPhase = "source ${./scripts/build-phase.sh}";
  installPhase = "source ${./scripts/install-phase.sh}";

  doInstallCheck = true;
  installCheckPhase = "source ${./scripts/install-check-phase.sh}";

  passthru = {
    inherit nodejs runtimePackages;
  };

  meta = {
    description = "Minimal terminal coding harness";
    homepage = "https://github.com/earendil-works/pi";
    license = lib.licenses.mit;
    mainProgram = "pi";
  };
}
