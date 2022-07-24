tool
extends CollisionPolygon2D
class_name VectorCollisionPolygon
# Collision Polygon with points updated from a VectorPath

export(NodePath) var path_node_path setget set_path_node_path
export(int, FLAGS, "") var mask := 1

var is_vector_fill := true

onready var is_ready := true


func _get_configuration_warning():
	if ! _get_path_node():
		return "No valid path set"
	return ""


func set_path_node_path(new_path :NodePath) -> void:
	path_node_path = new_path
	update_configuration_warning()
	if is_ready and path_node_path:
		update_polygon()


func update_polygon():
	var node = _get_path_node()
	if ! node:
		return
	polygon = node.get_shape(0,0,mask)


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
