extends Control

const PORTRAIT_REFERENCE := Vector2i(720, 1280)
const LANDSCAPE_REFERENCE := Vector2i(960, 540)
const ASSET_ROOT := "res://assets/realm_alliance/production/"

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
var enemy_hp := 28
var enemy_hp_max := 28
var busy := false
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
	var topbar := PanelContainer.new()
	_anchor(topbar, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 60.0)
	topbar.add_theme_stylebox_override("panel", _panel_style(Color("#081827"), Color("#24455e"), 0))
	add_child(topbar)

	var player_chip := PanelContainer.new()
	_anchor(player_chip, 0.012, 0.12, 0.31, 0.88)
	player_chip.add_theme_stylebox_override("panel", _panel_style(Color("#0b1b2c"), Color("#315a78"), 13))
	topbar.add_child(player_chip)

	var player_label := Label.new()
	player_label.text = "REALMWÄCHTER   LV. 1"
	player_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	player_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_label.add_theme_color_override("font_color", Color("#e8f2ff"))
	player_label.add_theme_font_size_override("font_size", 17)
	player_chip.add_child(player_label)

	var resources := HBoxContainer.new()
	_anchor(resources, 0.33, 0.18, 0.82, 0.84)
	resources.alignment = BoxContainer.ALIGNMENT_CENTER
	resources.add_theme_constant_override("separation", 6)
	topbar.add_child(resources)

	for entry in [["GOLD", "0"], ["ESSENZ", "0"], ["STAUB", "0"]]:
		var resource := PanelContainer.new()
		resource.custom_minimum_size = Vector2(102, 38)
		resource.add_theme_stylebox_override("panel", _panel_style(Color("#0a1724"), Color("#26425a"), 10))
		var text := Label.new()
		text.text = "%s  %s" % [entry[0], entry[1]]
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		text.add_theme_color_override("font_color", Color("#b9c9dc"))
		text.add_theme_font_size_override("font_size", 13)
		resource.add_child(text)
		resources.add_child(resource)

	fullscreen_button = Button.new()
	fullscreen_button.text = "FULL"
	fullscreen_button.visible = OS.get_name() == "Web"
	fullscreen_button.focus_mode = Control.FOCUS_NONE
	fullscreen_button.add_theme_font_size_override("font_size", 12)
	fullscreen_button.add_theme_stylebox_override("normal", _panel_style(Color("#102234"), Color("#3976a3"), 10))
	fullscreen_button.add_theme_stylebox_override("pressed", _panel_style(Color("#17344e"), Color("#65b7ed"), 10))
	_anchor(fullscreen_button, 0.87, 0.18, 0.985, 0.84)
	fullscreen_button.pressed.connect(_toggle_fullscreen)
	topbar.add_child(fullscreen_button)


func _build_stage() -> void:
	stage = Control.new()
	_anchor(stage, 0.0, 0.0, 1.0, 1.0, 0.0, 60.0, 0.0, -68.0)
	stage.clip_contents = true
	add_child(stage)

	var sky := ColorRect.new()
	_anchor(sky, 0.0, 0.0, 1.0, 0.7)
	sky.color = Color("#86cceb")
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(sky)

	var horizon := ColorRect.new()
	_anchor(horizon, 0.0, 0.62, 1.0, 1.0)
	horizon.color = Color("#b9d5bf")
	horizon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(horizon)

	var shade := ColorRect.new()
	_anchor(shade, 0.0, 0.0, 1.0, 1.0)
	shade.color = Color(0.02, 0.06, 0.09, 0.07)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.z_index = 6
	stage.add_child(shade)

	_add_world_texture("Castle", -0.10, 0.11, 0.44, 0.45, 1)
	_add_world_texture("Float", 0.57, 0.09, 1.12, 0.44, 1)
	_add_world_texture("Ruin", 0.65, 0.29, 1.05, 0.60, 2)
	_add_world_texture("Ruins", 0.10, 0.43, 0.90, 0.73, 2)
	_add_world_texture("Platform", -0.15, 0.56, 1.15, 0.95, 3)
	_add_world_texture("Foreground", -0.09, 0.72, 1.09, 1.05, 7)

	hero_holder = Control.new()
	hero_holder.name = "HeroHolder"
	_anchor(hero_holder, 0.04, 0.525, 0.29, 0.815)
	hero_holder.z_index = 8
	hero_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(hero_holder)

	hero_art = _make_texture_rect()
	_anchor(hero_art, 0.0, 0.0, 1.0, 1.0)
	hero_holder.add_child(hero_art)

	enemy_holder = Control.new()
	enemy_holder.name = "EnemyHolder"
	_anchor(enemy_holder, 0.53, 0.355, 0.98, 0.825)
	enemy_holder.z_index = 8
	enemy_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(enemy_holder)

	enemy_art = _make_texture_rect()
	_anchor(enemy_art, 0.0, 0.0, 1.0, 1.0)
	enemy_holder.add_child(enemy_art)

	_add_shadow(hero_holder, 0.17, 0.91, 0.83, 0.98)
	_add_shadow(enemy_holder, 0.12, 0.91, 0.88, 0.98)

	_build_enemy_hud()
	_build_damage_number()
	_build_combat_bottom_hud()

	var tap_zone := Button.new()
	tap_zone.text = ""
	tap_zone.flat = true
	tap_zone.focus_mode = Control.FOCUS_NONE
	tap_zone.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_anchor(tap_zone, 0.0, 0.13, 1.0, 0.83)
	tap_zone.z_index = 12
	tap_zone.pressed.connect(_attack)
	stage.add_child(tap_zone)

	attack_hint = Label.new()
	attack_hint.text = "TIPPEN ZUM ANGREIFEN"
	attack_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	attack_hint.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 0.72))
	attack_hint.add_theme_font_size_override("font_size", 16)
	_anchor(attack_hint, 0.27, 0.79, 0.73, 0.83)
	attack_hint.z_index = 30
	attack_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(attack_hint)

	_build_result_overlay()


