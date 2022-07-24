tool
extends Node2D
class_name VectorControl
# Abstract class for code shared by VectorPoint and VectorHandle
# Tracks whether or not transform has changed,
# since has_changed was last set to false

export(int, FLAGS, "") var tags := 1
var has_changed :bool setget set_has_changed, get_has_changed
onready var _cached_transform = null


func get_has_changed() -> bool:
	var parent = get_parent()
	if parent.get('is_control_point_group') and parent.has_changed:
		return true
	return ! _cached_transform or _cached_transform != transform


func set_has_changed(new_value: bool) -> void:
	if new_value:
		_cached_transform = null
	else:
		_cached_transform = transform


func get_position_in(reference_node: Node2D) -> Vector2:
	return reference_node.to_local(global_position)


func matches_mask(mask :int) -> bool:
	return bool(tags & mask)


func _get_layer_names(property_name :String) -> Array:
	if property_name != "tags":
		return []
	var parent = get_parent()
	if parent.has_method("_get_layer_names"):
		return parent._get_layer_names("tags")
	return []
