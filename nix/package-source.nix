{ lib, srcRoot }:

let
  fromRoot = path: srcRoot + path;
in
lib.fileset.toSource {
  root = srcRoot;
  fileset = lib.fileset.unions (map fromRoot [
    "/.npmrc"
    "/package-lock.json"
    "/package.json"
    "/packages/agent"
    "/packages/ai"
    "/packages/client"
    "/packages/coding-agent"
    "/packages/protocol"
    "/packages/telemetry"
    "/packages/tui"
    "/tsconfig.base.json"
  ]);
}
