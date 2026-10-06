extends Control

const PORTRAIT_REFERENCE := Vector2i(720, 1280)
const LANDSCAPE_REFERENCE := Vector2i(960, 540)
const ASSET_ROOT := "res://assets/realm_alliance/production/"
const V2_ASSET_ROOT := "res://assets/realm_alliance/v2/"

const HERO_FILES := {
	"idle": "hero/realmwaechter/idle.png",
	"attack": "hero/realmwaechter/attack.png",
	"skill": "hero/realmwaechter/skill.png",
	"hit": "hero/realmwaechter/hit.png",
	"victory": "hero/realmwaechter/victory.png",
	"defeat": "hero/realmwaechter/defeated.png",
}

const ENEMY_FILES := {
	"idle": "monsters/cloud-golem/idle.png",
	"attack": "monsters/cloud-golem/attack.png",
	"hit": "monsters/cloud-golem/hit.png",
	"defeated": "monsters/cloud-golem/defeated.png",
}

const WORLD_FILES := {
	"castle": "worlds/wolkgarten/castle-island.png",
	"float": "worlds/wolkgarten/floating-islands.png",
	"ruin": "worlds/wolkgarten/ruin-island.png",
	"ruins": "worlds/wolkgarten/ruins-strip.png",
	"platform": "worlds/wolkgarten/arena-platform.png",
	"foreground": "worlds/wolkgarten/foliage-rocks.png",
}

var player_hp := 100
var enemy_hp := 100
var enemy_hp_max := 100
var busy := false
var damage_index := 0
var auto_enabled := false
const DISPLAY_DAMAGE := [5274, 2931, 8416, 2605]
var _last_landscape := false
var _profile_initialized := false
var _applying_profile := false

var stage: Control
var hero_holder: Control
var enemy_holder: Control
var hero_art: TextureRect
var enemy_art: TextureRect
var enemy_hp_bar: ProgressBar
var enemy_hp_text: Label
var player_hp_bar: ProgressBar
var player_hp_text: Label
var damage_label: Label
var result_overlay: ColorRect
var result_title: Label
var attack_hint: Label
var fullscreen_button: Button
var slash_fx: TextureRect
var impact_fx: TextureRect
var momentum_bar: ProgressBar
var fury_bar: ProgressBar
var auto_button: Button


func _ready() -> void:
	_apply_orientation_profile()
	if not get_window().size_changed.is_connected(_on_window_size_changed):
		get_window().size_changed.connect(_on_window_size_changed)

	_build_interface()
	_load_production_assets()
	_refresh_hud()


func _on_window_size_changed() -> void:
	if _applying_profile:
		return
	_apply_orientation_profile()


func _apply_orientation_profile() -> void:
	var physical_size := get_window().size
	if physical_size.x <= 0 or physical_size.y <= 0:
		return

	var is_landscape := physical_size.x > physical_size.y
	if _profile_initialized and is_landscape == _last_landscape:
		return

	_applying_profile = true
	_last_landscape = is_landscape
	_profile_initialized = true

	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	get_window().content_scale_size = LANDSCAPE_REFERENCE if is_landscape else PORTRAIT_REFERENCE

	_applying_profile = false


func _build_interface() -> void:
	var app_bg := ColorRect.new()
	_anchor(app_bg, 0.0, 0.0, 1.0, 1.0)
	app_bg.color = Color("#06101a")
	app_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(app_bg)

	_build_topbar()
	_build_stage()
	_build_bottom_nav()


