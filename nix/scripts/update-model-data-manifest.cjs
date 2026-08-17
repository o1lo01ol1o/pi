const { createHash } = require("node:crypto");
const { readFileSync, readdirSync, writeFileSync } = require("node:fs");
const { basename, join } = require("node:path");

const dataDir = process.argv[2];
if (!dataDir) {
  throw new Error("model data directory argument is required");
}

const hash = (value) => createHash("sha256").update(value).digest("hex");
const sortRecord = (record) =>
  Object.fromEntries(Object.entries(record).sort(([left], [right]) => (left < right ? -1 : left > right ? 1 : 0)));

const manifestPath = join(dataDir, ".manifest.json");
const previousManifest = JSON.parse(readFileSync(manifestPath, "utf8"));
const files = {};
const structure = {};

for (const filename of readdirSync(dataDir).filter((entry) => entry.endsWith(".json") && entry !== ".manifest.json").sort()) {
  const content = readFileSync(join(dataDir, filename), "utf8");
  files[filename] = hash(content);

  const providerId = basename(filename, ".json");
  const groups = JSON.parse(content);
  const models = {};
  for (const api of Object.keys(groups).sort()) {
    for (const modelId of Object.keys(groups[api]).sort()) {
      if (models[modelId]) {
        throw new Error(`${providerId}/${modelId} appears in more than one API group`);
      }
      models[modelId] = api;
    }
  }
  structure[providerId] = sortRecord(models);
}

const normalizedStructure = sortRecord(
  Object.fromEntries(Object.entries(structure).map(([providerId, models]) => [providerId, sortRecord(models)])),
);
const manifest = {
  schemaVersion: 3,
  generatedAt: previousManifest.generatedAt,
  structureHash: hash(JSON.stringify(normalizedStructure)),
  files: sortRecord(files),
};
writeFileSync(manifestPath, JSON.stringify(manifest));
