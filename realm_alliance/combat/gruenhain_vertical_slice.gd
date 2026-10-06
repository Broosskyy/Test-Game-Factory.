extends Control

const PORTRAIT_REFERENCE := Vector2i(720, 1280)
const LANDSCAPE_REFERENCE := Vector2i(960, 540)

const COMBAT_ROOT := "res://assets/realm_alliance/production/"
const V2_ROOT := "res://assets/realm_alliance/v2/"
const V2_GAME_ROOT := "res://assets/realm_alliance/v2_game/"

const HERO_FILES := {
	"idle": "hero/realmwaechter/idle.png",
	"attack": "hero/realmwaechter/attack.png",
	"skill": "hero/realmwaechter/skill.png",
	"hit": "hero/realmwaechter/hit.png",
	"victory": "hero/realmwaechter/victory.png",
	"defeat": "hero/realmwaechter/defeated.png",
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

var _last_landscape := false
var _profile_initialized := false
var _applying_profile := false

var stage: Control
var hero_holder: Control
var enemy_holder: Control
var hero_art: TextureRect
var enemy_art: TextureRect
var hit_fx: TextureRect

var enemy_name_label: Label
var enemy_tier_label: Label
var enemy_level_label: Label
var enemy_hp_bar: ProgressBar
var enemy_hp_text: Label
var progress_label: Label

var player_hp_bar: ProgressBar
var player_hp_text: Label
var player_level_label: Label
var damage_label: Label

var attack_hint: Label
var auto_button: Button

var level_overlay: ColorRect
var loot_overlay: ColorRect
var result_overlay: ColorRect
var result_title: Label
var chest_art: TextureRect


func _ready() -> void:
	_apply_orientation_profile()

	if not get_window().size_changed.is_connected(_on_window_size_changed):
		get_window().size_changed.connect(_on_window_size_changed)

	_build_interface()
	_validate_required_assets()
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
	avatar.texture = _load_combat_texture(HERO_FILES["idle"])
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
		icon.custom_minimum_size = Vector2(27, 27)
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
	_anchor(settings, 0.89, 0.18, 0.955, 0.82)
	header.add_child(settings)

	if OS.get_name() == "Web":
		var fullscreen := Button.new()
		fullscreen.text = "FULL"
		fullscreen.focus_mode = Control.FOCUS_NONE
		fullscreen.add_theme_font_size_override("font_size", 11)
		fullscreen.add_theme_stylebox_override("normal", _panel_style(Color("#0b1a2b"), Color("#31587a"), 12))
		_anchor(fullscreen, 0.958, 0.18, 0.992, 0.82)
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

	var world_pill := PanelContainer.new()
	_anchor(world_pill, 0.22, 0.018, 0.78, 0.082)
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

	var streak := PanelContainer.new()
	_anchor(streak, 0.018, 0.105, 0.25, 0.185)
	streak.z_index = 31
	streak.add_theme_stylebox_override("panel", _panel_style(Color(0.05, 0.08, 0.10, 0.90), Color("#80602c"), 12))
	stage.add_child(streak)

	var streak_text := Label.new()
	streak_text.text = "12ER SIEGESSERIE\n+24% GOLD  +18% XP"
	streak_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	streak_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	streak_text.add_theme_color_override("font_color", Color("#ffe39d"))
	streak_text.add_theme_font_size_override("font_size", 12)
	streak.add_child(streak_text)

	hero_holder = Control.new()
	_anchor(hero_holder, -0.005, 0.45, 0.39, 0.80)
	hero_holder.z_index = 10
	hero_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(hero_holder)

	hero_art = _make_texture_rect()
	_anchor(hero_art, 0.0, 0.0, 1.0, 1.0)
	hero_holder.add_child(hero_art)

	enemy_holder = Control.new()
	enemy_holder.z_index = 9
	enemy_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(enemy_holder)

	enemy_art = _make_texture_rect()
	_anchor(enemy_art, 0.0, 0.0, 1.0, 1.0)
	enemy_holder.add_child(enemy_art)

	hit_fx = _make_texture_rect()
	hit_fx.texture = _load_v2_texture("v190/vfx/combat_impacts/nature_impact.png")
	_anchor(hit_fx, 0.56, 0.39, 0.97, 0.70)
	hit_fx.z_index = 16
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
	_anchor(attack_hint, 0.31, 0.675, 0.69, 0.715)
	attack_hint.z_index = 32
	attack_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(attack_hint)


func _build_enemy_hud() -> void:
	var hud := PanelContainer.new()
	_anchor(hud, 0.285, 0.092, 0.715, 0.215)
	hud.z_index = 40
	hud.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.065, 0.105, 0.96), Color("#4c7694"), 15))
	stage.add_child(hud)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	hud.add_child(box)

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
	damage_label.add_theme_font_size_override("font_size", 68)
	_anchor(damage_label, 0.68, 0.305, 0.985, 0.49)
	damage_label.rotation = deg_to_rad(-5.0)
	damage_label.z_index = 47
	damage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(damage_label)


