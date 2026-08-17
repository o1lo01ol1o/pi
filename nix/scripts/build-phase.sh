set -eo pipefail

runHook preBuild

mkdir -p packages/ai/src/providers/data
cp -R "$PI_NIX_MODEL_DATA"/. packages/ai/src/providers/data/
chmod -R u+w packages/ai/src/providers/data
cp -R "$PI_NIX_MODEL_DATA_OVERRIDES"/. packages/ai/src/providers/data/
"$PI_NIX_NODE" "$PI_NIX_UPDATE_MODEL_DATA_MANIFEST" packages/ai/src/providers/data

npm run --workspace @earendil-works/pi-telemetry build
npm run --workspace @earendil-works/pi-protocol build
npm run --workspace @earendil-works/pi-client build
npm run --workspace @earendil-works/pi-tui build
npm run --workspace @earendil-works/pi-ai build:offline
npm run --workspace @earendil-works/pi-agent-core build
npm run --workspace @earendil-works/pi-coding-agent build

runHook postBuild
