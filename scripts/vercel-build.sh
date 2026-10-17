#!/usr/bin/env bash
set -euo pipefail

REPO="Broosskyy/Test-Game-Factory."
ASSET_NAME="test-game-factory-web.zip"
EXPECTED_SHA="${VERCEL_GIT_COMMIT_SHA:-}"
BRANCH="${VERCEL_GIT_COMMIT_REF:-main}"

if [ -z "$EXPECTED_SHA" ]; then
  echo "VERCEL_GIT_COMMIT_SHA is not set."
  exit 1
fi

if [ "$BRANCH" = "main" ]; then
  TAG="web-live"
else
  TAG="web-preview-${EXPECTED_SHA}"
fi

API_URL="https://api.github.com/repos/${REPO}/releases/tags/${TAG}"

echo "Waiting for Godot Web bundle for branch $BRANCH, commit $EXPECTED_SHA, tag $TAG"

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