func _build_topbar() -> void:
	var topbar := Control.new()
	_anchor(topbar, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 78.0)
	topbar.z_index = 120
	add_child(topbar)

	var topbar_bg := Panel.new()
	_anchor(topbar_bg, 0.0, 0.0, 1.0, 1.0)
	topbar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	topbar_bg.add_theme_stylebox_override("panel", _panel_style(Color("#071522"), Color("#244e6b"), 0))
	topbar.add_child(topbar_bg)

	var player_chip := Control.new()
	_anchor(player_chip, 0.012, 0.10, 0.305, 0.90)
	topbar.add_child(player_chip)

	var chip_bg := Panel.new()
	_anchor(chip_bg, 0.0, 0.0, 1.0, 1.0)
	chip_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip_bg.add_theme_stylebox_override("panel", _panel_style(Color("#0b1b2c"), Color("#315f83"), 16))
	player_chip.add_child(chip_bg)

	var avatar := TextureRect.new()
	avatar.name = "TopHeroPortrait"
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_anchor(avatar, 0.018, 0.08, 0.26, 0.92)
	player_chip.add_child(avatar)

	var level := Label.new()
	level.text = "LV. 42"
	level.add_theme_color_override("font_color", Color.WHITE)
	level.add_theme_font_size_override("font_size", 21)
	_anchor(level, 0.29, 0.08, 0.94, 0.48)
	player_chip.add_child(level)

	var xp := ProgressBar.new()
	xp.min_value = 0
	xp.max_value = 100
	xp.value = 72
	xp.show_percentage = false
	xp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	xp.add_theme_stylebox_override("background", _panel_style(Color("#06101a"), Color("#10293c"), 8))
	xp.add_theme_stylebox_override("fill", _panel_style(Color("#2c9cff"), Color("#6dc8ff"), 8))
	_anchor(xp, 0.29, 0.57, 0.80, 0.82)
	player_chip.add_child(xp)

	var xp_text := Label.new()
	xp_text.text = "72%"
	xp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	xp_text.add_theme_color_override("font_color", Color("#dceeff"))
	xp_text.add_theme_font_size_override("font_size", 12)
	_anchor(xp_text, 0.81, 0.52, 0.98, 0.86)
	player_chip.add_child(xp_text)

	var resources := HBoxContainer.new()
	_anchor(resources, 0.315, 0.17, 0.835, 0.84)
	resources.alignment = BoxContainer.ALIGNMENT_CENTER
	resources.add_theme_constant_override("separation", 7)
	topbar.add_child(resources)

	var resource_data := [
		["ui_v4/navigation/currency.png", "128.4K", Color("#f4b62d")],
		["ui_v4/inventory_consumables/purple_orb.png", "2.580", Color("#a341ff")],
		["ui_v4/inventory_consumables/blue_crystal.png", "347", Color("#2bd5ff")]
	]
	for entry in resource_data:
		var resource := PanelContainer.new()
		resource.custom_minimum_size = Vector2(112, 44)
		resource.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		resource.add_theme_stylebox_override("panel", _panel_style(Color("#071624"), Color("#24445f"), 16))

		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 7)
		resource.add_child(row)

		var icon := TextureRect.new()
		icon.texture = _load_v2_texture(entry[0])
		icon.custom_minimum_size = Vector2(26, 26)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)

		var amount := Label.new()
		amount.text = entry[1]
		amount.add_theme_color_override("font_color", Color.WHITE)
		amount.add_theme_font_size_override("font_size", 16)
		row.add_child(amount)

		var plus := Label.new()
		plus.text = "+"
		plus.add_theme_color_override("font_color", Color("#99afd0"))
		plus.add_theme_font_size_override("font_size", 19)
		row.add_child(plus)
		resources.add_child(resource)

	var mail := Button.new()
	mail.text = "MAIL"
	mail.focus_mode = Control.FOCUS_NONE
	mail.add_theme_font_size_override("font_size", 11)
	mail.add_theme_stylebox_override("normal", _panel_style(Color("#0b1a2b"), Color("#31587a"), 12))
	_anchor(mail, 0.847, 0.18, 0.918, 0.82)
	topbar.add_child(mail)

	fullscreen_button = Button.new()
	fullscreen_button.text = "FULL" if OS.get_name() == "Web" else "SET"
	fullscreen_button.focus_mode = Control.FOCUS_NONE
	fullscreen_button.add_theme_font_size_override("font_size", 11)
	fullscreen_button.add_theme_stylebox_override("normal", _panel_style(Color("#0b1a2b"), Color("#31587a"), 12))
	fullscreen_button.add_theme_stylebox_override("pressed", _panel_style(Color("#17344e"), Color("#65b7ed"), 12))
	_anchor(fullscreen_button, 0.925, 0.18, 0.988, 0.82)
	fullscreen_button.pressed.connect(_toggle_fullscreen)
	topbar.add_child(fullscreen_button)

