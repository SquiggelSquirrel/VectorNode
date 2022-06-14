tool
extends Node2D
class_name VectorPointGroup

var is_control_point_group := true
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


func get_point_nodes() -> Array:
	var points := []
	for child in get_children():
		if child.get("is_control_point"):
			points.append(child)
		if child.get("is_control_point_group"):
			points += child.get_point_nodes();
	return points
