extends Control
class_name HeroVisualRig

# Visual composition only. Gameplay stats/items live outside this rig.
# The rig keeps future customization modular while the current slice activates
# only Body + Weapon.

const WEAPON_SOCKETS := {
	"idle": {
		"position": Vector2(0.64, 0.58),
		"rotation_deg": 22.0,
		"extent": 0.82,
		"draw_front": true,
	},
	"attack": {
		"position": Vector2(0.62, 0.50),
		"rotation_deg": -34.0,
		"extent": 0.90,
		"draw_front": true,
	},
	"skill": {
		"position": Vector2(0.60, 0.47),
		"rotation_deg": -42.0,
		"extent": 0.94,
		"draw_front": true,
	},
	"hit": {
		"position": Vector2(0.64, 0.57),
		"rotation_deg": 34.0,
		"extent": 0.82,
		"draw_front": true,
	},
	"victory": {
		"position": Vector2(0.57, 0.35),
		"rotation_deg": -118.0,
		"extent": 0.92,
		"draw_front": true,
	},
	"defeat": {
		"position": Vector2(0.59, 0.68),
		"rotation_deg": 76.0,
		"extent": 0.78,
		"draw_front": true,
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
var _weapon_grip_uv := Vector2(0.50, 0.82)
var _weapon_base_rotation_deg := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_layers()


func _ready() -> void:
	if not resized.is_connected(_apply_socket_layout):
		resized.connect(_apply_socket_layout)
	_apply_socket_layout()


func _build_layers() -> void:
	aura_back_art = _make_layer("AuraBack", -4)
	add_child(aura_back_art)

	back_socket = Control.new()
	back_socket.name = "BackSocket"
	back_socket.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill(back_socket)
	back_socket.z_index = -3
	add_child(back_socket)

	wings_art = _make_layer("Wings", 0)
	back_socket.add_child(wings_art)

	body_art = _make_layer("Body", 0)
	add_child(body_art)

	# Complete armor/outfit visual. Kept empty for the current slice.
	outfit_art = _make_layer("Outfit", 1)
	add_child(outfit_art)

	weapon_socket = Control.new()
	weapon_socket.name = "WeaponSocket"
	weapon_socket.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weapon_socket.z_index = 3
	add_child(weapon_socket)

	weapon_art = TextureRect.new()
	weapon_art.name = "Weapon"
	weapon_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	weapon_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	weapon_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weapon_socket.add_child(weapon_art)

	head_socket = Control.new()
	head_socket.name = "HeadSocket"
	head_socket.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill(head_socket)
	head_socket.z_index = 4
	add_child(head_socket)

	headgear_art = _make_layer("Headgear", 0)
	head_socket.add_child(headgear_art)

	aura_front_art = _make_layer("AuraFront", 5)
	add_child(aura_front_art)


func set_body_texture(texture: Texture2D) -> void:
	body_art.texture = texture


func set_weapon(texture: Texture2D, grip_uv: Vector2, base_rotation_deg: float = 0.0) -> void:
	weapon_art.texture = texture
	_weapon_grip_uv = grip_uv
	_weapon_base_rotation_deg = base_rotation_deg
	weapon_art.visible = texture != null
	_apply_socket_layout()


func set_state(state: String) -> void:
	_state = state if WEAPON_SOCKETS.has(state) else "idle"
	_apply_socket_layout()


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


func _apply_socket_layout() -> void:
	if weapon_socket == null or weapon_art == null:
		return
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var spec: Dictionary = WEAPON_SOCKETS.get(_state, WEAPON_SOCKETS["idle"])
	var uv: Vector2 = spec["position"]
	weapon_socket.position = Vector2(size.x * uv.x, size.y * uv.y)
	weapon_socket.rotation = deg_to_rad(_weapon_base_rotation_deg + float(spec["rotation_deg"]))
	weapon_socket.z_index = 3 if bool(spec["draw_front"]) else -1

	var extent := minf(size.x, size.y) * float(spec["extent"])
	weapon_art.size = Vector2(extent, extent)
	# The grip point becomes local (0,0), so rotation happens around the hand.
	weapon_art.position = -Vector2(extent * _weapon_grip_uv.x, extent * _weapon_grip_uv.y)


func _make_layer(layer_name: String, layer_z: int) -> TextureRect:
	var layer := TextureRect.new()
	layer.name = layer_name
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.z_index = layer_z
	_fill(layer)
	layer.visible = layer_name == "Body"
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
