extends CharacterBody2D

@export var move_speed := 360.0
@export var acceleration := 2400.0
@export var deceleration := 3000.0

var _movement_source: Node
var _facing := Vector2.DOWN


func _ready() -> void:
	_movement_source = get_tree().get_first_node_in_group("movement_input")
	queue_redraw()


func _physics_process(delta: float) -> void:
	var input_vector := _keyboard_vector()

	if is_instance_valid(_movement_source) and _movement_source.has_method("get_vector"):
		var touch_vector: Vector2 = _movement_source.call("get_vector")
		if touch_vector.length() > 0.04:
			input_vector = touch_vector

	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()

	if input_vector.length() > 0.04:
		_facing = input_vector.normalized()
		var target_velocity := input_vector * move_speed
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
		queue_redraw()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)

	move_and_slide()


func _keyboard_vector() -> Vector2:
	var direction := Vector2.ZERO

	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0

	return direction.normalized()


func _draw() -> void:
	draw_circle(Vector2(0, 9), 34.0, Color(0.0, 0.0, 0.0, 0.32))
	draw_circle(Vector2.ZERO, 31.0, Color(0.74, 0.81, 0.96, 1.0))
	draw_circle(Vector2.ZERO, 25.0, Color(0.13, 0.17, 0.24, 1.0))
	draw_line(Vector2.ZERO, _facing * 24.0, Color(0.5, 0.72, 1.0, 1.0), 5.0, true)
	draw_circle(_facing * 24.0, 5.5, Color(0.72, 0.86, 1.0, 1.0))
