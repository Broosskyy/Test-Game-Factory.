extends Control

@onready var viewport_readout: Label = %ViewportReadout
@onready var orientation_badge: Label = %OrientationBadge


func _ready() -> void:
	if not get_viewport().size_changed.is_connected(_refresh_debug_readout):
		get_viewport().size_changed.connect(_refresh_debug_readout)
	call_deferred("_refresh_debug_readout")


func _refresh_debug_readout() -> void:
	var size := get_viewport_rect().size
	var orientation := "PORTRAIT" if size.y >= size.x else "LANDSCAPE"
	orientation_badge.text = orientation
	viewport_readout.text = "%d × %d logical viewport" % [roundi(size.x), roundi(size.y)]
