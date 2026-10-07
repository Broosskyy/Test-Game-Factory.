extends Control

const PORTRAIT_REFERENCE := Vector2i(720, 1280)
const LANDSCAPE_REFERENCE := Vector2i(960, 540)

const COMBAT_ROOT := "res://assets/realm_alliance/production/"
const V2_ROOT := "res://assets/realm_alliance/v2/"
const V2_GAME_ROOT := "res://assets/realm_alliance/v2_game/"
const RUNTIME_HERO_ROOT := "res://assets/realm_alliance/runtime/hero/"
const CombatLayout = preload("res://realm_alliance/combat/gruenhain_combat_layout.gd")
const HeroVisualRig = preload("res://realm_alliance/combat/hero_visual_rig.gd")

# Clean HeroBody art never owns the gameplay weapon.
# Attack/skill/victory use the clean idle body plus motion/weapon animation,
# avoiding the inconsistent legacy state crops.
const HERO_FILES := {
	"idle": "idle.webp",
	"attack": "idle.webp",
	"skill": "idle.webp",
	"hit": "idle.webp",
	"victory": "idle.webp",
	"defeat": "defeat.webp",
}

# Gameplay item and visual asset stay separate from the hero body.
# Later this can be replaced by inventory/equipment data without changing the visual rig.
const STARTER_WEAPON := {
	"id": "realmblade_basic",
	"name": "Realmblade",
	"level": 1,
	"upgrade": 0,
	"base_damage": 25,
	"texture": "weapons/realmblade/blade-basic.png",
	"grip_uv": Vector2(0.50, 0.92),
	"base_rotation_deg": 0.0,
}

const RUN_SEQUENCE := [
	{
		"id": "M001",
		"name": "Waldwinzling",
		"tier": "NORMAL",
		"level": 12,
		"max_hp": 75,
		"display_hp_k": 68.0,
		"enemy_damage": 2,
		"layout": "normal",
	},
	{
		"id": "M002",
		"name": "Blatthorn",
		"tier": "NORMAL",
		"level": 14,
		"max_hp": 90,
		"display_hp_k": 84.0,
		"enemy_damage": 3,
		"layout": "normal",
	},
	{
		"id": "M004",
		"name": "Pilzling",
		"tier": "NORMAL",
		"level": 16,
		"max_hp": 105,
		"display_hp_k": 96.0,
		"enemy_damage": 3,
		"layout": "normal",
	},
	{
		"id": "M010",
		"name": "Waldgeist",
		"tier": "ELITE",
		"level": 22,
		"max_hp": 150,
		"display_hp_k": 184.0,
		"enemy_damage": 4,
		"layout": "elite",
	},
	{
		"id": "B001",
		"name": "Mooskönig",
		"tier": "BOSS",
		"level": 30,
		"max_hp": 250,
		"display_hp_k": 620.0,
		"enemy_damage": 5,
		"layout": "boss",
	},
]

const DISPLAY_DAMAGE := [5274, 2931, 8416, 2605, 6128, 3442]

var player_hp := 100
var player_level := 42
var player_xp := 72
var player_momentum := 10
var player_rage := 0
var hero_damage := 25

var encounter_index := 0
var enemy_hp := 1
var enemy_hp_max := 1
var current_enemy: Dictionary = {}

var run_mode := "combat"
var busy := false
var auto_enabled := false
var auto_cooldown := 0.0
var damage_index := 0
var first_input_hint_available := true

var _last_landscape := false
var _profile_initialized := false
var _applying_profile := false

var stage: Control

# Layout slots never animate. Motion wrappers animate inside the slots.
var hero_holder: Control
var hero_motion: Control
var hero_rig: Control
var enemy_holder: Control
var enemy_motion: Control
var hero_art: TextureRect
var enemy_art: TextureRect
var hit_fx: TextureRect
var _enemy_texture_size := Vector2.ONE
var _enemy_used_rect := Rect2(Vector2.ZERO, Vector2.ONE)

var world_pill: PanelContainer
var streak_panel: PanelContainer
var enemy_hud: PanelContainer
var bottom_backing: ColorRect
var vitals_row: HBoxContainer
var skills_row: HBoxContainer

var enemy_name_label: Label
var enemy_tier_label: Label
var enemy_level_label: Label
var enemy_hp_bar: ProgressBar
var enemy_hp_text: Label
var progress_label: Label

var player_hp_bar: ProgressBar
var player_hp_text: Label
var player_level_label: Label
var player_xp_bar: ProgressBar
var player_xp_text: Label
var momentum_bar: ProgressBar
var momentum_label: Label
var rage_bar: ProgressBar
var rage_label: Label
var damage_label: Label

var attack_hint: Label
var auto_button: Button

var level_overlay: ColorRect
var loot_overlay: ColorRect
var result_overlay: ColorRect
var result_title: Label
var result_detail: Label
var restart_button: Button
var chest_art: TextureRect


func _ready() -> void:
	_apply_orientation_profile()

	if not get_window().size_changed.is_connected(_on_window_size_changed):
		get_window().size_changed.connect(_on_window_size_changed)

	_build_interface()
	_validate_required_assets()
	_validate_layout_contract()
	_start_run()


func _process(delta: float) -> void:
	if not auto_enabled or run_mode != "combat" or busy:
		return

	auto_cooldown -= delta
	if auto_cooldown <= 0.0:
		auto_cooldown = 0.30
		_attack()


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

	if stage != null:
		_apply_master_layout()


func _build_interface() -> void:
	var app_bg := ColorRect.new()
	_anchor(app_bg, 0.0, 0.0, 1.0, 1.0)
	app_bg.color = Color("#06101a")
	app_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(app_bg)

	_build_header()
	_build_stage()
	_build_bottom_nav()
	_build_level_overlay()
	_build_loot_overlay()
	_build_result_overlay()


