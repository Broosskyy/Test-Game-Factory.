extends Node2D

const WORLD_SIZE := Vector2(2400.0, 2000.0)
const WALL_THICKNESS := 64.0
const GRID_SIZE := 128


func _ready() -> void:
	_create_boundaries()
	queue_redraw()


func _create_boundaries() -> void:
	_create_wall(
		Vector2(WORLD_SIZE.x * 0.5, -WALL_THICKNESS * 0.5),
		Vector2(WORLD_SIZE.x + WALL_THICKNESS * 2.0, WALL_THICKNESS)
	)
	_create_wall(
		Vector2(WORLD_SIZE.x * 0.5, WORLD_SIZE.y + WALL_THICKNESS * 0.5),
		Vector2(WORLD_SIZE.x + WALL_THICKNESS * 2.0, WALL_THICKNESS)
	)
	_create_wall(
		Vector2(-WALL_THICKNESS * 0.5, WORLD_SIZE.y * 0.5),
		Vector2(WALL_THICKNESS, WORLD_SIZE.y)
	)
	_create_wall(
		Vector2(WORLD_SIZE.x + WALL_THICKNESS * 0.5, WORLD_SIZE.y * 0.5),
		Vector2(WALL_THICKNESS, WORLD_SIZE.y)
	)


func _create_wall(wall_position: Vector2, wall_size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = wall_position

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = wall_size
	collision.shape = shape

	body.add_child(collision)
	add_child(body)


func _draw() -> void:
	var world_rect := Rect2(Vector2.ZERO, WORLD_SIZE)
	draw_rect(world_rect, Color(0.035, 0.042, 0.055, 1.0), true)

	var grid_color := Color(0.12, 0.14, 0.18, 0.42)
	for x in range(0, int(WORLD_SIZE.x) + 1, GRID_SIZE):
		draw_line(Vector2(x, 0), Vector2(x, WORLD_SIZE.y), grid_color, 1.0)

	for y in range(0, int(WORLD_SIZE.y) + 1, GRID_SIZE):
		draw_line(Vector2(0, y), Vector2(WORLD_SIZE.x, y), grid_color, 1.0)

	draw_rect(world_rect, Color(0.34, 0.4, 0.52, 0.9), false, 6.0)
	draw_circle(WORLD_SIZE * 0.5, 10.0, Color(0.46, 0.66, 1.0, 0.9))
