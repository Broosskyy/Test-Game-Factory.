extends MarginContainer
## Keeps UI content away from native display cutouts while preserving
## a consistent design margin on Web and desktop.
##
## The game canvas itself always fills the available viewport. This node
## only protects interactive UI content.

@export var design_margin: float = 40.0

func _ready() -> void:
	if not get_viewport().size_changed.is_connected(_apply_safe_area):
		get_viewport().size_changed.connect(_apply_safe_area)
	call_deferred("_apply_safe_area")


func _apply_safe_area() -> void:
	var left := design_margin
	var top := design_margin
	var right := design_margin
	var bottom := design_margin

	var platform := OS.get_name()
	if platform == "Android" or platform == "iOS":
		var safe_rect := DisplayServer.get_display_safe_area()
		var screen_size := DisplayServer.screen_get_size(DisplayServer.SCREEN_OF_MAIN_WINDOW)
		var viewport_size := get_viewport_rect().size

		if screen_size.x > 0 and screen_size.y > 0 and safe_rect.size.x > 0 and safe_rect.size.y > 0:
			var scale_x := viewport_size.x / float(screen_size.x)
			var scale_y := viewport_size.y / float(screen_size.y)
			var safe_end := safe_rect.position + safe_rect.size

			left = maxf(left, safe_rect.position.x * scale_x)
			top = maxf(top, safe_rect.position.y * scale_y)
			right = maxf(right, (screen_size.x - safe_end.x) * scale_x)
			bottom = maxf(bottom, (screen_size.y - safe_end.y) * scale_y)

	add_theme_constant_override("margin_left", int(ceil(left)))
	add_theme_constant_override("margin_top", int(ceil(top)))
	add_theme_constant_override("margin_right", int(ceil(right)))
	add_theme_constant_override("margin_bottom", int(ceil(bottom)))
