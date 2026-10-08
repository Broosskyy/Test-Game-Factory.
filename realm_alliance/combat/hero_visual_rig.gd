extends Control
class_name HeroVisualRig

# Visual composition only. Gameplay items/stats live outside this rig.
# Body and equipment remain separate, but alpha-bound normalization keeps them
# visually locked together across differently cropped source images.

const WEAPON_SOCKETS := {
	# hand_uv is measured in the HeroBody texture, not in the outer combat slot.
	# This keeps the sword attached to the same hand in portrait and landscape.
	"idle": {
		"hand_uv": Vector2(0.742, 0.565),
		"rotation_deg": 90.0,
		"length_ratio": 0.55,
		"draw_front": false,
	},
	"attack": {
		"hand_uv": Vector2(0.742, 0.565),
		"rotation_deg": 30.0,
		"length_ratio": 0.62,
		"draw_front": true,
	},
	"skill": {
		"hand_uv": Vector2(0.742, 0.565),
		"rotation_deg": -15.0,
		"length_ratio": 0.66,
		"draw_front": true,
	},
	"hit": {
		"hand_uv": Vector2(0.742, 0.565),
		"rotation_deg": 105.0,
		"length_ratio": 0.54,
		"draw_front": false,
	},
	"victory": {
		"hand_uv": Vector2(0.742, 0.565),
		"rotation_deg": -15.0,
		"length_ratio": 0.62,
		"draw_front": true,
	},
	"defeat": {
		"hand_uv": Vector2(0.742, 0.565),
		"rotation_deg": 155.0,
		"length_ratio": 0.46,
		"draw_front": false,
	},
}

var aura_back_art: TextureRect
var back_socket: Control
var wings_art: TextureRect
var body_art: TextureRect
var outfit_art: TextureRect
var weapon_socket: Control
var weapon_art: TextureRect
var head_socket: Control
var headgear_art: TextureRect
var aura_front_art: TextureRect

var _state := "idle"
var _weapon_grip_uv := Vector2(0.50, 0.92)
var _weapon_base_rotation_deg := 0.0

var _body_texture_size := Vector2.ONE
var _body_used_rect := Rect2(Vector2.ZERO, Vector2.ONE)
var _body_scale := 1.0
var _body_draw_position := Vector2.ZERO
var _weapon_texture_size := Vector2.ONE
var _weapon_used_rect := Rect2(Vector2.ZERO, Vector2.ONE)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_layers()


func _ready() -> void:
	if not resized.is_connected(_apply_layout):
		resized.connect(_apply_layout)
	_apply_layout()


func _build_layers() -> void:
	aura_back_art = _make_fill_layer("AuraBack", -4)
	add_child(aura_back_art)

	back_socket = Control.new()
	back_socket.name = "BackSocket"
	back_socket.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill(back_socket)
	back_socket.z_index = -3
	add_child(back_socket)

	wings_art = _make_fill_layer("Wings", 0)
	back_socket.add_child(wings_art)

	body_art = TextureRect.new()
	body_art.name = "Body"
	body_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	body_art.stretch_mode = TextureRect.STRETCH_SCALE
	body_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_art.z_index = 0
	add_child(body_art)

	outfit_art = _make_fill_layer("Outfit", 1)
	add_child(outfit_art)

	weapon_socket = Control.new()
	weapon_socket.name = "WeaponSocket"
	weapon_socket.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weapon_socket.z_index = 3
	add_child(weapon_socket)

	weapon_art = TextureRect.new()
	weapon_art.name = "Weapon"
	weapon_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	weapon_art.stretch_mode = TextureRect.STRETCH_SCALE
	weapon_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weapon_socket.add_child(weapon_art)

	head_socket = Control.new()
	head_socket.name = "HeadSocket"
	head_socket.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill(head_socket)
	head_socket.z_index = 4
	add_child(head_socket)

	headgear_art = _make_fill_layer("Headgear", 0)
	head_socket.add_child(headgear_art)

	aura_front_art = _make_fill_layer("AuraFront", 5)
	add_child(aura_front_art)


func set_body_texture(texture: Texture2D) -> void:
	body_art.texture = texture
	var geometry := _texture_geometry(texture)
	_body_texture_size = geometry["size"]
	_body_used_rect = geometry["used"]
	_apply_body_layout()


func set_weapon(texture: Texture2D, grip_uv: Vector2, base_rotation_deg: float = 0.0) -> void:
	weapon_art.texture = texture
	_weapon_grip_uv = grip_uv
	_weapon_base_rotation_deg = base_rotation_deg

	var geometry := _texture_geometry(texture)
	_weapon_texture_size = geometry["size"]
	_weapon_used_rect = geometry["used"]

	weapon_art.visible = texture != null
	_apply_weapon_layout()


