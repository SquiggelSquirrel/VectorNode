tool
extends Node2D
class_name VectorControl
# Abstract class for code shared by VectorPoint and VectorHandle
# Tracks whether or not transform has changed,
# since has_changed was last set to false

var has_changed :bool setget set_has_changed, get_has_changed
onready var _cached_transform = null


func get_has_changed() -> bool:
	return ! _cached_transform or _cached_transform != transform


func set_has_changed(new_value: bool) -> void:
	if new_value:
		_cached_transform = null
	else:
		_cached_transform = transform


func get_position_in(reference_node: Node2D) -> Vector2:
	return reference_node.to_local(global_position)
