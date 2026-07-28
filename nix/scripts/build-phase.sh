set -eo pipefail

runHook preBuild

mkdir -p packages/ai/src/providers
cp -R "$PI_NIX_MODEL_DATA" packages/ai/src/providers/data

npm run --workspace @earendil-works/pi-tui build
npm run --workspace @earendil-works/pi-ai build:offline
npm run --workspace @earendil-works/pi-agent-core build
npm run --workspace @earendil-works/pi-coding-agent build

runHook postBuild
