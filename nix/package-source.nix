{ lib, srcRoot }:

let
  fromRoot = path: srcRoot + path;
  includeOptional = [
    "/packages/client"
    "/packages/protocol"
    "/packages/server"
    "/packages/telemetry"
  ];
in
lib.fileset.toSource {
  root = srcRoot;
  fileset = lib.fileset.unions (
    [
      (fromRoot "/.npmrc")
      (fromRoot "/package-lock.json")
      (fromRoot "/package.json")
      (fromRoot "/packages/agent")
      (fromRoot "/packages/ai")
      (fromRoot "/packages/chord")
      (fromRoot "/packages/coding-agent")
      (fromRoot "/packages/tui")
      (fromRoot "/scripts/build-coding-agent-bundle.mjs")
      (fromRoot "/tsconfig.base.json")
    ]
    ++ (map lib.fileset.maybeMissing (map fromRoot includeOptional))
  );
}