func _build_header() -> void:
	var header := Control.new()
	_anchor(header, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 94.0)
	header.z_index = 100
	add_child(header)

	var bg := Panel.new()
	_anchor(bg, 0.0, 0.0, 1.0, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_theme_stylebox_override("panel", _panel_style(Color("#071522"), Color("#244e6b"), 0))
	header.add_child(bg)

	var player_chip := Panel.new()
	_anchor(player_chip, 0.012, 0.10, 0.305, 0.90)
	player_chip.add_theme_stylebox_override("panel", _panel_style(Color("#0b1b2c"), Color("#315f83"), 16))
	header.add_child(player_chip)

	var avatar := TextureRect.new()
	avatar.texture = _load_runtime_hero_texture(HERO_FILES["idle"])
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_anchor(avatar, 0.018, 0.08, 0.26, 0.92)
	player_chip.add_child(avatar)

	player_level_label = Label.new()
	player_level_label.text = "LV. 42"
	player_level_label.add_theme_color_override("font_color", Color.WHITE)
	player_level_label.add_theme_font_size_override("font_size", 21)
	_anchor(player_level_label, 0.29, 0.08, 0.94, 0.48)
	player_chip.add_child(player_level_label)

	player_xp_bar = ProgressBar.new()
	player_xp_bar.min_value = 0
	player_xp_bar.max_value = 100
	player_xp_bar.value = player_xp
	player_xp_bar.show_percentage = false
	player_xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_xp_bar.add_theme_stylebox_override("background", _panel_style(Color("#06101a"), Color("#10293c"), 8))
	player_xp_bar.add_theme_stylebox_override("fill", _panel_style(Color("#2c9cff"), Color("#6dc8ff"), 8))
	_anchor(player_xp_bar, 0.29, 0.57, 0.80, 0.82)
	player_chip.add_child(player_xp_bar)

	player_xp_text = Label.new()
	player_xp_text.text = "%d%%" % mini(player_xp, 100)
	player_xp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_xp_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	player_xp_text.add_theme_color_override("font_color", Color("#dceeff"))
	player_xp_text.add_theme_font_size_override("font_size", 12)
	_anchor(player_xp_text, 0.81, 0.52, 0.98, 0.86)
	player_chip.add_child(player_xp_text)

	var resources := HBoxContainer.new()
	_anchor(resources, 0.305, 0.17, 0.79, 0.84)
	resources.alignment = BoxContainer.ALIGNMENT_CENTER
	resources.add_theme_constant_override("separation", 7)
	header.add_child(resources)

	var resource_data := [
		["ui_v4/navigation/currency.png", "128.4K"],
		["ui_v4/inventory_consumables/purple_orb.png", "2.580"],
		["ui_v4/inventory_consumables/blue_crystal.png", "347"],
	]

	for entry in resource_data:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(112, 44)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", _panel_style(Color("#071624"), Color("#24445f"), 16))

		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 7)
		card.add_child(row)

		var icon := TextureRect.new()
		icon.texture = _load_v2_texture(entry[0])
		icon.custom_minimum_size = Vector2(23, 23)
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

		resources.add_child(card)

	var settings := Button.new()
	settings.text = "SET"
	settings.focus_mode = Control.FOCUS_NONE
	settings.add_theme_font_size_override("font_size", 11)
	settings.add_theme_stylebox_override("normal", _panel_style(Color("#0b1a2b"), Color("#31587a"), 12))
	_anchor(settings, 0.80, 0.18, 0.89, 0.82)
	header.add_child(settings)

	if OS.get_name() == "Web":
		var fullscreen := Button.new()
		fullscreen.text = "FULL"
		fullscreen.focus_mode = Control.FOCUS_NONE
		fullscreen.add_theme_font_size_override("font_size", 11)
		fullscreen.add_theme_stylebox_override("normal", _panel_style(Color("#0b1a2b"), Color("#31587a"), 12))
		_anchor(fullscreen, 0.90, 0.18, 0.985, 0.82)
		fullscreen.pressed.connect(_toggle_fullscreen)
		header.add_child(fullscreen)


func _build_stage() -> void:
	stage = Control.new()
	_anchor(stage, 0.0, 0.0, 1.0, 1.0, 0.0, 94.0, 0.0, -118.0)
	stage.clip_contents = true
	add_child(stage)

	var background := TextureRect.new()
	background.texture = _load_game_texture("world/greenvale/BG001_gruenhain_home_v11.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_anchor(background, 0.0, 0.0, 1.0, 1.0)
	stage.add_child(background)

	var shade := ColorRect.new()
	_anchor(shade, 0.0, 0.0, 1.0, 1.0)
	shade.color = Color(0.01, 0.03, 0.02, 0.09)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.z_index = 2
	stage.add_child(shade)

	world_pill = PanelContainer.new()
	world_pill.z_index = 30
	world_pill.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.08, 0.13, 0.94), Color("#35678c"), 24))
	stage.add_child(world_pill)

	var world_row := HBoxContainer.new()
	world_row.alignment = BoxContainer.ALIGNMENT_CENTER
	world_row.add_theme_constant_override("separation", 10)
	world_pill.add_child(world_row)

	var region := Label.new()
	region.text = "GRÜNHAIN"
	region.add_theme_color_override("font_color", Color.WHITE)
	region.add_theme_font_size_override("font_size", 19)
	world_row.add_child(region)

	progress_label = Label.new()
	progress_label.text = "1 / 5"
	progress_label.add_theme_color_override("font_color", Color("#8bd5ff"))
	progress_label.add_theme_font_size_override("font_size", 15)
	world_row.add_child(progress_label)

	streak_panel = PanelContainer.new()
	streak_panel.z_index = 31
	streak_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.05, 0.08, 0.10, 0.90), Color("#80602c"), 12))
	stage.add_child(streak_panel)

	var streak_text := Label.new()
	streak_text.text = "12ER SIEGESSERIE\n+24% GOLD  +18% XP"
	streak_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	streak_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	streak_text.add_theme_color_override("font_color", Color("#ffe39d"))
	streak_text.add_theme_font_size_override("font_size", 12)
	streak_panel.add_child(streak_text)

	hero_holder = Control.new()
	hero_holder.z_index = 12
	hero_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(hero_holder)

	hero_motion = Control.new()
	_anchor(hero_motion, 0.0, 0.0, 1.0, 1.0)
	hero_motion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_holder.add_child(hero_motion)

	hero_rig = HeroVisualRig.new()
	_anchor(hero_rig, 0.0, 0.0, 1.0, 1.0)
	hero_motion.add_child(hero_rig)

	hero_art = hero_rig.body_art
	hero_rig.set_weapon(
		_load_combat_texture(str(STARTER_WEAPON["texture"])),
		STARTER_WEAPON["grip_uv"],
		float(STARTER_WEAPON["base_rotation_deg"])
	)

	enemy_holder = Control.new()
	enemy_holder.z_index = 11
	enemy_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(enemy_holder)

	enemy_motion = Control.new()
	_anchor(enemy_motion, 0.0, 0.0, 1.0, 1.0)
	enemy_motion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_holder.add_child(enemy_motion)

	enemy_art = TextureRect.new()
	enemy_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	enemy_art.stretch_mode = TextureRect.STRETCH_SCALE
	enemy_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_motion.add_child(enemy_art)

	hit_fx = _make_texture_rect()
	hit_fx.texture = _load_v2_texture("v190/vfx/combat_impacts/nature_impact.png")
	hit_fx.z_index = 17
	hit_fx.visible = false
	stage.add_child(hit_fx)

	_build_enemy_hud()
	_build_damage_number()
	_build_combat_bottom_hud()

	var tap_zone := Button.new()
	tap_zone.text = ""
	tap_zone.flat = true
	tap_zone.focus_mode = Control.FOCUS_NONE
	_anchor(tap_zone, 0.0, 0.12, 1.0, 0.72)
	tap_zone.z_index = 18
	tap_zone.pressed.connect(_attack)
	stage.add_child(tap_zone)

	attack_hint = Label.new()
	attack_hint.text = "TIPPEN ZUM ANGREIFEN"
	attack_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	attack_hint.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0, 0.76))
	attack_hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	attack_hint.add_theme_constant_override("shadow_offset_x", 2)
	attack_hint.add_theme_constant_override("shadow_offset_y", 2)
	attack_hint.add_theme_font_size_override("font_size", 14)
	attack_hint.z_index = 32
	attack_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(attack_hint)

	_apply_master_layout()


