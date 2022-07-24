tool
extends Node2D
class_name VectorMultiFill

enum Direction {CLOCKWISE, ANTICLOCKWISE}

export(NodePath) var path_node_path setget set_path_node_path
export(int, FLAGS, "") var mask := 1
export(Color) var color := Color.white
export(Direction) var direction :int = Direction.CLOCKWISE
export(PoolVector2Array) var polygon := []

var is_vector_fill := true

var _self_intersections := []
var _polygons = []

onready var is_ready := true


func set_path_node_path(new_path :NodePath) -> void:
	path_node_path = new_path
	update_configuration_warning()
	if is_ready and path_node_path:
		update_fill()


func update_fill():
	var node = _get_path_node()
	if ! node:
		return
	polygon = node.get_shape(0,0,mask)
	_self_intersections = SelfIntersect.get_self_intersections(polygon)
	update()


func _get_configuration_warning():
	if ! _get_path_node():
		return "No valid path set"
	return ""


func _draw():
	draw_colored_polygon(polygon, color)


func _get_path_node():
	if path_node_path == "":
		return null
	var node = get_node(path_node_path)
	if ! node:
		return null
	if node.get('is_vector_path'):
		return node
	return null


func _get_layer_names(property_name :String) -> Array:
	if property_name != "mask":
		return []
	var path_node = _get_path_node()
	if ! path_node:
		return []
	return path_node._get_layer_names("tags")