func _build_stage() -> void:
	stage = Control.new()
	_anchor(stage, 0.0, 0.0, 1.0, 1.0, 0.0, 78.0, 0.0, -92.0)
	stage.clip_contents = true
	add_child(stage)

	var sky := ColorRect.new()
	_anchor(sky, 0.0, 0.0, 1.0, 0.74)
	sky.color = Color("#7fc7ec")
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(sky)

	var horizon := ColorRect.new()
	_anchor(horizon, 0.0, 0.50, 1.0, 1.0)
	horizon.color = Color("#a9c9a5")
	horizon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(horizon)

	_add_world_texture("Castle", -0.08, 0.025, 0.55, 0.47, 1)
	_add_world_texture("Float", 0.49, 0.015, 1.15, 0.43, 1)
	_add_world_texture("Ruin", 0.54, 0.17, 1.03, 0.57, 2)
	_add_world_texture("Ruins", -0.01, 0.28, 1.01, 0.69, 2)
	_add_world_texture("Platform", -0.28, 0.44, 1.28, 0.87, 3)
	_add_world_texture("Foreground", -0.10, 0.66, 1.10, 1.06, 7)

	var depth_tint := ColorRect.new()
	_anchor(depth_tint, 0.0, 0.0, 1.0, 1.0)
	depth_tint.color = Color(0.015, 0.055, 0.075, 0.08)
	depth_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	depth_tint.z_index = 5
	stage.add_child(depth_tint)

	# Compact world progression pill from the combat master.
	var world_pill := PanelContainer.new()
	_anchor(world_pill, 0.25, 0.018, 0.75, 0.080)
	world_pill.z_index = 32
	world_pill.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.08, 0.13, 0.94), Color("#35678c"), 24))
	stage.add_child(world_pill)

	var world_row := HBoxContainer.new()
	world_row.alignment = BoxContainer.ALIGNMENT_CENTER
	world_row.add_theme_constant_override("separation", 10)
	world_pill.add_child(world_row)

	var mountain := Label.new()
	mountain.text = "^^"
	mountain.add_theme_color_override("font_color", Color("#d7e9ff"))
	mountain.add_theme_font_size_override("font_size", 18)
	world_row.add_child(mountain)

	var world_name := Label.new()
	world_name.text = "WOLKGARTEN  3-5"
	world_name.add_theme_color_override("font_color", Color.WHITE)
	world_name.add_theme_font_size_override("font_size", 19)
	world_row.add_child(world_name)

	var progress := Label.new()
	progress.text = "●  •  •  •  •  X"
	progress.add_theme_color_override("font_color", Color("#7bbcff"))
	progress.add_theme_font_size_override("font_size", 16)
	world_row.add_child(progress)

	var streak := PanelContainer.new()
	_anchor(streak, 0.018, 0.105, 0.235, 0.178)
	streak.z_index = 31
	streak.add_theme_stylebox_override("panel", _panel_style(Color(0.05, 0.08, 0.10, 0.90), Color("#5d4c2b"), 12))
	stage.add_child(streak)

	var streak_text := Label.new()
	streak_text.text = "12ER SIEGESSERIE\n+24% GOLD  +18% XP"
	streak_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	streak_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	streak_text.add_theme_color_override("font_color", Color("#ffe39d"))
	streak_text.add_theme_font_size_override("font_size", 12)
	streak.add_child(streak_text)

	hero_holder = Control.new()
	hero_holder.name = "HeroHolder"
	_anchor(hero_holder, 0.015, 0.455, 0.35, 0.795)
	hero_holder.z_index = 10
	hero_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(hero_holder)

	hero_art = _make_texture_rect()
	_anchor(hero_art, 0.0, 0.0, 1.0, 1.0)
	hero_holder.add_child(hero_art)

	enemy_holder = Control.new()
	enemy_holder.name = "EnemyHolder"
	_anchor(enemy_holder, 0.43, 0.275, 1.01, 0.805)
	enemy_holder.z_index = 9
	enemy_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(enemy_holder)

	enemy_art = _make_texture_rect()
	_anchor(enemy_art, 0.0, 0.0, 1.0, 1.0)
	enemy_holder.add_child(enemy_art)

	_add_shadow(hero_holder, 0.13, 0.91, 0.90, 0.98)
	_add_shadow(enemy_holder, 0.08, 0.91, 0.92, 0.98)

	slash_fx = _make_texture_rect()
	_anchor(slash_fx, 0.25, 0.44, 0.72, 0.70)
	slash_fx.z_index = 15
	slash_fx.visible = false
	stage.add_child(slash_fx)

	impact_fx = _make_texture_rect()
	_anchor(impact_fx, 0.56, 0.41, 0.96, 0.70)
	impact_fx.z_index = 16
	impact_fx.visible = false
	stage.add_child(impact_fx)

	_build_enemy_hud()
	_build_damage_number()
	_build_combat_bottom_hud()

	var tap_zone := Button.new()
	tap_zone.text = ""
	tap_zone.flat = true
	tap_zone.focus_mode = Control.FOCUS_NONE
	tap_zone.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_anchor(tap_zone, 0.0, 0.11, 1.0, 0.745)
	tap_zone.z_index = 18
	tap_zone.pressed.connect(_attack)
	stage.add_child(tap_zone)

	attack_hint = Label.new()
	attack_hint.text = "TIPPEN ZUM ANGREIFEN"
	attack_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	attack_hint.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0, 0.72))
	attack_hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	attack_hint.add_theme_constant_override("shadow_offset_x", 2)
	attack_hint.add_theme_constant_override("shadow_offset_y", 2)
	attack_hint.add_theme_font_size_override("font_size", 14)
	_anchor(attack_hint, 0.31, 0.69, 0.69, 0.73)
	attack_hint.z_index = 30
	attack_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(attack_hint)

	_build_result_overlay()

