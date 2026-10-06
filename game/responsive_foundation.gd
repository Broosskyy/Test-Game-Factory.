extends Control

const PORTRAIT_REFERENCE := Vector2i(720, 1280)
const LANDSCAPE_REFERENCE := Vector2i(960, 540)

@onready var viewport_readout: Label = %ViewportReadout
@onready var orientation_badge: Label = %OrientationBadge
@onready var fullscreen_button: Button = %FullscreenButton

var _last_landscape: bool
var _profile_initialized := false
var _applying_profile := false


func _ready() -> void:
	if not get_window().size_changed.is_connected(_on_window_size_changed):
		get_window().size_changed.connect(_on_window_size_changed)

	if not fullscreen_button.pressed.is_connected(_toggle_fullscreen):
		fullscreen_button.pressed.connect(_toggle_fullscreen)

	fullscreen_button.visible = OS.get_name() == "Web"
	_apply_orientation_profile()
	call_deferred("_refresh_debug_readout")


func _on_window_size_changed() -> void:
	if _applying_profile:
		return

	_apply_orientation_profile()
	call_deferred("_refresh_debug_readout")


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


func _refresh_debug_readout() -> void:
	var physical_size := get_window().size
	var logical_size := get_viewport_rect().size
	var orientation := "LANDSCAPE" if physical_size.x > physical_size.y else "PORTRAIT"

	orientation_badge.text = orientation
	viewport_readout.text = "%d x %d" % [
		roundi(logical_size.x),
		roundi(logical_size.y)
	]


func _toggle_fullscreen() -> void:
	var current_mode := DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
