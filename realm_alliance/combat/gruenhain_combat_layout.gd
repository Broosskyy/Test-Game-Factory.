extends RefCounted
class_name GruenhainCombatLayout

# Normalized slots inside the combat stage.
# These are the visual master contract. Gameplay/state changes must never rewrite them.

const PORTRAIT := {
	"ground_line": 0.74,
	"world_pill": Rect2(0.22, 0.018, 0.56, 0.064),
	"streak": Rect2(0.018, 0.105, 0.23, 0.08),
	"enemy_hud": Rect2(0.275, 0.095, 0.45, 0.105),

	"hero": Rect2(0.05, 0.405, 0.34, 0.335),
	"normal": Rect2(0.53, 0.33, 0.43, 0.41),
	"elite": Rect2(0.49, 0.285, 0.49, 0.455),
	"boss": Rect2(0.41, 0.195, 0.59, 0.555),

	"damage": Rect2(0.67, 0.295, 0.30, 0.20),
	"hit_fx": Rect2(0.52, 0.30, 0.46, 0.38),

	"bottom_backing": Rect2(0.0, 0.715, 1.0, 0.285),
	"vitals": Rect2(0.025, 0.725, 0.84, 0.07),
	"skills": Rect2(0.035, 0.812, 0.93, 0.153),
	"attack_hint": Rect2(0.31, 0.675, 0.38, 0.04),
}

const LANDSCAPE := {
	"ground_line": 0.76,
	"world_pill": Rect2(0.33, 0.02, 0.34, 0.10),
	"streak": Rect2(0.02, 0.12, 0.18, 0.13),
	"enemy_hud": Rect2(0.35, 0.10, 0.30, 0.16),

	"hero": Rect2(0.10, 0.36, 0.23, 0.40),
	"normal": Rect2(0.63, 0.36, 0.25, 0.40),
	"elite": Rect2(0.60, 0.31, 0.31, 0.45),
	"boss": Rect2(0.55, 0.22, 0.39, 0.54),

	"damage": Rect2(0.70, 0.25, 0.22, 0.28),
	"hit_fx": Rect2(0.58, 0.27, 0.34, 0.40),

	"bottom_backing": Rect2(0.0, 0.715, 1.0, 0.285),
	"vitals": Rect2(0.20, 0.725, 0.60, 0.075),
	"skills": Rect2(0.25, 0.82, 0.50, 0.15),
	"attack_hint": Rect2(0.38, 0.66, 0.24, 0.06),
}


static func profile(is_landscape: bool) -> Dictionary:
	return LANDSCAPE if is_landscape else PORTRAIT


static func apply_slot(control: Control, rect: Rect2) -> void:
	if control == null:
		return

	control.anchor_left = rect.position.x
	control.anchor_top = rect.position.y
	control.anchor_right = rect.position.x + rect.size.x
	control.anchor_bottom = rect.position.y + rect.size.y
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0