func _build_enemy_hud() -> void:
	var hud := PanelContainer.new()
	_anchor(hud, 0.295, 0.095, 0.705, 0.205)
	hud.z_index = 42
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.065, 0.105, 0.96), Color("#4c7694"), 15))
	stage.add_child(hud)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	hud.add_child(box)

	var title := HBoxContainer.new()
	title.alignment = BoxContainer.ALIGNMENT_CENTER
	title.add_theme_constant_override("separation", 8)
	box.add_child(title)

	var rank := Label.new()
	rank.text = "X"
	rank.custom_minimum_size = Vector2(32, 32)
	rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rank.add_theme_color_override("font_color", Color("#ff707d"))
	rank.add_theme_font_size_override("font_size", 20)
	title.add_child(rank)

	var name := Label.new()
	name.text = "STEINGOLEM"
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.add_theme_color_override("font_color", Color.WHITE)
	name.add_theme_font_size_override("font_size", 21)
	title.add_child(name)

	var level := Label.new()
	level.text = "LV. 38"
	level.add_theme_color_override("font_color", Color("#edf4ff"))
	level.add_theme_font_size_override("font_size", 15)
	title.add_child(level)

	var bar_wrap := Control.new()
	bar_wrap.custom_minimum_size = Vector2(0, 24)
	box.add_child(bar_wrap)

	enemy_hp_bar = ProgressBar.new()
	enemy_hp_bar.min_value = 0
	enemy_hp_bar.max_value = enemy_hp_max
	enemy_hp_bar.value = enemy_hp
	enemy_hp_bar.show_percentage = false
	_anchor(enemy_hp_bar, 0.0, 0.08, 1.0, 0.88)
	enemy_hp_bar.add_theme_stylebox_override("background", _panel_style(Color("#02060a"), Color("#18222b"), 9))
	enemy_hp_bar.add_theme_stylebox_override("fill", _panel_style(Color("#ff233e"), Color("#ff6575"), 9))
	bar_wrap.add_child(enemy_hp_bar)

	enemy_hp_text = Label.new()
	enemy_hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_hp_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	enemy_hp_text.add_theme_color_override("font_color", Color.WHITE)
	enemy_hp_text.add_theme_color_override("font_shadow_color", Color.BLACK)
	enemy_hp_text.add_theme_constant_override("shadow_offset_x", 2)
	enemy_hp_text.add_theme_constant_override("shadow_offset_y", 2)
	enemy_hp_text.add_theme_font_size_override("font_size", 13)
	_anchor(enemy_hp_text, 0.0, 0.0, 1.0, 1.0)
	bar_wrap.add_child(enemy_hp_text)

	var status := HBoxContainer.new()
	status.alignment = BoxContainer.ALIGNMENT_CENTER
	status.add_theme_constant_override("separation", 6)
	box.add_child(status)
	var status_icons := [
		["ui_v4/combat_status/burn.png", "#ff772b"],
		["ui_v4/combat_status/defense_up.png", "#53c7ff"],
		["ui_v4/combat_status/attack_up.png", "#bcc5d0"]
	]
	for entry in status_icons:
		var chip := PanelContainer.new()
		chip.custom_minimum_size = Vector2(34, 30)
		chip.add_theme_stylebox_override("panel", _panel_style(Color("#07121d"), Color(entry[1]), 7))

		var icon := TextureRect.new()
		icon.texture = _load_v2_texture(entry[0])
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(icon)
		status.add_child(chip)

	var trait_label := Label.new()
	trait_label.text = "ERDPANZER"
	trait_label.add_theme_color_override("font_color", Color("#d4e1ed"))
	trait_label.add_theme_font_size_override("font_size", 11)
	status.add_child(trait_label)

func _build_damage_number() -> void:
	damage_label = Label.new()
	damage_label.text = ""
	damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	damage_label.add_theme_color_override("font_color", Color("#ffd927"))
	damage_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.98))
	damage_label.add_theme_constant_override("shadow_offset_x", 4)
	damage_label.add_theme_constant_override("shadow_offset_y", 4)
	damage_label.add_theme_font_size_override("font_size", 70)
	_anchor(damage_label, 0.70, 0.32, 0.99, 0.49)
	damage_label.rotation = deg_to_rad(-5.0)
	damage_label.z_index = 47
	damage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_label.visible = false
	stage.add_child(damage_label)

