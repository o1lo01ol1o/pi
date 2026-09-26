const { createHash } = require("node:crypto");
const { readFileSync, readdirSync, writeFileSync } = require("node:fs");
const { basename, join } = require("node:path");

const dataDir = process.argv[2];
if (!dataDir) {
  throw new Error("model data directory argument is required");
}

const modelDataSource = readFileSync("packages/ai/scripts/model-data.ts", "utf8");
const schemaVersionMatch = modelDataSource.match(/MODEL_DATA_SCHEMA_VERSION\s*=\s*(\d+)/);
if (!schemaVersionMatch) {
  throw new Error("could not read MODEL_DATA_SCHEMA_VERSION from packages/ai/scripts/model-data.ts");
}
const schemaVersion = Number(schemaVersionMatch[1]);

const hash = (value) => createHash("sha256").update(value).digest("hex");
const sortRecord = (record) =>
  Object.fromEntries(Object.entries(record).sort(([left], [right]) => (left < right ? -1 : left > right ? 1 : 0)));

const manifestPath = join(dataDir, ".manifest.json");
const previousManifest = JSON.parse(readFileSync(manifestPath, "utf8"));
const files = {};
const structure = {};

for (const filename of readdirSync(dataDir).filter((entry) => entry.endsWith(".json") && entry !== ".manifest.json").sort()) {
  const path = join(dataDir, filename);
  const groups = JSON.parse(readFileSync(path, "utf8"));
  const normalizedGroups = {};
  const models = {};

  for (const [api, apiModels] of Object.entries(groups)) {
    const normalizedModels = {};
    for (const model of Object.values(apiModels)) {
      const type = model.type ?? "chat";
      const modelKey = `${type}:${model.id}`;
      if (models[modelKey]) {
        throw new Error(`${basename(filename, ".json")}/${modelKey} appears in more than one API group`);
      }
      normalizedModels[modelKey] = model.type === type ? model : { ...model, type };
      models[modelKey] = api;
    }
    normalizedGroups[api] = normalizedModels;
  }

  const content = JSON.stringify(normalizedGroups);
  writeFileSync(path, content);
  files[filename] = hash(content);
  structure[basename(filename, ".json")] = sortRecord(models);
}

const normalizedStructure = sortRecord(
  Object.fromEntries(Object.entries(structure).map(([providerId, models]) => [providerId, sortRecord(models)])),
);
const manifest = {
  schemaVersion,
  generatedAt: previousManifest.generatedAt,
  structureHash: hash(JSON.stringify(normalizedStructure)),
  files: sortRecord(files),
};
writeFileSync(manifestPath, JSON.stringify(manifest));
