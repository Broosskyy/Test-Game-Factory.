#!/usr/bin/env bash
set -euo pipefail

SOURCE_REPO="Broosskyy/Realm-Alliance"
SOURCE_SHA="d7c385f8e75020742558fb4307f3cf712f7f1bdb"
SOURCE_ROOT="https://raw.githubusercontent.com/${SOURCE_REPO}/${SOURCE_SHA}/public/assets/production"
DEST_ROOT="assets/realm_alliance/production"

files=(
  "worlds/wolkgarten/castle-island.png"
  "worlds/wolkgarten/floating-islands.png"
  "worlds/wolkgarten/ruin-island.png"
  "worlds/wolkgarten/ruins-strip.png"
  "worlds/wolkgarten/arena-platform.png"
  "worlds/wolkgarten/foliage-rocks.png"

  "hero/realmwaechter/idle.png"
  "hero/realmwaechter/attack.png"
  "hero/realmwaechter/skill.png"
  "hero/realmwaechter/hit.png"
  "hero/realmwaechter/victory.png"
  "hero/realmwaechter/defeated.png"

  "monsters/cloud-golem/idle.png"
  "monsters/cloud-golem/attack.png"
  "monsters/cloud-golem/hit.png"
  "monsters/cloud-golem/defeated.png"

  "monsters/crystal-wolf/idle.png"
  "monsters/crystal-wolf/attack.png"
  "monsters/crystal-wolf/hit.png"
  "monsters/crystal-wolf/defeated.png"

  "weapons/realmblade/blade-basic.png"
  "weapons/realmblade/vfx-basic.png"
)

echo "Syncing pinned REALM ALLIANCE production assets from ${SOURCE_SHA}..."

for relative in "${files[@]}"; do
  target="${DEST_ROOT}/${relative}"
  mkdir -p "$(dirname "$target")"

  if [ -s "$target" ]; then
    echo "exists  $relative"
    continue
  fi

  echo "fetch   $relative"
  curl -fL --retry 4 --retry-delay 2     "${SOURCE_ROOT}/${relative}"     -o "$target"

  test -s "$target"
done

cat > "${DEST_ROOT}/SOURCE.txt" <<EOF
REALM ALLIANCE V2 production asset source
repo=${SOURCE_REPO}
commit=${SOURCE_SHA}
branch_reference=feature/combat-master-convergence-01
EOF

echo "REALM ALLIANCE asset sync complete."
