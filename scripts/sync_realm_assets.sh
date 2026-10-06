#!/usr/bin/env bash
set -euo pipefail

SOURCE_REPO="Broosskyy/Realm-Alliance"

COMBAT_SHA="d7c385f8e75020742558fb4307f3cf712f7f1bdb"
COMBAT_ROOT="https://raw.githubusercontent.com/${SOURCE_REPO}/${COMBAT_SHA}/public/assets/production"
COMBAT_DEST="assets/realm_alliance/production"

V2_SHA="61b4aa9b2dff1337e0a64615f8f98c4791e1af4e"
V2_ROOT="https://raw.githubusercontent.com/${SOURCE_REPO}/${V2_SHA}/assets/production"
V2_DEST="assets/realm_alliance/v2"

sync_file() {
  local root="$1"
  local dest_root="$2"
  local relative="$3"
  local target="${dest_root}/${relative}"

  mkdir -p "$(dirname "$target")"

  if [ -s "$target" ]; then
    echo "exists  $relative"
    return
  fi

  echo "fetch   $relative"
  curl -fL --retry 4 --retry-delay 2 "${root}/${relative}" -o "$target"
  test -s "$target"
}

combat_files=(
  "worlds/wolkgarten/castle-island.png"
  "worlds/wolkgarten/floating-islands.png"
  "worlds/wolkgarten/ruin-island.png"
  "worlds/wolkgarten/ruins-strip.png"
  "worlds/wolkgarten/arena-platform.png"
  "worlds/wolkgarten/foliage-rocks.png"
  "worlds/wolkgarten/portal-island.png"

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
  "monsters/cloud-golem/vfx_crystal_burst.png"
  "monsters/cloud-golem/vfx_crystal_spike.png"
  "monsters/cloud-golem/vfx_ground_impact.png"
  "monsters/cloud-golem/vfx_slash.png"

  "monsters/crystal-wolf/idle.png"
  "monsters/crystal-wolf/attack.png"
  "monsters/crystal-wolf/hit.png"
  "monsters/crystal-wolf/defeated.png"

  "weapons/realmblade/blade-basic.png"
  "weapons/realmblade/blade-crystal.png"
  "weapons/realmblade/blade-fire.png"
  "weapons/realmblade/blade-gold.png"
  "weapons/realmblade/vfx-basic.png"
  "weapons/realmblade/vfx-crystal.png"
  "weapons/realmblade/vfx-fire.png"
  "weapons/realmblade/vfx-gold.png"
)

v2_files=(
  "ui_v4/combat_core/attack.png"
  "ui_v4/combat_core/auto.png"
  "ui_v4/combat_core/heavy_attack.png"
  "ui_v4/combat_core/target.png"

  "ui_v4/combat_status/burn.png"
  "ui_v4/combat_status/defense_up.png"
  "ui_v4/combat_status/attack_up.png"

  "ui_v4/navigation/combat.png"
  "ui_v4/navigation/currency.png"
  "ui_v4/navigation/home.png"
  "ui_v4/navigation/inventory.png"
  "ui_v4/navigation/menu.png"
  "ui_v4/navigation/monster.png"
  "ui_v4/navigation/quest.png"
  "ui_v4/navigation/settings.png"

  "ui_v4/inventory_consumables/blue_crystal.png"
  "ui_v4/inventory_consumables/purple_orb.png"

  "ui_v4/monster_boss_hud/elite_frame.png"
  "ui_v4/monster_boss_hud/hp_bar.png"
  "ui_v4/monster_boss_hud/target_frame.png"

  "ui_v4/quest_states/streak.png"

  "v190/vfx/combat_impacts/ice_impact.png"
  "v190/vfx/combat_impacts/ice_impact_strong.png"
  "v190/vfx/combat_impacts/gold_impact.png"
  "v190/vfx/combat_impacts/fire_impact.png"
  "v190/vfx/combat_impacts/nature_impact.png"

  "v190/vfx/progression_a/blue_level_beam.png"
  "v190/vfx/progression_a/gold_level_beam.png"
  "v190/vfx/progression_a/purple_unlock_vortex.png"

  "v190/vfx/rewards/blue_burst.png"
  "v190/vfx/rewards/gold_burst.png"
  "v190/vfx/rewards/purple_vortex.png"
)

echo "Syncing REALM ALLIANCE combat-master assets from ${COMBAT_SHA}..."
for relative in "${combat_files[@]}"; do
  sync_file "$COMBAT_ROOT" "$COMBAT_DEST" "$relative"
done

echo "Syncing REALM ALLIANCE V2 UI/VFX assets from ${V2_SHA}..."
for relative in "${v2_files[@]}"; do
  sync_file "$V2_ROOT" "$V2_DEST" "$relative"
done

cat > "${COMBAT_DEST}/SOURCE.txt" <<EOF
REALM ALLIANCE combat production source
repo=${SOURCE_REPO}
commit=${COMBAT_SHA}
branch_reference=feature/combat-master-convergence-01
EOF

cat > "${V2_DEST}/SOURCE.txt" <<EOF
REALM ALLIANCE V2 UI/VFX source
repo=${SOURCE_REPO}
commit=${V2_SHA}
branch_reference=realm-v2-web-first
EOF

echo "REALM ALLIANCE dual-source asset sync complete."