func _build_combat_bottom_hud() -> void:
	var bottom := ColorRect.new()
	_anchor(bottom, 0.0, 0.745, 1.0, 1.0)
	bottom.color = Color(0.015, 0.04, 0.065, 0.76)
	bottom.z_index = 24
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(bottom)

	var vitals := HBoxContainer.new()
	_anchor(vitals, 0.025, 0.755, 0.87, 0.825)
	vitals.add_theme_constant_override("separation", 8)
	vitals.z_index = 28
	stage.add_child(vitals)

	# HP
	var hp_card := PanelContainer.new()
	hp_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_card.add_theme_stylebox_override("panel", _panel_style(Color("#091722"), Color("#314353"), 12))
	var hp_box := VBoxContainer.new()
	hp_box.add_theme_constant_override("separation", 2)
	hp_card.add_child(hp_box)
	var hp_title := Label.new()
	hp_title.text = "HP"
	hp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_title.add_theme_color_override("font_color", Color("#ff7180"))
	hp_title.add_theme_font_size_override("font_size", 13)
	hp_box.add_child(hp_title)
	var hp_wrap := Control.new()
	hp_wrap.custom_minimum_size = Vector2(0, 25)
	hp_box.add_child(hp_wrap)
	player_hp_bar = ProgressBar.new()
	player_hp_bar.min_value = 0
	player_hp_bar.max_value = 100
	player_hp_bar.value = player_hp
	player_hp_bar.show_percentage = false
	_anchor(player_hp_bar, 0.0, 0.25, 1.0, 0.90)
	player_hp_bar.add_theme_stylebox_override("background", _panel_style(Color("#020609"), Color("#32151c"), 9))
	player_hp_bar.add_theme_stylebox_override("fill", _panel_style(Color("#ff3d56"), Color("#ff7080"), 9))
	hp_wrap.add_child(player_hp_bar)
	player_hp_text = Label.new()
	player_hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_hp_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	player_hp_text.add_theme_color_override("font_color", Color.WHITE)
	player_hp_text.add_theme_font_size_override("font_size", 11)
	_anchor(player_hp_text, 0.0, 0.0, 1.0, 1.0)
	hp_wrap.add_child(player_hp_text)
	vitals.add_child(hp_card)

	# Momentum
	var momentum_card := PanelContainer.new()
	momentum_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	momentum_card.add_theme_stylebox_override("panel", _panel_style(Color("#091722"), Color("#392e57"), 12))
	var momentum_box := VBoxContainer.new()
	momentum_card.add_child(momentum_box)
	var momentum_title := Label.new()
	momentum_title.text = "MOMENTUM 68%"
	momentum_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	momentum_title.add_theme_color_override("font_color", Color("#b98cff"))
	momentum_title.add_theme_font_size_override("font_size", 11)
	momentum_box.add_child(momentum_title)
	momentum_bar = ProgressBar.new()
	momentum_bar.min_value = 0
	momentum_bar.max_value = 100
	momentum_bar.value = 68
	momentum_bar.show_percentage = false
	momentum_bar.custom_minimum_size = Vector2(0, 18)
	momentum_bar.add_theme_stylebox_override("background", _panel_style(Color("#04070c"), Color("#2a2238"), 8))
	momentum_bar.add_theme_stylebox_override("fill", _panel_style(Color("#8b38df"), Color("#bd65ff"), 8))
	momentum_box.add_child(momentum_bar)
	vitals.add_child(momentum_card)

	# Fury
	var fury_card := PanelContainer.new()
	fury_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fury_card.add_theme_stylebox_override("panel", _panel_style(Color("#091722"), Color("#5b331c"), 12))
	var fury_box := VBoxContainer.new()
	fury_card.add_child(fury_box)
	var fury_title := Label.new()
	fury_title.text = "ZORN 42%"
	fury_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fury_title.add_theme_color_override("font_color", Color("#ff9f40"))
	fury_title.add_theme_font_size_override("font_size", 11)
	fury_box.add_child(fury_title)
	fury_bar = ProgressBar.new()
	fury_bar.min_value = 0
	fury_bar.max_value = 100
	fury_bar.value = 42
	fury_bar.show_percentage = false
	fury_bar.custom_minimum_size = Vector2(0, 18)
	fury_bar.add_theme_stylebox_override("background", _panel_style(Color("#04070c"), Color("#422815"), 8))
	fury_bar.add_theme_stylebox_override("fill", _panel_style(Color("#ff861f"), Color("#ffb04c"), 8))
	fury_box.add_child(fury_bar)
	vitals.add_child(fury_card)

	auto_button = Button.new()
	auto_button.text = ""
	auto_button.focus_mode = Control.FOCUS_NONE
	auto_button.add_theme_font_size_override("font_size", 13)
	auto_button.add_theme_color_override("font_color", Color.WHITE)
	auto_button.add_theme_stylebox_override("normal", _panel_style(Color("#071629"), Color("#168cff"), 36))
	auto_button.add_theme_stylebox_override("pressed", _panel_style(Color("#0b2948"), Color("#67cbff"), 36))
	_anchor(auto_button, 1.0, 0.758, 1.0, 0.758, -94.0, 0.0, -14.0, 80.0)
	auto_button.z_index = 29
	auto_button.pressed.connect(_toggle_auto)
	stage.add_child(auto_button)
	_decorate_icon_button(auto_button, "ui_v4/combat_core/auto.png", "AUTO", false)

	var skills := HBoxContainer.new()
	_anchor(skills, 0.045, 0.846, 0.955, 0.982)
	skills.alignment = BoxContainer.ALIGNMENT_CENTER
	skills.add_theme_constant_override("separation", 16)
	skills.z_index = 31
	stage.add_child(skills)

	var skill_data := [
		["ui_v4/combat_core/attack.png", "2.5", "#2e83ff", false],
		["ui_v4/combat_core/target.png", "6.8", "#8f43e8", true],
		["ui_v4/combat_core/heavy_attack.png", "LV.50", "#69717c", true],
		["ui_v4/combat_core/heavy_attack.png", "18.4", "#ff7d21", true]
	]
	for data in skill_data:
		var button := Button.new()
		button.text = ""
		button.custom_minimum_size = Vector2(104, 104)
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.focus_mode = Control.FOCUS_NONE
		button.disabled = bool(data[3])
		button.add_theme_stylebox_override("normal", _panel_style(Color("#0b1a29"), Color(data[2]), 52))
		button.add_theme_stylebox_override("pressed", _panel_style(Color("#123652"), Color("#a8e3ff"), 52))
		button.add_theme_stylebox_override("disabled", _panel_style(Color("#111821"), Color(data[2]), 52))
		if not bool(data[3]):
			button.pressed.connect(_attack)
		skills.add_child(button)
		_decorate_icon_button(button, data[0], data[1], bool(data[3]))