func _build_enemy_hud() -> void:
	var hud := PanelContainer.new()
	_anchor(hud, 0.31, 0.045, 0.69, 0.135)
	hud.z_index = 40
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_theme_stylebox_override("panel", _panel_style(Color(0.03, 0.07, 0.11, 0.94), Color("#4a7896"), 13))
	stage.add_child(hud)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	hud.add_child(box)

	var title := HBoxContainer.new()
	title.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(title)

	var rank := Label.new()
	rank.text = "1"
	rank.custom_minimum_size = Vector2(28, 28)
	rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rank.add_theme_color_override("font_color", Color.WHITE)
	rank.add_theme_font_size_override("font_size", 16)
	title.add_child(rank)

	var name := Label.new()
	name.text = "WOLKENFLINK"
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.add_theme_color_override("font_color", Color.WHITE)
	name.add_theme_font_size_override("font_size", 18)
	title.add_child(name)

	var level := Label.new()
	level.text = "LV. 1"
	level.add_theme_color_override("font_color", Color("#dce8f5"))
	level.add_theme_font_size_override("font_size", 12)
	title.add_child(level)

	var bar_wrap := Control.new()
	bar_wrap.custom_minimum_size = Vector2(0, 20)
	box.add_child(bar_wrap)

	enemy_hp_bar = ProgressBar.new()
	enemy_hp_bar.min_value = 0
	enemy_hp_bar.max_value = enemy_hp_max
	enemy_hp_bar.value = enemy_hp
	enemy_hp_bar.show_percentage = false
	_anchor(enemy_hp_bar, 0.0, 0.15, 1.0, 0.85)
	enemy_hp_bar.add_theme_stylebox_override("background", _panel_style(Color("#02060a"), Color("#18222b"), 8))
	enemy_hp_bar.add_theme_stylebox_override("fill", _panel_style(Color("#ff4056"), Color("#ff6d7d"), 8))
	bar_wrap.add_child(enemy_hp_bar)

	enemy_hp_text = Label.new()
	enemy_hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_hp_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	enemy_hp_text.add_theme_color_override("font_color", Color.WHITE)
	enemy_hp_text.add_theme_font_size_override("font_size", 11)
	_anchor(enemy_hp_text, 0.0, 0.0, 1.0, 1.0)
	bar_wrap.add_child(enemy_hp_text)


func _build_damage_number() -> void:
	damage_label = Label.new()
	damage_label.text = ""
	damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	damage_label.add_theme_color_override("font_color", Color("#fff2a8"))
	damage_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	damage_label.add_theme_constant_override("shadow_offset_x", 3)
	damage_label.add_theme_constant_override("shadow_offset_y", 3)
	damage_label.add_theme_font_size_override("font_size", 58)
	_anchor(damage_label, 0.64, 0.31, 0.94, 0.41)
	damage_label.z_index = 45
	damage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_label.visible = false
	stage.add_child(damage_label)


