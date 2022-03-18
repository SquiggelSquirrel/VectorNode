tool
extends Line2D
class_name VectorStroke
# Line2D that provides a "stroke" for a VectorPath

export(NodePath) var path_node_path setget set_path_node_path
export(int) var start = 0 setget set_start
export(int) var end = 0 setget set_end
export(bool) var use_data_nodes_width = true setget set_use_data_nodes_width
export(bool) var use_data_nodes_color = true setget set_use_data_nodes_color
var is_vector_stroke := true
var _needs_shape_update := false
var _needs_data_update := false
var _segment_ratios := []
onready var _is_ready = true


func _ready() -> void:
	set_process( !! _get_path_node() )


func _process(_delta) -> void:
	var path_node = _get_path_node()
	if ! path_node:
		return
	if _needs_shape_update:
		update_shape()
	if _needs_data_update:
		update_data()


func _get_configuration_warning() -> String:
	if ! _get_path_node():
		return "No path node specified"
	return ""


func set_path_node_path(new_path :NodePath) -> void:
	path_node_path = new_path
	update_configuration_warning()
	if _is_ready:
		set_process(!! _get_path_node())
		_needs_shape_update = true
		_needs_data_update = true


func set_start(new_start :int) -> void:
	start = new_start
	_needs_shape_update = true
	_needs_data_update = true


func set_end(new_end :int) -> void:
	end = new_end
	_needs_shape_update = true
	_needs_data_update = true


func set_use_data_nodes_width(new_use_data_nodes_width: bool) -> void:
	use_data_nodes_width = new_use_data_nodes_width
	if new_use_data_nodes_width:
		_needs_data_update = true
	
	
func set_use_data_nodes_color(new_use_data_nodes_color: bool) -> void:
	use_data_nodes_color = new_use_data_nodes_color
	if new_use_data_nodes_color:
		_needs_data_update = true


func update_shape() -> void:
	var path_node = _get_path_node()
	if ! path_node:
		return
	points = path_node.get_shape(start,end)
	if path_node.range_is_closed(start,end):
		_close()
	_needs_shape_update = false


func update_data() -> void:
	var path_node = _get_path_node()
	if ! path_node:
		return
	_update_segment_ratios(path_node)
	if use_data_nodes_color:
		_update_color(path_node)
	if use_data_nodes_width:
		_update_width(path_node)


func _get_path_node():
	if path_node_path:
		var node := get_node(path_node_path)
		if node.get('is_vector_path'):
			return node
	return null


func _update_segment_ratios(path_node :Node) -> void:
	var length_offsets := [0.0]
	var total_length := 0.0
	for length in path_node.get_baked_lengths(start, end):
		total_length += length
		length_offsets.append(total_length)
	_segment_ratios = []
	for length in length_offsets:
		_segment_ratios.append(length / total_length)


func _update_color(data_node :Node) -> void:
	var offsets := []
	var colors := []
	var point_colors :Array = data_node.get_colors(start,end)
	if _segment_ratios.size() != point_colors.size():
		return
	for i in point_colors.size():
		offsets.append(_segment_ratios[i])
		colors.append(point_colors[i])
	if ! gradient:
		gradient = Gradient.new()
	gradient.offsets = offsets
	gradient.colors = colors


func _update_width(data_node :Node) -> void:
	var widths :Array = data_node.get_widths()
	if _segment_ratios.size() != widths.size():
		return
	if width_curve:
		width_curve.clear_points()
	else:
		width_curve = Curve.new()
	for i in widths.size():
		# warning-ignore:return_value_discarded
		width_curve.add_point(Vector2(
				_segment_ratios[i],
				widths[i]))


func _close() -> void:
	# Godot doesn't currently support closed Line2D nodes;
	# create a closed-like effect with an extra point *almost* overlapping
	# the start node, along the same line.
	var start_vector := (points[1] - points[0]).normalized()
	var close_point := points[0] + start_vector * -0.1
	var _points = points
	_points.append(close_point)
	_points.append(points[0])
	points = _points