func _build_combat_bottom_hud() -> void:
	var bottom := ColorRect.new()
	_anchor(bottom, 0.0, 0.715, 1.0, 1.0)
	bottom.color = Color(0.015, 0.04, 0.065, 0.78)
	bottom.z_index = 24
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(bottom)

	var vitals := HBoxContainer.new()
	_anchor(vitals, 0.025, 0.725, 0.865, 0.795)
	vitals.add_theme_constant_override("separation", 8)
	vitals.z_index = 28
	stage.add_child(vitals)

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

	vitals.add_child(hp_card)

	for stat in [["MOMENTUM", "68%", "#a34cff"], ["ZORN", "42%", "#ff8b23"]]:
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", _panel_style(Color("#091722"), Color(stat[2]), 12))

		var box := VBoxContainer.new()
		card.add_child(box)

		var label := Label.new()
		label.text = "%s %s" % [stat[0], stat[1]]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color(stat[2]))
		label.add_theme_font_size_override("font_size", 11)
		box.add_child(label)

		var bar := ProgressBar.new()
		bar.min_value = 0
		bar.max_value = 100
		bar.value = 68 if stat[0] == "MOMENTUM" else 42
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 18)
		bar.add_theme_stylebox_override("background", _panel_style(Color("#04070c"), Color("#222d38"), 8))
		bar.add_theme_stylebox_override("fill", _panel_style(Color(stat[2]), Color(stat[2]).lightened(0.2), 8))
		box.add_child(bar)

		vitals.add_child(card)

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

	var skills := HBoxContainer.new()
	_anchor(skills, 0.035, 0.812, 0.965, 0.965)
	skills.alignment = BoxContainer.ALIGNMENT_CENTER
	skills.add_theme_constant_override("separation", 16)
	skills.z_index = 31
	stage.add_child(skills)

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
		skills.add_child(button)
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
	level_overlay.color = Color(0.01, 0.025, 0.035, 0.84)
	level_overlay.z_index = 200
	level_overlay.visible = false
	add_child(level_overlay)

	var card := PanelContainer.new()
	_anchor(card, 0.16, 0.27, 0.84, 0.68)
	card.add_theme_stylebox_override("panel", _panel_style(Color("#0b1725"), Color("#d7a832"), 24))
	level_overlay.add_child(card)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 12)
	card.add_child(content)

	var art := TextureRect.new()
	art.texture = _load_v2_texture("ui_v4/upgrade_evolution_a/level_up.png")
	art.custom_minimum_size = Vector2(180, 150)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content.add_child(art)

	var title := Label.new()
	title.text = "LEVEL 43"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#ffe69b"))
	title.add_theme_font_size_override("font_size", 36)
	content.add_child(title)

	var stats := Label.new()
	stats.text = "+5 ANGRIFF\n+6 LEBEN\n+2 GOLDFUND"
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_color_override("font_color", Color("#eef5ff"))
	stats.add_theme_font_size_override("font_size", 17)
	content.add_child(stats)

	var continue_button := Button.new()
	continue_button.text = "WEITER"
	continue_button.custom_minimum_size = Vector2(220, 56)
	continue_button.focus_mode = Control.FOCUS_NONE
	continue_button.add_theme_font_size_override("font_size", 17)
	continue_button.add_theme_stylebox_override("normal", _panel_style(Color("#234e2f"), Color("#64da82"), 14))
	continue_button.pressed.connect(_continue_after_levelup)
	content.add_child(continue_button)


func _build_loot_overlay() -> void:
	loot_overlay = ColorRect.new()
	_anchor(loot_overlay, 0.0, 0.0, 1.0, 1.0)
	loot_overlay.color = Color(0.01, 0.025, 0.035, 0.86)
	loot_overlay.z_index = 210
	loot_overlay.visible = false
	add_child(loot_overlay)

	var card := PanelContainer.new()
	_anchor(card, 0.15, 0.25, 0.85, 0.72)
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
	title.add_theme_font_size_override("font_size", 28)
	content.add_child(title)

	chest_art = TextureRect.new()
	chest_art.texture = _load_v2_texture("v190/rewards/chest_states/closed.png")
	chest_art.custom_minimum_size = Vector2(260, 210)
	chest_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chest_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	content.add_child(chest_art)

	var reward := Label.new()
	reward.text = "GARANTIERTE BOSS-TRUHE"
	reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward.add_theme_color_override("font_color", Color("#dce9f5"))
	reward.add_theme_font_size_override("font_size", 15)
	content.add_child(reward)

	var open_button := Button.new()
	open_button.text = "TRUHE ÖFFNEN"
	open_button.custom_minimum_size = Vector2(240, 58)
	open_button.focus_mode = Control.FOCUS_NONE
	open_button.add_theme_font_size_override("font_size", 17)
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

	var restart := Button.new()
	restart.text = "NEUSTART"
	restart.custom_minimum_size = Vector2(230, 58)
	restart.focus_mode = Control.FOCUS_NONE
	restart.add_theme_font_size_override("font_size", 17)
	restart.add_theme_stylebox_override("normal", _panel_style(Color("#17324b"), Color("#66b5e7"), 14))
	restart.pressed.connect(_start_run)
	content.add_child(restart)