func _build_result_overlay() -> void:
	result_overlay = ColorRect.new()
	_anchor(result_overlay, 0.0, 0.0, 1.0, 1.0)
	result_overlay.color = Color(0.015, 0.035, 0.055, 0.82)
	result_overlay.z_index = 80
	result_overlay.visible = false
	stage.add_child(result_overlay)

	var card := PanelContainer.new()
	_anchor(card, 0.20, 0.35, 0.80, 0.64)
	card.add_theme_stylebox_override("panel", _panel_style(Color("#0a1826"), Color("#5c8db3"), 22))
	result_overlay.add_child(card)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 16)
	card.add_child(content)

	var eyebrow := Label.new()
	eyebrow.text = "WOLKGARTEN"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_color_override("font_color", Color("#9bb8ce"))
	eyebrow.add_theme_font_size_override("font_size", 15)
	content.add_child(eyebrow)

	result_title = Label.new()
	result_title.text = "SIEG"
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title.add_theme_color_override("font_color", Color.WHITE)
	result_title.add_theme_font_size_override("font_size", 36)
	content.add_child(result_title)

	var subtitle := Label.new()
	subtitle.text = "Combat Master Convergence 02"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color("#9eafbf"))
	subtitle.add_theme_font_size_override("font_size", 14)
	content.add_child(subtitle)

	var restart := Button.new()
	restart.text = "NEUSTART"
	restart.custom_minimum_size = Vector2(210, 56)
	restart.focus_mode = Control.FOCUS_NONE
	restart.add_theme_font_size_override("font_size", 16)
	restart.add_theme_stylebox_override("normal", _panel_style(Color("#17324b"), Color("#66b5e7"), 14))
	restart.add_theme_stylebox_override("pressed", _panel_style(Color("#214963"), Color("#9bdcff"), 14))
	restart.pressed.connect(_restart)
	content.add_child(restart)


func _build_bottom_nav() -> void:
	var nav := PanelContainer.new()
	_anchor(nav, 0.0, 1.0, 1.0, 1.0, 0.0, -92.0, 0.0, 0.0)
	nav.add_theme_stylebox_override("panel", _panel_style(Color("#06101a"), Color("#244c68"), 0))
	add_child(nav)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 0)
	nav.add_child(row)

	var entries := [
		["ui_v4/navigation/combat.png", "KAMPF"],
		["ui_v4/navigation/quest.png", "ABENTEUER"],
		["ui_v4/navigation/monster.png", "WESEN"],
		["ui_v4/navigation/inventory.png", "BEUTE"],
		["ui_v4/navigation/menu.png", "MEHR"]
	]
	for entry in entries:
		var button := Button.new()
		button.text = ""
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_stylebox_override("normal", _panel_style(Color("#091522") if entry[1] != "KAMPF" else Color("#33135a"), Color("#173448") if entry[1] != "KAMPF" else Color("#a23cff"), 0))
		row.add_child(button)
		_decorate_nav_button(button, entry[0], entry[1], entry[1] == "KAMPF")

func _add_world_texture(node_name: String, left: float, top: float, right: float, bottom: float, layer: int) -> void:
	var texture_rect := _make_texture_rect()
	texture_rect.name = node_name
	_anchor(texture_rect, left, top, right, bottom)
	texture_rect.z_index = layer
	stage.add_child(texture_rect)


func _add_shadow(parent: Control, left: float, top: float, right: float, bottom: float) -> void:
	var shadow := ColorRect.new()
	_anchor(shadow, left, top, right, bottom)
	shadow.color = Color(0.02, 0.07, 0.06, 0.28)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.z_index = -1
	parent.add_child(shadow)


