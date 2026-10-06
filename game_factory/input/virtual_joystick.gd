extends Control

@export_range(0.0, 0.5, 0.01) var deadzone := 0.14

var _value := Vector2.ZERO
var _knob_offset := Vector2.ZERO
var _active_touch := -1
var _mouse_active := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func get_vector() -> Vector2:
	return _value


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _active_touch == -1:
			_active_touch = event.index
			_update_from_local_position(event.position)
			accept_event()
		elif not event.pressed and event.index == _active_touch:
			_active_touch = -1
			_reset()
			accept_event()

	elif event is InputEventScreenDrag and event.index == _active_touch:
		_update_from_local_position(event.position)
		accept_event()

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_mouse_active = event.pressed
		if _mouse_active:
			_update_from_local_position(event.position)
		else:
			_reset()
		accept_event()

	elif event is InputEventMouseMotion and _mouse_active:
		_update_from_local_position(event.position)
		accept_event()


func _update_from_local_position(local_position: Vector2) -> void:
	var center := size * 0.5
	var radius := maxf(1.0, minf(size.x, size.y) * 0.36)
	var raw_offset := local_position - center
	_knob_offset = raw_offset.limit_length(radius)

	var normalized := _knob_offset / radius
	var magnitude := normalized.length()

	if magnitude <= deadzone:
		_value = Vector2.ZERO
	else:
		var scaled_magnitude := inverse_lerp(deadzone, 1.0, minf(magnitude, 1.0))
		_value = normalized.normalized() * scaled_magnitude

	queue_redraw()


func _reset() -> void:
	_value = Vector2.ZERO
	_knob_offset = Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.36
	var knob_radius := radius * 0.43

	draw_circle(center, radius, Color(0.05, 0.065, 0.09, 0.72))
	draw_arc(center, radius, 0.0, TAU, 64, Color(0.46, 0.58, 0.78, 0.42), 3.0, true)
	draw_circle(center + _knob_offset, knob_radius, Color(0.56, 0.72, 1.0, 0.9))
	draw_circle(center + _knob_offset, knob_radius * 0.58, Color(0.13, 0.17, 0.24, 0.95))