func _start_run() -> void:
	player_hp = 100
	player_level = 42
	hero_damage = 25
	encounter_index = 0
	damage_index = 0
	auto_enabled = false
	auto_cooldown = 0.0
	busy = false
	run_mode = "combat"

	level_overlay.visible = false
	loot_overlay.visible = false
	result_overlay.visible = false

	hero_art.modulate = Color.WHITE
	hero_holder.position = Vector2.ZERO
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

	enemy_holder.modulate = Color(1, 1, 1, 0)
	var spawn_tween := create_tween()
	spawn_tween.tween_property(enemy_holder, "modulate:a", 1.0, 0.28)

	attack_hint.visible = true
	_refresh_enemy_hud()


func _attack() -> void:
	if run_mode != "combat" or busy:
		return

	busy = true
	attack_hint.visible = false

	_set_hero_state("attack")

	var hero_start := hero_holder.position
	var hero_tween := create_tween()
	hero_tween.tween_property(hero_holder, "position", hero_start + Vector2(20, -3), 0.10)
	hero_tween.tween_property(hero_holder, "position", hero_start, 0.13)

	await get_tree().create_timer(0.11).timeout

	enemy_hp = maxi(0, enemy_hp - hero_damage)
	_set_enemy_state("hit")
	_show_hit_fx()
	_show_damage()
	_refresh_enemy_hud()

	var enemy_start := enemy_holder.position
	var recoil := create_tween()
	recoil.tween_property(enemy_holder, "position", enemy_start + Vector2(12, 0), 0.06)
	recoil.tween_property(enemy_holder, "position", enemy_start, 0.11)

	await get_tree().create_timer(0.22).timeout

	if enemy_hp <= 0:
		await _handle_enemy_defeat()
		busy = false
		return

	_set_hero_state("idle")
	_set_enemy_state("attack")

	await get_tree().create_timer(0.18).timeout

	player_hp = maxi(0, player_hp - int(current_enemy["enemy_damage"]))
	_set_hero_state("hit")
	hero_art.modulate = Color(1.2, 0.72, 0.72, 1.0)
	_refresh_player_hud()

	await get_tree().create_timer(0.13).timeout
	hero_art.modulate = Color.WHITE

	if player_hp <= 0:
		_show_defeat()
		busy = false
		return

	_set_hero_state("idle")
	_set_enemy_state("idle")
	attack_hint.visible = true
	busy = false


func _handle_enemy_defeat() -> void:
	_set_enemy_state("defeat")
	_set_hero_state("victory")
	run_mode = "transition"
	attack_hint.visible = false

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

	await get_tree().create_timer(0.55).timeout
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
	_anchor(beam, 0.18, 0.18, 0.82, 0.80)
	beam.z_index = 201
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
	_anchor(burst, 0.24, 0.23, 0.76, 0.70)
	burst.z_index = 212
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	loot_overlay.add_child(burst)

	await get_tree().create_timer(0.75).timeout
	loot_overlay.visible = false
	burst.queue_free()
	_show_victory()


func _show_victory() -> void:
	run_mode = "result"
	_set_hero_state("victory")
	result_title.text = "SIEG"
	result_title.add_theme_color_override("font_color", Color("#ffe69b"))
	result_overlay.visible = true


func _show_defeat() -> void:
	run_mode = "result"
	auto_enabled = false
	attack_hint.visible = false
	_set_hero_state("defeat")
	result_title.text = "NIEDERLAGE"
	result_title.add_theme_color_override("font_color", Color("#ff8794"))
	result_overlay.visible = true


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


func _apply_enemy_layout(layout: String) -> void:
	match layout:
		"boss":
			_anchor(enemy_holder, 0.36, 0.235, 1.025, 0.805)
		"elite":
			_anchor(enemy_holder, 0.44, 0.275, 1.005, 0.805)
		_:
			_anchor(enemy_holder, 0.50, 0.315, 0.985, 0.805)


func _set_hero_state(state: String) -> void:
	hero_art.texture = _load_combat_texture(HERO_FILES.get(state, HERO_FILES["idle"]))


func _set_enemy_state(state: String) -> void:
	if current_enemy.is_empty():
		return

	var id := str(current_enemy["id"])
	var path := "monsters/greenvale/states/%s_%s.png" % [id, state]
	enemy_art.texture = _load_game_texture(path)


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
	]

	for path in required:
		if not ResourceLoader.exists(path):
			push_error("Missing Grünhain vertical-slice asset: " + path)


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