func _make_texture_rect() -> TextureRect:
	var texture_rect := TextureRect.new()
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return texture_rect


func _load_production_assets() -> void:
	_set_texture_by_name("Castle", WORLD_FILES["castle"])
	_set_texture_by_name("Float", WORLD_FILES["float"])
	_set_texture_by_name("Ruin", WORLD_FILES["ruin"])
	_set_texture_by_name("Ruins", WORLD_FILES["ruins"])
	_set_texture_by_name("Platform", WORLD_FILES["platform"])
	_set_texture_by_name("Foreground", WORLD_FILES["foreground"])
	var top_portrait := find_child("TopHeroPortrait", true, false) as TextureRect
	if top_portrait != null:
		top_portrait.texture = _load_texture(HERO_FILES["idle"])
	if slash_fx != null:
		slash_fx.texture = _load_texture("weapons/realmblade/vfx-crystal.png")
	if impact_fx != null:
		impact_fx.texture = _load_v2_texture("v190/vfx/combat_impacts/ice_impact_strong.png")
	_set_hero_state("idle")
	_set_enemy_state("idle")


func _set_texture_by_name(node_name: String, relative_path: String) -> void:
	var node := stage.get_node_or_null(node_name) as TextureRect
	if node == null:
		return
	node.texture = _load_texture(relative_path)


func _load_texture(relative_path: String) -> Texture2D:
	var path := ASSET_ROOT + relative_path
	if not ResourceLoader.exists(path):
		push_error("Missing REALM ALLIANCE production asset: " + path)
		return null
	return load(path) as Texture2D


func _set_hero_state(state: String) -> void:
	hero_art.texture = _load_texture(HERO_FILES.get(state, HERO_FILES["idle"]))


func _set_enemy_state(state: String) -> void:
	enemy_art.texture = _load_texture(ENEMY_FILES.get(state, ENEMY_FILES["idle"]))