func _build_enemy_hud() -> void:
	enemy_hud = PanelContainer.new()
	enemy_hud.z_index = 40
	enemy_hud.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.065, 0.105, 0.96), Color("#4c7694"), 15))
	stage.add_child(enemy_hud)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	enemy_hud.add_child(box)

	var title := HBoxContainer.new()
	title.alignment = BoxContainer.ALIGNMENT_CENTER
	title.add_theme_constant_override("separation", 8)
	box.add_child(title)

	enemy_tier_label = Label.new()
	enemy_tier_label.custom_minimum_size = Vector2(54, 28)
	enemy_tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_tier_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	enemy_tier_label.add_theme_font_size_override("font_size", 11)
	title.add_child(enemy_tier_label)

	enemy_name_label = Label.new()
	enemy_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	enemy_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_name_label.add_theme_color_override("font_color", Color.WHITE)
	enemy_name_label.add_theme_font_size_override("font_size", 20)
	title.add_child(enemy_name_label)

	enemy_level_label = Label.new()
	enemy_level_label.add_theme_color_override("font_color", Color("#edf4ff"))
	enemy_level_label.add_theme_font_size_override("font_size", 14)
	title.add_child(enemy_level_label)

	var bar_wrap := Control.new()
	bar_wrap.custom_minimum_size = Vector2(0, 25)
	box.add_child(bar_wrap)

	enemy_hp_bar = ProgressBar.new()
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
	status.add_theme_constant_override("separation", 7)
	box.add_child(status)

	for icon_path in [
		"ui_v4/combat_status/attack_up.png",
		"ui_v4/combat_status/defense_up.png",
	]:
		var icon := TextureRect.new()
		icon.texture = _load_v2_texture(icon_path)
		icon.custom_minimum_size = Vector2(27, 27)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		status.add_child(icon)


func _build_damage_number() -> void:
	damage_label = Label.new()
	damage_label.visible = false
	damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	damage_label.add_theme_color_override("font_color", Color("#ffd927"))
	damage_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.98))
	damage_label.add_theme_constant_override("shadow_offset_x", 4)
	damage_label.add_theme_constant_override("shadow_offset_y", 4)
	damage_label.add_theme_font_size_override("font_size", 54)
	damage_label.rotation = deg_to_rad(-4.0)
	damage_label.z_index = 47
	damage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_anchor(damage_label, 0.04, -0.12, 0.96, 0.28)
	enemy_holder.add_child(damage_label)