func _build_combat_bottom_hud() -> void:
	var bottom := ColorRect.new()
	_anchor(bottom, 0.0, 0.835, 1.0, 1.0)
	bottom.color = Color(0.015, 0.045, 0.075, 0.88)
	bottom.z_index = 24
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(bottom)

	var vitals := HBoxContainer.new()
	_anchor(vitals, 0.03, 0.845, 0.97, 0.895)
	vitals.add_theme_constant_override("separation", 8)
	vitals.z_index = 26
	stage.add_child(vitals)

	var hp_card := VBoxContainer.new()
	hp_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vitals.add_child(hp_card)

	var hp_title := Label.new()
	hp_title.text = "HP"
	hp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_title.add_theme_color_override("font_color", Color("#dbe8f5"))
	hp_title.add_theme_font_size_override("font_size", 12)
	hp_card.add_child(hp_title)

	var hp_wrap := Control.new()
	hp_wrap.custom_minimum_size = Vector2(0, 22)
	hp_card.add_child(hp_wrap)

	player_hp_bar = ProgressBar.new()
	player_hp_bar.min_value = 0
	player_hp_bar.max_value = 100
	player_hp_bar.value = player_hp
	player_hp_bar.show_percentage = false
	_anchor(player_hp_bar, 0.0, 0.2, 1.0, 0.85)
	player_hp_bar.add_theme_stylebox_override("background", _panel_style(Color("#020609"), Color("#173225"), 8))
	player_hp_bar.add_theme_stylebox_override("fill", _panel_style(Color("#38cf74"), Color("#5ef09a"), 8))
	hp_wrap.add_child(player_hp_bar)

	player_hp_text = Label.new()
	player_hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_hp_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	player_hp_text.add_theme_color_override("font_color", Color.WHITE)
	player_hp_text.add_theme_font_size_override("font_size", 10)
	_anchor(player_hp_text, 0.0, 0.0, 1.0, 1.0)
	hp_wrap.add_child(player_hp_text)

	for stat in [["MOMENTUM", "0"], ["ZORN", "0"]]:
		var card := VBoxContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var t := Label.new()
		t.text = stat[0]
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t.add_theme_color_override("font_color", Color("#aebcd0"))
		t.add_theme_font_size_override("font_size", 11)
		var v := Label.new()
		v.text = stat[1]
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_theme_color_override("font_color", Color.WHITE)
		v.add_theme_font_size_override("font_size", 17)
		card.add_child(t)
		card.add_child(v)
		vitals.add_child(card)

	var skills := HBoxContainer.new()
	_anchor(skills, 0.08, 0.905, 0.92, 0.992)
	skills.alignment = BoxContainer.ALIGNMENT_CENTER
	skills.add_theme_constant_override("separation", 14)
	skills.z_index = 31
	stage.add_child(skills)

	for data in [["ANGRIFF", false], ["RISSHIEB", true], ["NOVA", true], ["ZORN", true]]:
		var button := Button.new()
		button.text = data[0]
		button.custom_minimum_size = Vector2(116, 76)
		button.focus_mode = Control.FOCUS_NONE
		button.disabled = bool(data[1])
		button.add_theme_font_size_override("font_size", 13)
		button.add_theme_color_override("font_color", Color("#f2f7ff"))
		button.add_theme_color_override("font_disabled_color", Color("#7b8794"))
		button.add_theme_stylebox_override("normal", _panel_style(Color("#102438"), Color("#4387b8"), 34))
		button.add_theme_stylebox_override("pressed", _panel_style(Color("#183b58"), Color("#78c9ff"), 34))
		button.add_theme_stylebox_override("disabled", _panel_style(Color("#10161d"), Color("#38424c"), 34))
		if data[0] == "ANGRIFF":
			button.pressed.connect(_attack)
		skills.add_child(button)


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
	subtitle.text = "Vertical Slice Port 01"
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
	_anchor(nav, 0.0, 1.0, 1.0, 1.0, 0.0, -68.0, 0.0, 0.0)
	nav.add_theme_stylebox_override("panel", _panel_style(Color("#06101a"), Color("#22475f"), 0))
	add_child(nav)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_child(row)

	for label_text in ["KAMPF", "ABENTEUER", "WESEN", "BEUTE", "MEHR"]:
		var label := Label.new()
		label.text = label_text
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color("#e8d7ff") if label_text == "KAMPF" else Color("#7e91a7"))
		row.add_child(label)


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

	var damage := 7
	enemy_hp = maxi(0, enemy_hp - damage)
	_set_enemy_state("hit")
	_show_damage(damage)
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

	player_hp = maxi(0, player_hp - 5)
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
	damage_label.position.y += 8.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(damage_label, "position:y", damage_label.position.y - 32.0, 0.38)
	tween.tween_property(damage_label, "modulate:a", 0.0, 0.38)
	await tween.finished
	damage_label.visible = false


func _refresh_hud() -> void:
	if enemy_hp_bar != null:
		enemy_hp_bar.value = enemy_hp
	if enemy_hp_text != null:
		enemy_hp_text.text = "%d / %d" % [enemy_hp, enemy_hp_max]
	if player_hp_bar != null:
		player_hp_bar.value = player_hp
	if player_hp_text != null:
		player_hp_text.text = "%d / 100" % player_hp


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
	_set_hero_state("idle")
	_set_enemy_state("idle")
	_refresh_hud()


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