func _attack() -> void:
	if busy or result_overlay.visible:
		return

	busy = true
	attack_hint.visible = false
	_set_hero_state("attack")

	var hero_start := hero_holder.position
	var hero_tween := create_tween()
	hero_tween.tween_property(hero_holder, "position", hero_start + Vector2(18, -3), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	hero_tween.tween_property(hero_holder, "position", hero_start, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await get_tree().create_timer(0.09).timeout

	var damage := 25
	enemy_hp = maxi(0, enemy_hp - damage)
	_set_enemy_state("hit")
	if slash_fx != null:
		slash_fx.visible = true
		slash_fx.modulate = Color(1.1, 1.15, 1.35, 1.0)
		var fx_tween := create_tween()
		fx_tween.tween_property(slash_fx, "modulate:a", 0.0, 0.24)
		fx_tween.finished.connect(func():
			if is_instance_valid(slash_fx):
				slash_fx.visible = false
				slash_fx.modulate = Color.WHITE
		)

	if impact_fx != null:
		impact_fx.visible = true
		impact_fx.scale = Vector2(0.72, 0.72)
		impact_fx.modulate = Color.WHITE
		var impact_tween := create_tween()
		impact_tween.set_parallel(true)
		impact_tween.tween_property(impact_fx, "scale", Vector2.ONE, 0.18)
		impact_tween.tween_property(impact_fx, "modulate:a", 0.0, 0.28)
		impact_tween.finished.connect(func():
			if is_instance_valid(impact_fx):
				impact_fx.visible = false
				impact_fx.scale = Vector2.ONE
				impact_fx.modulate = Color.WHITE
		)
	_show_damage(DISPLAY_DAMAGE[damage_index % DISPLAY_DAMAGE.size()])
	damage_index += 1
	_refresh_hud()

	var enemy_start := enemy_holder.position
	var enemy_tween := create_tween()
	enemy_tween.tween_property(enemy_holder, "position", enemy_start + Vector2(10, 0), 0.07)
	enemy_tween.tween_property(enemy_holder, "position", enemy_start, 0.11)

	await get_tree().create_timer(0.19).timeout

	if enemy_hp <= 0:
		_set_enemy_state("defeated")
		_set_hero_state("victory")
		await get_tree().create_timer(0.35).timeout
		_show_result(true)
		busy = false
		return

	_set_hero_state("idle")
	_set_enemy_state("attack")
	await get_tree().create_timer(0.12).timeout

	player_hp = maxi(0, player_hp - 12)
	_set_hero_state("hit")
	hero_art.modulate = Color(1.35, 0.72, 0.72, 1.0)
	_refresh_hud()

	await get_tree().create_timer(0.13).timeout
	hero_art.modulate = Color.WHITE

	if player_hp <= 0:
		_set_hero_state("defeat")
		_set_enemy_state("idle")
		await get_tree().create_timer(0.30).timeout
		_show_result(false)
		busy = false
		return

	_set_hero_state("idle")
	_set_enemy_state("idle")
	busy = false


func _show_damage(value: int) -> void:
	damage_label.text = "-%d" % value
	damage_label.visible = true
	damage_label.modulate = Color.WHITE
	var start_y := damage_label.position.y

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(damage_label, "position:y", start_y - 34.0, 0.38)
	tween.tween_property(damage_label, "modulate:a", 0.0, 0.38)
	await tween.finished
	damage_label.position.y = start_y
	damage_label.visible = false


func _refresh_hud() -> void:
	if enemy_hp_bar != null:
		enemy_hp_bar.value = enemy_hp
	if enemy_hp_text != null:
		var current_k := 412.0 * (float(enemy_hp) / float(enemy_hp_max))
		enemy_hp_text.text = "%.1fK / 412.0K" % current_k
	if player_hp_bar != null:
		player_hp_bar.value = player_hp
	if player_hp_text != null:
		var visible_hp := roundi(1420.0 * (float(player_hp) / 100.0))
		player_hp_text.text = "%s / 1.420" % _format_thousands(visible_hp)


func _show_result(victory: bool) -> void:
	result_title.text = "SIEG" if victory else "NIEDERLAGE"
	result_title.add_theme_color_override("font_color", Color("#fff1a8") if victory else Color("#ff8794"))
	result_overlay.visible = true


func _restart() -> void:
	busy = false
	player_hp = 100
	enemy_hp = enemy_hp_max
	result_overlay.visible = false
	attack_hint.visible = true
	hero_art.modulate = Color.WHITE
	damage_index = 0
	if slash_fx != null:
		slash_fx.visible = false
		slash_fx.modulate = Color.WHITE
	if impact_fx != null:
		impact_fx.visible = false
		impact_fx.scale = Vector2.ONE
		impact_fx.modulate = Color.WHITE
	_set_hero_state("idle")
	_set_enemy_state("idle")
	_refresh_hud()


func _toggle_auto() -> void:
	auto_enabled = not auto_enabled
	if auto_button != null:
		var caption := auto_button.get_node_or_null("Caption") as Label
		if caption != null:
			caption.text = "AUTO ON" if auto_enabled else "AUTO"


func _format_thousands(value: int) -> String:
	var raw := str(value)
	var out := ""
	var count := 0
	for i in range(raw.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			out = "." + out
		out = raw[i] + out
		count += 1
	return out


func _load_v2_texture(relative_path: String) -> Texture2D:
	var path := V2_ASSET_ROOT + relative_path
	if not ResourceLoader.exists(path):
		push_error("Missing REALM ALLIANCE V2 asset: " + path)
		return null
	return load(path) as Texture2D


func _decorate_icon_button(button: Button, relative_path: String, caption_text: String, dimmed: bool) -> void:
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.texture = _load_v2_texture(relative_path)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.modulate = Color(0.62, 0.66, 0.72, 0.85) if dimmed else Color.WHITE
	_anchor(icon, 0.18, 0.08, 0.82, 0.72)
	button.add_child(icon)

	var caption := Label.new()
	caption.name = "Caption"
	caption.text = caption_text
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.add_theme_color_override("font_color", Color("#8d98a8") if dimmed else Color.WHITE)
	caption.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	caption.add_theme_constant_override("shadow_offset_x", 2)
	caption.add_theme_constant_override("shadow_offset_y", 2)
	caption.add_theme_font_size_override("font_size", 12)
	_anchor(caption, 0.0, 0.68, 1.0, 0.98)
	button.add_child(caption)


func _decorate_nav_button(button: Button, relative_path: String, caption_text: String, active: bool) -> void:
	var icon := TextureRect.new()
	icon.texture = _load_v2_texture(relative_path)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.modulate = Color.WHITE if active else Color(0.70, 0.76, 0.86, 0.86)
	_anchor(icon, 0.32, 0.08, 0.68, 0.58)
	button.add_child(icon)

	var caption := Label.new()
	caption.text = caption_text
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.add_theme_color_override("font_color", Color("#f1e6ff") if active else Color("#9aaac0"))
	caption.add_theme_font_size_override("font_size", 12)
	_anchor(caption, 0.0, 0.58, 1.0, 0.96)
	button.add_child(caption)


func _toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _panel_style(background: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 8
	style.content_margin_top = 5
	style.content_margin_right = 8
	style.content_margin_bottom = 5
	return style


func _anchor(
	control: Control,
	left: float,
	top: float,
	right: float,
	bottom: float,
	offset_left: float = 0.0,
	offset_top: float = 0.0,
	offset_right: float = 0.0,
	offset_bottom: float = 0.0
) -> void:
	control.anchor_left = left
	control.anchor_top = top
	control.anchor_right = right
	control.anchor_bottom = bottom
	control.offset_left = offset_left
	control.offset_top = offset_top
	control.offset_right = offset_right
	control.offset_bottom = offset_bottom