func _build_combat_bottom_hud() -> void:
	bottom_backing = ColorRect.new()
	bottom_backing.color = Color(0.015, 0.04, 0.065, 0.78)
	bottom_backing.z_index = 8
	bottom_backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(bottom_backing)

	vitals_row = HBoxContainer.new()
	vitals_row.add_theme_constant_override("separation", 8)
	vitals_row.z_index = 28
	stage.add_child(vitals_row)

	var hp_card := PanelContainer.new()
	hp_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_card.add_theme_stylebox_override("panel", _panel_style(Color("#091722"), Color("#314353"), 12))
	var hp_box := VBoxContainer.new()
	hp_card.add_child(hp_box)

	var hp_title := Label.new()
	hp_title.text = "HP"
	hp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_title.add_theme_color_override("font_color", Color("#ff7180"))
	hp_title.add_theme_font_size_override("font_size", 12)
	hp_box.add_child(hp_title)

	var hp_wrap := Control.new()
	hp_wrap.custom_minimum_size = Vector2(0, 24)
	hp_box.add_child(hp_wrap)

	player_hp_bar = ProgressBar.new()
	player_hp_bar.min_value = 0
	player_hp_bar.max_value = 100
	player_hp_bar.show_percentage = false
	_anchor(player_hp_bar, 0.0, 0.25, 1.0, 0.90)
	player_hp_bar.add_theme_stylebox_override("background", _panel_style(Color("#020609"), Color("#32151c"), 8))
	player_hp_bar.add_theme_stylebox_override("fill", _panel_style(Color("#ff3d56"), Color("#ff7080"), 8))
	hp_wrap.add_child(player_hp_bar)

	player_hp_text = Label.new()
	player_hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_hp_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	player_hp_text.add_theme_color_override("font_color", Color.WHITE)
	player_hp_text.add_theme_font_size_override("font_size", 11)
	_anchor(player_hp_text, 0.0, 0.0, 1.0, 1.0)
	hp_wrap.add_child(player_hp_text)

	vitals_row.add_child(hp_card)

	var momentum_card := PanelContainer.new()
	momentum_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	momentum_card.add_theme_stylebox_override("panel", _panel_style(Color("#091722"), Color("#a34cff"), 12))
	var momentum_box := VBoxContainer.new()
	momentum_card.add_child(momentum_box)
	momentum_label = Label.new()
	momentum_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	momentum_label.add_theme_color_override("font_color", Color("#a34cff"))
	momentum_label.add_theme_font_size_override("font_size", 11)
	momentum_box.add_child(momentum_label)
	momentum_bar = ProgressBar.new()
	momentum_bar.min_value = 0
	momentum_bar.max_value = 100
	momentum_bar.show_percentage = false
	momentum_bar.custom_minimum_size = Vector2(0, 18)
	momentum_bar.add_theme_stylebox_override("background", _panel_style(Color("#04070c"), Color("#222d38"), 8))
	momentum_bar.add_theme_stylebox_override("fill", _panel_style(Color("#a34cff"), Color("#c184ff"), 8))
	momentum_box.add_child(momentum_bar)
	vitals_row.add_child(momentum_card)

	var rage_card := PanelContainer.new()
	rage_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rage_card.add_theme_stylebox_override("panel", _panel_style(Color("#091722"), Color("#ff8b23"), 12))
	var rage_box := VBoxContainer.new()
	rage_card.add_child(rage_box)
	rage_label = Label.new()
	rage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rage_label.add_theme_color_override("font_color", Color("#ff8b23"))
	rage_label.add_theme_font_size_override("font_size", 11)
	rage_box.add_child(rage_label)
	rage_bar = ProgressBar.new()
	rage_bar.min_value = 0
	rage_bar.max_value = 100
	rage_bar.show_percentage = false
	rage_bar.custom_minimum_size = Vector2(0, 18)
	rage_bar.add_theme_stylebox_override("background", _panel_style(Color("#04070c"), Color("#222d38"), 8))
	rage_bar.add_theme_stylebox_override("fill", _panel_style(Color("#ff8b23"), Color("#ffb15e"), 8))
	rage_box.add_child(rage_bar)
	vitals_row.add_child(rage_card)

	auto_button = Button.new()
	auto_button.text = ""
	auto_button.focus_mode = Control.FOCUS_NONE
	auto_button.add_theme_stylebox_override("normal", _panel_style(Color("#071629"), Color("#168cff"), 42))
	auto_button.add_theme_stylebox_override("pressed", _panel_style(Color("#0b2948"), Color("#67cbff"), 42))
	_anchor(auto_button, 1.0, 0.728, 1.0, 0.728, -100.0, 0.0, -12.0, 88.0)
	auto_button.z_index = 29
	auto_button.pressed.connect(_toggle_auto)
	stage.add_child(auto_button)
	_decorate_icon_button(auto_button, "ui_v4/combat_core/auto.png", "AUTO", false)

	skills_row = HBoxContainer.new()
	skills_row.alignment = BoxContainer.ALIGNMENT_CENTER
	skills_row.add_theme_constant_override("separation", 16)
	skills_row.z_index = 31
	stage.add_child(skills_row)

	var skill_data := [
		["ui_v4/combat_core/attack.png", "2.5", "#2e83ff", false],
		["ui_v4/combat_core/target.png", "6.8", "#8f43e8", true],
		["ui_v4/combat_core/heavy_attack.png", "LV.50", "#69717c", true],
		["ui_v4/combat_core/heavy_attack.png", "18.4", "#ff7d21", true],
	]

	for data in skill_data:
		var button := Button.new()
		button.text = ""
		button.custom_minimum_size = Vector2(118, 118)
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.focus_mode = Control.FOCUS_NONE
		button.disabled = bool(data[3])
		button.add_theme_stylebox_override("normal", _panel_style(Color("#0b1a29"), Color(data[2]), 58))
		button.add_theme_stylebox_override("pressed", _panel_style(Color("#123652"), Color("#a8e3ff"), 58))
		button.add_theme_stylebox_override("disabled", _panel_style(Color("#111821"), Color(data[2]), 58))
		if not bool(data[3]):
			button.pressed.connect(_attack)
		skills_row.add_child(button)
		_decorate_icon_button(button, data[0], data[1], bool(data[3]))


func _build_bottom_nav() -> void:
	var nav := PanelContainer.new()
	_anchor(nav, 0.0, 1.0, 1.0, 1.0, 0.0, -118.0, 0.0, 0.0)
	nav.add_theme_stylebox_override("panel", _panel_style(Color("#06101a"), Color("#244c68"), 0))
	add_child(nav)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_child(row)

	var entries := [
		["ui_v4/navigation/combat.png", "KAMPF"],
		["ui_v4/navigation/quest.png", "ABENTEUER"],
		["ui_v4/navigation/monster.png", "WESEN"],
		["ui_v4/navigation/inventory.png", "BEUTE"],
		["ui_v4/navigation/menu.png", "MEHR"],
	]

	for entry in entries:
		var button := Button.new()
		button.text = ""
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_stylebox_override("normal", _panel_style(
			Color("#33135a") if entry[1] == "KAMPF" else Color("#091522"),
			Color("#a23cff") if entry[1] == "KAMPF" else Color("#173448"),
			0
		))
		row.add_child(button)
		_decorate_nav_button(button, entry[0], entry[1], entry[1] == "KAMPF")


func _build_level_overlay() -> void:
	level_overlay = ColorRect.new()
	_anchor(level_overlay, 0.0, 0.0, 1.0, 1.0)
	level_overlay.color = Color(0.01, 0.025, 0.035, 0.70)
	level_overlay.z_index = 200
	level_overlay.visible = false
	add_child(level_overlay)

	var card := PanelContainer.new()
	_anchor(card, 0.20, 0.34, 0.80, 0.62)
	card.z_index = 2
	card.add_theme_stylebox_override("panel", _panel_style(Color("#0b1725"), Color("#d7a832"), 24))
	level_overlay.add_child(card)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 12)
	card.add_child(content)

	var art := TextureRect.new()
	art.texture = _load_v2_texture("ui_v4/upgrade_evolution_a/level_up.png")
	art.custom_minimum_size = Vector2(126, 96)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content.add_child(art)

	var title := Label.new()
	title.text = "LEVEL 43"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#ffe69b"))
	title.add_theme_font_size_override("font_size", 30)
	content.add_child(title)

	var stats := Label.new()
	stats.text = "+5 ANGRIFF\n+6 LEBEN\n+2 GOLDFUND"
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_color_override("font_color", Color("#eef5ff"))
	stats.add_theme_font_size_override("font_size", 14)
	content.add_child(stats)

	var continue_button := Button.new()
	continue_button.text = "WEITER"
	continue_button.custom_minimum_size = Vector2(190, 46)
	continue_button.focus_mode = Control.FOCUS_NONE
	continue_button.add_theme_font_size_override("font_size", 15)
	continue_button.add_theme_stylebox_override("normal", _panel_style(Color("#234e2f"), Color("#64da82"), 14))
	continue_button.pressed.connect(_continue_after_levelup)
	content.add_child(continue_button)