func set_state(state: String) -> void:
	_state = state if WEAPON_SOCKETS.has(state) else "idle"
	_apply_layout()


func set_outfit(texture: Texture2D) -> void:
	outfit_art.texture = texture
	outfit_art.visible = texture != null


func set_headgear(texture: Texture2D) -> void:
	headgear_art.texture = texture
	headgear_art.visible = texture != null


func set_wings(texture: Texture2D) -> void:
	wings_art.texture = texture
	wings_art.visible = texture != null


func set_aura(back_texture: Texture2D, front_texture: Texture2D = null) -> void:
	aura_back_art.texture = back_texture
	aura_front_art.texture = front_texture
	aura_back_art.visible = back_texture != null
	aura_front_art.visible = front_texture != null


func clear_cosmetics() -> void:
	set_outfit(null)
	set_headgear(null)
	set_wings(null)
	set_aura(null, null)


func _apply_layout() -> void:
	_apply_body_layout()
	_apply_weapon_layout()


func _apply_body_layout() -> void:
	if body_art == null:
		return
	if size.x <= 1.0 or size.y <= 1.0:
		return
	if _body_used_rect.size.x <= 0.0 or _body_used_rect.size.y <= 0.0:
		return

	var target_height := size.y * 0.96
	var max_visible_width := size.x * 1.58

	if _state == "defeat":
		target_height = size.y * 0.58
		max_visible_width = size.x * 1.82

	var scale_factor := target_height / _body_used_rect.size.y
	if _body_used_rect.size.x * scale_factor > max_visible_width:
		scale_factor = max_visible_width / _body_used_rect.size.x

	var render_size := _body_texture_size * scale_factor
	var used_center_x := (_body_used_rect.position.x + _body_used_rect.size.x * 0.5) * scale_factor
	var used_bottom := (_body_used_rect.position.y + _body_used_rect.size.y) * scale_factor

	_body_scale = scale_factor
	_body_draw_position = Vector2(
		size.x * 0.5 - used_center_x,
		size.y * 0.985 - used_bottom
	)

	body_art.size = render_size
	body_art.position = _body_draw_position


func _apply_weapon_layout() -> void:
	if weapon_socket == null or weapon_art == null:
		return
	if size.x <= 1.0 or size.y <= 1.0:
		return
	if _weapon_used_rect.size.x <= 0.0 or _weapon_used_rect.size.y <= 0.0:
		return

	var spec: Dictionary = WEAPON_SOCKETS.get(_state, WEAPON_SOCKETS["idle"])
	var hand_uv: Vector2 = spec["hand_uv"]
	var hand_in_body_texture := Vector2(
		_body_texture_size.x * hand_uv.x,
		_body_texture_size.y * hand_uv.y
	)

	# Convert the authored hand point through the exact same body transform.
	weapon_socket.position = _body_draw_position + hand_in_body_texture * _body_scale
	weapon_socket.rotation = deg_to_rad(_weapon_base_rotation_deg + float(spec["rotation_deg"]))
	weapon_socket.z_index = 3 if bool(spec["draw_front"]) else -1

	# Weapon length is proportional to the visible HeroBody height, not slot width.
	var visible_body_height := _body_used_rect.size.y * _body_scale
	var target_extent := visible_body_height * float(spec["length_ratio"])
	var max_used_dimension := maxf(_weapon_used_rect.size.x, _weapon_used_rect.size.y)
	var scale_factor := target_extent / max_used_dimension
	var render_size := _weapon_texture_size * scale_factor

	var grip_in_texture := _weapon_used_rect.position + Vector2(
		_weapon_used_rect.size.x * _weapon_grip_uv.x,
		_weapon_used_rect.size.y * _weapon_grip_uv.y
	)

	weapon_art.size = render_size
	weapon_art.position = -grip_in_texture * scale_factor


func _texture_geometry(texture: Texture2D) -> Dictionary:
	if texture == null:
		return {
			"size": Vector2.ONE,
			"used": Rect2(Vector2.ZERO, Vector2.ONE),
		}

	var texture_size := texture.get_size()
	var used := Rect2(Vector2.ZERO, texture_size)
	var image: Image = texture.get_image()

	if image != null and image.get_width() > 0 and image.get_height() > 0:
		var used_i: Rect2i = image.get_used_rect()
		if used_i.size.x > 0 and used_i.size.y > 0:
			used = Rect2(Vector2(used_i.position), Vector2(used_i.size))

	return {
		"size": texture_size,
		"used": used,
	}


func _make_fill_layer(layer_name: String, layer_z: int) -> TextureRect:
	var layer := TextureRect.new()
	layer.name = layer_name
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.z_index = layer_z
	_fill(layer)
	layer.visible = false
	return layer


func _fill(control: Control) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 1.0
	control.anchor_bottom = 1.0
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0
