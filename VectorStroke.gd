tool
extends Line2D
class_name VectorStroke
# Line2D that provides a "stroke" for a VectorPath

export(NodePath) var path_node_path setget set_path_node_path
export(int, FLAGS, "") var mask := 1
export(float) var start := 0.0 setget set_start
export(float) var end := 0.0 setget set_end
export(bool) var use_data_nodes_width = false setget set_use_data_nodes_width
export(bool) var use_data_nodes_color = false setget set_use_data_nodes_color
export(bool) var use_close_fix = false setget set_use_close_fix
export(float, 1.0) var start_pinch_length := 0.0 setget set_start_pinch_length
export(float, 1.0) var end_pinch_length := 0.0 setget set_end_pinch_length

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


func set_start(new_start :float) -> void:
	start = new_start
	_needs_shape_update = true
	_needs_data_update = true


func set_end(new_end :float) -> void:
	end = new_end
	_needs_shape_update = true
	_needs_data_update = true


func set_start_pinch_length(length :float) -> void:
	start_pinch_length = length
	_needs_data_update = true


func set_end_pinch_length(length :float) -> void:
	end_pinch_length = length
	_needs_data_update = true


func set_use_data_nodes_width(new_use_data_nodes_width: bool) -> void:
	use_data_nodes_width = new_use_data_nodes_width
	if new_use_data_nodes_width:
		_needs_data_update = true
	
	
func set_use_data_nodes_color(new_use_data_nodes_color: bool) -> void:
	use_data_nodes_color = new_use_data_nodes_color
	if new_use_data_nodes_color:
		_needs_data_update = true


func set_use_close_fix(new_use_close_fix :bool) -> void:
	use_close_fix = new_use_close_fix
	_needs_shape_update = true


func update_shape() -> void:
	var path_node = _get_path_node()
	if ! path_node:
		return
	points = path_node.get_shape(start,end,mask)
	if path_node.range_is_closed(start,end):
		_close()
	_needs_shape_update = false


func update_data() -> void:
	var path_node = _get_path_node()
	if ! path_node:
		return
	_update_segment_ratios(path_node, mask)
	if use_data_nodes_color:
		_update_color(path_node, mask)
	if use_data_nodes_width:
		_update_width(path_node, mask)
	_needs_data_update = false


func _get_path_node():
	if path_node_path:
		var node := get_node(path_node_path)
		if node.get('is_vector_path'):
			return node
	return null


func _update_segment_ratios(path_node :Node, mask :int = 1) -> void:
	var length_offsets := [0.0]
	var total_length := 0.0
	for length in path_node.get_baked_lengths(start, end, mask):
		total_length += length
		length_offsets.append(total_length)
	_segment_ratios = []
	for length in length_offsets:
		_segment_ratios.append(length / total_length)


func _update_color(data_node :Node, mask :int = 1) -> void:
	var offsets := []
	var colors := []
	var point_colors :Array = data_node.get_colors(start, end, mask)
	if _segment_ratios.size() != point_colors.size():
		return
	
	var start_fraction := fposmod(start, 1.0)
	var end_fraction := fposmod(end, 1.0)
	
	for i in point_colors.size():
		offsets.append(_segment_ratios[i])
		
		if i == 0 and start_fraction != 0.0:
			colors.append(lerp(
					point_colors[0],
					point_colors[1],
					start_fraction))
		elif i + 1 == point_colors.size() and end_fraction != 0.0:
			colors.append(lerp(
					point_colors[i-1],
					point_colors[i],
					end_fraction))
		else:
			colors.append(point_colors[i])
	
	if ! gradient:
		gradient = Gradient.new()
	gradient.offsets = offsets
	gradient.colors = colors


func _update_width(data_node :Node, mask :int = 1) -> void:
	var widths :Array = data_node.get_widths(start, end, mask)
	if _segment_ratios.size() != widths.size():
		return
	if width_curve:
		width_curve.clear_points()
	else:
		width_curve = Curve.new()
	
	var start_fraction := fposmod(start, 1.0)
	var end_fraction := fposmod(end, 1.0)
	
	for i in widths.size():
		var width
		if i == 0 and start_fraction != 0.0:
			width = lerp(widths[0], widths[1], start_fraction)
		elif i + 1 == widths.size() and end_fraction != 0.0:
			width = lerp(widths[i-1], widths[i], end_fraction)
		else:
			width = widths[i]
		
		# warning-ignore:return_value_discarded
		width_curve.add_point(Vector2(_segment_ratios[i],width))
	
	if start_pinch_length > 0.0:
		var width := width_curve.interpolate(start_pinch_length)
		for i in width_curve.get_point_count():
			for j in width_curve.get_point_count():
				if width_curve.get_point_position(j)[0] <= start_pinch_length:
					width_curve.remove_point(j)
					break
		# warning-ignore:return_value_discarded
		width_curve.add_point(Vector2.ZERO)
		# warning-ignore:return_value_discarded
		width_curve.add_point(Vector2(start_pinch_length,width))
	
	if end_pinch_length > 0.0:
		var end_pinch := 1.0 - end_pinch_length
		var width := width_curve.interpolate(end_pinch)
		for i in width_curve.get_point_count():
			for j in width_curve.get_point_count():
				if width_curve.get_point_position(j)[0] >= end_pinch:
					width_curve.remove_point(j)
					break
		# warning-ignore:return_value_discarded
		width_curve.add_point(Vector2.RIGHT)
		# warning-ignore:return_value_discarded
		width_curve.add_point(Vector2(end_pinch, width))


func _close() -> void:
	# Godot doesn't currently support closed Line2D nodes;
	# create a closed-like effect with an extra point overlapping
	# the start line
	var _points = points
	_points.append(points[0])
	if use_close_fix:
		var start_vector := (points[1] - points[0]).normalized()
		var close_point := points[0] + start_vector * 0.1
		_points.append(close_point)
	points = _points


func _get_layer_names(property_name :String) -> Array:
	if property_name != "mask":
		return []
	var path_node = _get_path_node()
	if ! path_node:
		return []
	return path_node._get_layer_names("tags")