func _build_loot_overlay() -> void:
	loot_overlay = ColorRect.new()
	_anchor(loot_overlay, 0.0, 0.0, 1.0, 1.0)
	loot_overlay.color = Color(0.01, 0.025, 0.035, 0.72)
	loot_overlay.z_index = 210
	loot_overlay.visible = false
	add_child(loot_overlay)

	var card := PanelContainer.new()
	_anchor(card, 0.20, 0.31, 0.80, 0.64)
	card.z_index = 2
	card.add_theme_stylebox_override("panel", _panel_style(Color("#0b1725"), Color("#d7a832"), 24))
	loot_overlay.add_child(card)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 12)
	card.add_child(content)

	var title := Label.new()
	title.text = "BOSS-BEUTE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#ffe69b"))
	title.add_theme_font_size_override("font_size", 24)
	content.add_child(title)

	chest_art = TextureRect.new()
	chest_art.texture = _load_v2_texture("v190/rewards/chest_states/closed.png")
	chest_art.custom_minimum_size = Vector2(190, 150)
	chest_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chest_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content.add_child(chest_art)

	var reward := Label.new()
	reward.text = "GARANTIERTE BOSS-TRUHE"
	reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward.add_theme_color_override("font_color", Color("#dce9f5"))
	reward.add_theme_font_size_override("font_size", 13)
	content.add_child(reward)

	var open_button := Button.new()
	open_button.text = "TRUHE ÖFFNEN"
	open_button.custom_minimum_size = Vector2(205, 48)
	open_button.focus_mode = Control.FOCUS_NONE
	open_button.add_theme_font_size_override("font_size", 15)
	open_button.add_theme_stylebox_override("normal", _panel_style(Color("#5d3512"), Color("#ffc85f"), 14))
	open_button.pressed.connect(_open_loot)
	content.add_child(open_button)


func _build_result_overlay() -> void:
	result_overlay = ColorRect.new()
	_anchor(result_overlay, 0.0, 0.0, 1.0, 1.0)
	result_overlay.color = Color(0.01, 0.025, 0.035, 0.86)
	result_overlay.z_index = 220
	result_overlay.visible = false
	add_child(result_overlay)

	var card := PanelContainer.new()
	_anchor(card, 0.18, 0.31, 0.82, 0.68)
	card.add_theme_stylebox_override("panel", _panel_style(Color("#0b1725"), Color("#5b8fb4"), 24))
	result_overlay.add_child(card)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 18)
	card.add_child(content)

	var region := Label.new()
	region.text = "GRÜNHAIN · VERTICAL SLICE"
	region.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	region.add_theme_color_override("font_color", Color("#9db6c8"))
	region.add_theme_font_size_override("font_size", 14)
	content.add_child(region)

	result_title = Label.new()
	result_title.text = "SIEG"
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title.add_theme_font_size_override("font_size", 38)
	content.add_child(result_title)

	result_detail = Label.new()
	result_detail.text = ""
	result_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_detail.add_theme_color_override("font_color", Color("#c5d8e6"))
	result_detail.add_theme_font_size_override("font_size", 14)
	content.add_child(result_detail)

	restart_button = Button.new()
	restart_button.text = "NEUSTART"
	restart_button.custom_minimum_size = Vector2(230, 58)
	restart_button.focus_mode = Control.FOCUS_NONE
	restart_button.add_theme_font_size_override("font_size", 17)
	restart_button.add_theme_stylebox_override("normal", _panel_style(Color("#17324b"), Color("#66b5e7"), 14))
	restart_button.pressed.connect(_start_run)
	content.add_child(restart_button)


func _start_run() -> void:
	player_hp = 100
	player_level = 42
	player_xp = 72
	player_momentum = 20
	player_rage = 0
	hero_damage = int(STARTER_WEAPON["base_damage"])
	encounter_index = 0
	damage_index = 0
	first_input_hint_available = true
	auto_enabled = false
	auto_cooldown = 0.0
	busy = false
	run_mode = "combat"

	level_overlay.visible = false
	loot_overlay.visible = false
	result_overlay.visible = false

	hero_art.modulate = Color.WHITE
	hero_motion.position = Vector2.ZERO
	hero_motion.modulate = Color.WHITE
	enemy_motion.position = Vector2.ZERO
	enemy_motion.modulate = Color.WHITE
	_apply_master_layout()
	_set_hero_state("idle")

	if auto_button != null:
		var caption := auto_button.get_node_or_null("Caption") as Label
		if caption != null:
			caption.text = "AUTO"

	_start_encounter(0)
	_refresh_player_hud()


