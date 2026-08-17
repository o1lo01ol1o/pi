set -eo pipefail

runHook preBuild

mkdir -p packages/ai/src/providers/data
if [ -d "$PI_NIX_MODEL_DATA" ]; then
  cp -R "$PI_NIX_MODEL_DATA"/. packages/ai/src/providers/data/
fi
chmod -R u+w packages/ai/src/providers/data
if [ -d "$PI_NIX_MODEL_DATA_OVERRIDES" ]; then
  cp -R "$PI_NIX_MODEL_DATA_OVERRIDES"/. packages/ai/src/providers/data/
fi
if [ -f "packages/ai/src/providers/data/.manifest.json" ]; then
  "$PI_NIX_NODE" "$PI_NIX_UPDATE_MODEL_DATA_MANIFEST" packages/ai/src/providers/data
fi

run_workspace() {
  local package_dir="${1}"
  local workspace="${2}"
  local script="${3}"
  if [ -d "${package_dir}" ]; then
    npm run --workspace "${workspace}" "${script}"
  fi
}

run_workspace packages/telemetry "@earendil-works/pi-telemetry" build
run_workspace packages/protocol "@earendil-works/pi-protocol" build
run_workspace packages/client "@earendil-works/pi-client" build
npm run --workspace @earendil-works/pi-tui build
if [ "$("$PI_NIX_NODE" -e 'const p=require("./packages/ai/package.json");process.stdout.write(p.scripts && p.scripts["build:offline"] ? "yes" : "no")')" = "yes" ]; then
  npm run --workspace @earendil-works/pi-ai build:offline
else
  # Older sources (<=0.82.x) have no build:offline and their build script
  # regenerates model data from the network. The hydrated data above and the
  # committed generated files are already current, so only compile.
  node_modules/.bin/tsgo -p packages/ai/tsconfig.build.json
fi
run_workspace packages/agent "@earendil-works/pi-agent-core" build
npm run --workspace @earendil-works/pi-coding-agent build

runHook postBuild
