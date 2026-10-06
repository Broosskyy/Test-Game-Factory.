#!/usr/bin/env bash
set -euo pipefail

REPO="Broosskyy/Test-Game-Factory."
TAG="web-live"
ASSET_NAME="test-game-factory-web.zip"
API_URL="https://api.github.com/repos/${REPO}/releases/tags/${TAG}"
EXPECTED_SHA="${VERCEL_GIT_COMMIT_SHA:-}"

if [ -z "$EXPECTED_SHA" ]; then
  echo "VERCEL_GIT_COMMIT_SHA is not set."
  exit 1
fi

if [ "${VERCEL_GIT_COMMIT_REF:-main}" != "main" ]; then
  echo "Preview branch detected: ${VERCEL_GIT_COMMIT_REF:-unknown}"
  echo "Godot gameplay previews are published from validated main builds."
  mkdir -p build/web
  cat > build/web/index.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Game Factory Preview</title>
  <style>
    html,body{height:100%;margin:0;background:#07090d;color:#eef0f4;font-family:system-ui,sans-serif}
    body{display:grid;place-items:center}
    main{text-align:center;padding:32px}
    p{color:#959ba6}
  </style>
</head>
<body><main><h1>GAME FACTORY</h1><p>Branch validated via GitHub CI.<br>Playable Web builds publish from main.</p></main></body>
</html>
HTML
  exit 0
fi

echo "Waiting for Godot Web bundle for commit $EXPECTED_SHA"

release_json=""
for attempt in $(seq 1 120); do
  release_json="$(curl -fsSL -H "Accept: application/vnd.github+json" "$API_URL" 2>/dev/null || true)"

  if [ -n "$release_json" ]; then
    release_sha="$(printf '%s' "$release_json" | node -e '
      let data="";
      process.stdin.on("data", c => data += c);
      process.stdin.on("end", () => {
        try {
          const json = JSON.parse(data);
          const body = String(json.body || "");
          const match = body.match(/^commit=([0-9a-f]{40})$/m);
          process.stdout.write(match ? match[1] : "");
        } catch {
          process.stdout.write("");
        }
      });
    ')"

    if [ "$release_sha" = "$EXPECTED_SHA" ]; then
      asset_url="$(printf '%s' "$release_json" | node -e '
        let data="";
        process.stdin.on("data", c => data += c);
        process.stdin.on("end", () => {
          try {
            const json = JSON.parse(data);
            const asset = (json.assets || []).find(a => a.name === "test-game-factory-web.zip");
            process.stdout.write(asset ? String(asset.browser_download_url || "") : "");
          } catch {
            process.stdout.write("");
          }
        });
      ')"

      if [ -n "$asset_url" ]; then
        echo "Found matching Web bundle."
        rm -rf build/web
        mkdir -p build/web
        curl -fL --retry 3 --retry-delay 2 "$asset_url" -o /tmp/test-game-factory-web.zip
        unzip -q /tmp/test-game-factory-web.zip -d build/web
        test -f build/web/index.html
        test -f build/web/index.wasm
        test -f build/web/index.pck
        echo "Web bundle ready for Vercel."
        exit 0
      fi
    fi
  fi

  echo "Bundle not ready yet (attempt $attempt/120)."
  sleep 5
done

echo "Timed out waiting for Web bundle for $EXPECTED_SHA."
exit 1