func _start_encounter(index: int) -> void:
	encounter_index = index
	current_enemy = RUN_SEQUENCE[index]
	enemy_hp_max = int(current_enemy["max_hp"])
	enemy_hp = enemy_hp_max
	run_mode = "combat"
	busy = false

	_apply_enemy_layout(str(current_enemy["layout"]))
	_set_enemy_state("idle")

	enemy_motion.position = Vector2(26, 6)
	enemy_motion.modulate = Color(1, 1, 1, 0)
	var spawn_tween := create_tween()
	spawn_tween.set_parallel(true)
	spawn_tween.tween_property(enemy_motion, "modulate:a", 1.0, 0.22)
	spawn_tween.tween_property(enemy_motion, "position", Vector2.ZERO, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	attack_hint.visible = encounter_index == 0 and first_input_hint_available
	_refresh_enemy_hud()


func _attack() -> void:
	if run_mode != "combat" or busy:
		return

	busy = true
	first_input_hint_available = false
	attack_hint.visible = false

	var hero_start := hero_motion.position
	_set_hero_state("attack")

	# Anticipation -> strike -> recovery. Only HeroMotion moves; HeroSlot stays locked.
	var hero_tween := create_tween()
	hero_tween.tween_property(hero_motion, "position", hero_start + Vector2(-5, 1), 0.055).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	hero_tween.tween_property(hero_motion, "position", hero_start + Vector2(22, -3), 0.085).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	hero_tween.tween_interval(0.045)
	hero_tween.tween_property(hero_motion, "position", hero_start, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(0.115).timeout

	enemy_hp = maxi(0, enemy_hp - hero_damage)
	player_momentum = mini(100, player_momentum + 5)
	_set_enemy_state("hit")
	enemy_art.modulate = Color(1.35, 1.35, 1.35, 1.0)
	_show_hit_fx()
	_show_damage()
	_refresh_enemy_hud()
	_refresh_player_hud()

	# Short hit-stop before recoil makes the impact readable.
	await get_tree().create_timer(0.055).timeout

	var enemy_start := enemy_motion.position
	var recoil := create_tween()
	recoil.tween_property(enemy_motion, "position", enemy_start + Vector2(18, -2), 0.055)
	recoil.tween_property(enemy_motion, "position", enemy_start - Vector2(4, 0), 0.06)
	recoil.tween_property(enemy_motion, "position", enemy_start, 0.09)

	var flash_tween := create_tween()
	flash_tween.tween_property(enemy_art, "modulate", Color.WHITE, 0.14)

	await get_tree().create_timer(0.19).timeout

	if enemy_hp <= 0:
		hero_motion.position = hero_start
		await _handle_enemy_defeat()
		busy = false
		return

	_set_hero_state("idle")
	await get_tree().create_timer(0.055).timeout

	# Enemy telegraph -> lunge -> hit -> recovery.
	_set_enemy_state("attack")
	var enemy_attack_start := enemy_motion.position
	var enemy_attack_tween := create_tween()
	enemy_attack_tween.tween_property(enemy_motion, "position", enemy_attack_start + Vector2(5, 0), 0.055)
	enemy_attack_tween.tween_property(enemy_motion, "position", enemy_attack_start + Vector2(-16, 0), 0.085)
	enemy_attack_tween.tween_interval(0.035)
	enemy_attack_tween.tween_property(enemy_motion, "position", enemy_attack_start, 0.13)

	await get_tree().create_timer(0.125).timeout

	var incoming_damage := int(current_enemy["enemy_damage"])
	player_hp = maxi(0, player_hp - incoming_damage)
	player_momentum = maxi(0, player_momentum - 4)
	player_rage = mini(100, player_rage + 3 + incoming_damage)
	_set_hero_state("hit")
	hero_art.modulate = Color(1.25, 0.68, 0.68, 1.0)
	_refresh_player_hud()

	await get_tree().create_timer(0.045).timeout

	var hero_hit_start := hero_motion.position
	var hero_hit_tween := create_tween()
	hero_hit_tween.tween_property(hero_motion, "position", hero_hit_start - Vector2(14, 1), 0.065)
	hero_hit_tween.tween_property(hero_motion, "position", hero_hit_start, 0.12)

	await get_tree().create_timer(0.16).timeout
	hero_art.modulate = Color.WHITE

	if player_hp <= 0:
		_show_defeat()
		busy = false
		return

	_set_hero_state("idle")
	_set_enemy_state("idle")
	hero_motion.position = hero_start
	enemy_motion.position = enemy_attack_start
	attack_hint.visible = false
	busy = false

func _handle_enemy_defeat() -> void:
	_set_enemy_state("defeat")
	_set_hero_state("victory" if encounter_index == RUN_SEQUENCE.size() - 1 else "idle")
	run_mode = "transition"
	attack_hint.visible = false

	_award_enemy_progression()
	await get_tree().create_timer(0.18).timeout

	var defeated_start := enemy_motion.position
	var defeat_tween := create_tween()
	defeat_tween.set_parallel(true)
	defeat_tween.tween_property(enemy_motion, "position", defeated_start + Vector2(0, 16), 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	defeat_tween.tween_property(enemy_motion, "modulate:a", 0.18, 0.36)
	await defeat_tween.finished

	var burst := _make_texture_rect()
	burst.texture = _load_v2_texture("v190/vfx/rewards/gold_burst.png")
	_anchor(burst, 0.55, 0.36, 0.95, 0.68)
	burst.z_index = 50
	burst.modulate.a = 0.0
	stage.add_child(burst)

	var reward_tween := create_tween()
	reward_tween.set_parallel(true)
	reward_tween.tween_property(burst, "modulate:a", 1.0, 0.12)
	reward_tween.tween_property(burst, "scale", Vector2(1.08, 1.08), 0.30)
	await reward_tween.finished

	await get_tree().create_timer(0.38).timeout
	burst.queue_free()

	if encounter_index == 2:
		_show_level_up()
		return

	if encounter_index == 4:
		_show_loot()
		return

	await get_tree().create_timer(0.45).timeout
	_set_hero_state("idle")
	_start_encounter(encounter_index + 1)


func _show_level_up() -> void:
	run_mode = "levelup"
	auto_enabled = false
	level_overlay.visible = true

	var beam := _make_texture_rect()
	beam.texture = _load_v2_texture("v190/vfx/progression_a/gold_level_beam.png")
	_anchor(beam, 0.28, 0.26, 0.72, 0.64)
	beam.z_index = 1
	beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_overlay.add_child(beam)

	var tween := create_tween()
	tween.set_parallel(true)
	beam.modulate.a = 0.0
	tween.tween_property(beam, "modulate:a", 0.85, 0.25)
	tween.tween_property(beam, "scale", Vector2(1.04, 1.04), 0.35)

	await get_tree().create_timer(0.65).timeout
	beam.queue_free()


func _continue_after_levelup() -> void:
	if run_mode != "levelup":
		return

	player_level = 43
	player_xp = maxi(0, player_xp - 100)
	hero_damage = 30
	player_hp = mini(100, player_hp + 25)
	player_level_label.text = "LV. %d" % player_level
	level_overlay.visible = false
	_set_hero_state("idle")
	_refresh_player_hud()
	_start_encounter(3)


func _show_loot() -> void:
	run_mode = "loot"
	auto_enabled = false
	loot_overlay.visible = true
	chest_art.texture = _load_v2_texture("v190/rewards/chest_states/closed.png")


func _open_loot() -> void:
	if run_mode != "loot":
		return

	run_mode = "loot_opening"
	chest_art.texture = _load_v2_texture("v190/rewards/chest_states/opening.png")
	await get_tree().create_timer(0.32).timeout

	chest_art.texture = _load_v2_texture("v190/rewards/chest_states/open_glow.png")

	var burst := _make_texture_rect()
	burst.texture = _load_v2_texture("v190/vfx/rewards/gold_burst.png")
	_anchor(burst, 0.31, 0.31, 0.69, 0.62)
	burst.z_index = 1
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loot_overlay.add_child(burst)

	await get_tree().create_timer(0.75).timeout
	loot_overlay.visible = false
	burst.queue_free()
	_show_victory()


func _show_victory() -> void:
	run_mode = "result"
	auto_enabled = false
	attack_hint.visible = false
	_set_hero_state("victory")
	result_title.text = "SIEG"
	result_detail.text = "5 / 5 abgeschlossen · Boss-Beute gesichert"
	result_title.add_theme_color_override("font_color", Color("#ffe69b"))
	restart_button.text = "NEUER RUN"
	restart_button.disabled = true
	result_overlay.visible = true
	await get_tree().create_timer(0.45).timeout
	restart_button.disabled = false


func _show_defeat() -> void:
	run_mode = "result"
	auto_enabled = false
	attack_hint.visible = false
	_set_hero_state("defeat")
	result_title.text = "NIEDERLAGE"
	result_detail.text = "Fortschritt: %d / %d" % [encounter_index + 1, RUN_SEQUENCE.size()]
	result_title.add_theme_color_override("font_color", Color("#ff8794"))
	restart_button.text = "NOCHMAL"
	restart_button.disabled = true
	result_overlay.visible = true
	await get_tree().create_timer(0.35).timeout
	restart_button.disabled = false


func _show_hit_fx() -> void:
	hit_fx.visible = true
	hit_fx.scale = Vector2(0.75, 0.75)
	hit_fx.modulate = Color.WHITE

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(hit_fx, "scale", Vector2.ONE, 0.16)
	tween.tween_property(hit_fx, "modulate:a", 0.0, 0.26)
	tween.finished.connect(func():
		if is_instance_valid(hit_fx):
			hit_fx.visible = false
			hit_fx.scale = Vector2.ONE
			hit_fx.modulate = Color.WHITE
	)


func _show_damage() -> void:
	var value: int = int(DISPLAY_DAMAGE[damage_index % DISPLAY_DAMAGE.size()])
	var critical: bool = damage_index % 4 == 2
	damage_index += 1

	damage_label.text = ("CRIT!\n" if critical else "") + _format_thousands(value)
	damage_label.add_theme_color_override("font_color", Color("#ff573d") if critical else Color("#ffd927"))
	damage_label.visible = true
	damage_label.modulate = Color.WHITE

	var start_y := damage_label.position.y
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(damage_label, "position:y", start_y - 32.0, 0.38)
	tween.tween_property(damage_label, "modulate:a", 0.0, 0.38)
	await tween.finished

	damage_label.position.y = start_y
	damage_label.visible = false


func _refresh_enemy_hud() -> void:
	enemy_name_label.text = str(current_enemy["name"])
	enemy_tier_label.text = str(current_enemy["tier"])
	enemy_level_label.text = "LV. %d" % int(current_enemy["level"])

	var tier := str(current_enemy["tier"])
	if tier == "BOSS":
		enemy_tier_label.add_theme_color_override("font_color", Color("#ff626e"))
	elif tier == "ELITE":
		enemy_tier_label.add_theme_color_override("font_color", Color("#c07aff"))
	else:
		enemy_tier_label.add_theme_color_override("font_color", Color("#b8d5e7"))

	enemy_hp_bar.min_value = 0
	enemy_hp_bar.max_value = enemy_hp_max
	enemy_hp_bar.value = enemy_hp

	var display_max := float(current_enemy["display_hp_k"])
	var display_current := display_max * (float(enemy_hp) / float(enemy_hp_max))
	enemy_hp_text.text = "%.1fK / %.1fK" % [display_current, display_max]

	progress_label.text = "%d / %d" % [encounter_index + 1, RUN_SEQUENCE.size()]


func _refresh_player_hud() -> void:
	player_hp_bar.value = player_hp
	var visible_hp := roundi(1420.0 * (float(player_hp) / 100.0))
	player_hp_text.text = "%s / 1.420" % _format_thousands(visible_hp)

	player_xp_bar.value = mini(player_xp, 100)
	player_xp_text.text = "%d%%" % mini(player_xp, 100)

	momentum_bar.value = player_momentum
	momentum_label.text = "MOMENTUM %d%%" % player_momentum

	rage_bar.value = player_rage
	rage_label.text = "ZORN %d%%" % player_rage



func _award_enemy_progression() -> void:
	var tier := str(current_enemy.get("tier", "NORMAL"))
	var xp_gain := 10
	var momentum_gain := 3
	var rage_gain := 2

	if tier == "ELITE":
		xp_gain = 14
		momentum_gain = 5
		rage_gain = 4
	elif tier == "BOSS":
		xp_gain = 20
		momentum_gain = 8
		rage_gain = 6

	player_xp += xp_gain
	player_momentum = mini(100, player_momentum + momentum_gain)
	player_rage = mini(100, player_rage + rage_gain)
	_refresh_player_hud()


func _layout_profile() -> Dictionary:
	return CombatLayout.profile(_last_landscape)


func _apply_master_layout() -> void:
	if stage == null:
		return

	var profile := _layout_profile()

	CombatLayout.apply_slot(world_pill, profile["world_pill"])
	CombatLayout.apply_slot(streak_panel, profile["streak"])
	CombatLayout.apply_slot(enemy_hud, profile["enemy_hud"])
	CombatLayout.apply_slot(hero_holder, profile["hero"])
	CombatLayout.apply_slot(hit_fx, profile["hit_fx"])
	CombatLayout.apply_slot(bottom_backing, profile["bottom_backing"])
	CombatLayout.apply_slot(vitals_row, profile["vitals"])
	CombatLayout.apply_slot(skills_row, profile["skills"])
	CombatLayout.apply_slot(attack_hint, profile["attack_hint"])

	if not current_enemy.is_empty():
		_apply_enemy_layout(str(current_enemy["layout"]))
	else:
		CombatLayout.apply_slot(enemy_holder, profile["normal"])

	call_deferred("_apply_enemy_art_layout")


func _apply_enemy_layout(layout: String) -> void:
	var profile := _layout_profile()
	var slot_key := "normal"

	if layout == "elite":
		slot_key = "elite"
	elif layout == "boss":
		slot_key = "boss"

	CombatLayout.apply_slot(enemy_holder, profile[slot_key])
	enemy_motion.position = Vector2.ZERO
	call_deferred("_apply_enemy_art_layout")


func _set_hero_state(state: String) -> void:
	var texture := _load_runtime_hero_texture(HERO_FILES.get(state, HERO_FILES["idle"]))
	# Body first, then state: the socket is resolved from the current body's texture space.
	hero_rig.set_body_texture(texture)
	hero_rig.set_state(state)


func _set_enemy_state(state: String) -> void:
	if current_enemy.is_empty():
		return

	var id := str(current_enemy["id"])
	var path := "monsters/greenvale/states/%s_%s.png" % [id, state]
	var texture := _load_game_texture(path)
	enemy_art.texture = texture
	_capture_enemy_texture_bounds(texture)
	_apply_enemy_art_layout()


func _capture_enemy_texture_bounds(texture: Texture2D) -> void:
	if texture == null:
		_enemy_texture_size = Vector2.ONE
		_enemy_used_rect = Rect2(Vector2.ZERO, Vector2.ONE)
		return

	_enemy_texture_size = texture.get_size()
	_enemy_used_rect = Rect2(Vector2.ZERO, _enemy_texture_size)

	var image: Image = texture.get_image()
	if image == null or image.get_width() <= 0 or image.get_height() <= 0:
		return

	var used_i: Rect2i = image.get_used_rect()
	if used_i.size.x <= 0 or used_i.size.y <= 0:
		return

	_enemy_used_rect = Rect2(Vector2(used_i.position), Vector2(used_i.size))


func _apply_enemy_art_layout() -> void:
	if enemy_art == null or enemy_motion == null:
		return
	if enemy_motion.size.x <= 1.0 or enemy_motion.size.y <= 1.0:
		return
	if _enemy_used_rect.size.x <= 0.0 or _enemy_used_rect.size.y <= 0.0:
		return

	var target_height := enemy_motion.size.y * 0.94
	var scale_factor := target_height / _enemy_used_rect.size.y
	var max_visible_width := enemy_motion.size.x * 1.16

	if _enemy_used_rect.size.x * scale_factor > max_visible_width:
		scale_factor = max_visible_width / _enemy_used_rect.size.x

	var render_size := _enemy_texture_size * scale_factor
	var used_center_x := (_enemy_used_rect.position.x + _enemy_used_rect.size.x * 0.5) * scale_factor
	var used_bottom := (_enemy_used_rect.position.y + _enemy_used_rect.size.y) * scale_factor

	enemy_art.size = render_size
	enemy_art.position = Vector2(
		enemy_motion.size.x * 0.5 - used_center_x,
		enemy_motion.size.y * 0.985 - used_bottom
	)


func _toggle_auto() -> void:
	auto_enabled = not auto_enabled
	auto_cooldown = 0.0

	if auto_button != null:
		var caption := auto_button.get_node_or_null("Caption") as Label
		if caption != null:
			caption.text = "AUTO ON" if auto_enabled else "AUTO"


func _toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _validate_required_assets() -> void:
	var required := [
		V2_GAME_ROOT + "world/greenvale/BG001_gruenhain_home_v11.png",
		V2_GAME_ROOT + "monsters/greenvale/states/M001_idle.png",
		V2_GAME_ROOT + "monsters/greenvale/states/M002_idle.png",
		V2_GAME_ROOT + "monsters/greenvale/states/M004_idle.png",
		V2_GAME_ROOT + "monsters/greenvale/states/M010_idle.png",
		V2_GAME_ROOT + "monsters/greenvale/states/B001_idle.png",
		V2_ROOT + "ui_v4/upgrade_evolution_a/level_up.png",
		V2_ROOT + "v190/rewards/chest_states/closed.png",
		COMBAT_ROOT + str(STARTER_WEAPON["texture"]),
		RUNTIME_HERO_ROOT + HERO_FILES["idle"],
		RUNTIME_HERO_ROOT + HERO_FILES["hit"],
		RUNTIME_HERO_ROOT + HERO_FILES["defeat"],
	]

	for path in required:
		if not ResourceLoader.exists(path):
			push_error("Missing Grünhain vertical-slice asset: " + path)


func _validate_layout_contract() -> void:
	for landscape in [false, true]:
		var profile := CombatLayout.profile(landscape)
		var ground_line := float(profile["ground_line"])

		for slot_name in ["hero", "normal", "elite", "boss"]:
			var rect: Rect2 = profile[slot_name]
			var bottom := rect.position.y + rect.size.y

			if abs(bottom - ground_line) > 0.035:
				push_error("COMBAT LAYOUT ERROR: %s bottom %.3f differs from ground line %.3f" % [slot_name, bottom, ground_line])


func _load_runtime_hero_texture(relative_path: String) -> Texture2D:
	var path := RUNTIME_HERO_ROOT + relative_path
	if not ResourceLoader.exists(path):
		push_error("Missing runtime hero asset: " + path)
		return null
	return load(path) as Texture2D


func _load_combat_texture(relative_path: String) -> Texture2D:
	var path := COMBAT_ROOT + relative_path
	if not ResourceLoader.exists(path):
		push_error("Missing combat asset: " + path)
		return null
	return load(path) as Texture2D


func _load_v2_texture(relative_path: String) -> Texture2D:
	var path := V2_ROOT + relative_path
	if not ResourceLoader.exists(path):
		push_error("Missing V2 asset: " + path)
		return null
	return load(path) as Texture2D


func _load_game_texture(relative_path: String) -> Texture2D:
	var path := V2_GAME_ROOT + relative_path
	if not ResourceLoader.exists(path):
		push_error("Missing V2 game asset: " + path)
		return null
	return load(path) as Texture2D


func _make_texture_rect() -> TextureRect:
	var rect := TextureRect.new()
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


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
