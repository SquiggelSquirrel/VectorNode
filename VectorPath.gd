tool
extends Node2D
class_name VectorPath
# Vector Shape Path container
# Monitors for changes to the points & handles
# Emits a "changed" signal when changes occur
# Exposes a curve for each path segment,
# Can provide an array of points for any range of segments

signal shape_changed
signal stroke_data_changed

var is_vector_path = true
export(float) var bake_interval = 10.0
var _cached_bake_interval := 10.0
var _curves := {}


func _process(_delta) -> void:
	if get_shape_has_changed():
		_curves = {}
		emit_signal("shape_changed")
		set_shape_has_changed(false)
	if get_stroke_data_has_changed():
		emit_signal("stroke_data_changed")
		set_stroke_data_has_changed(false)


func get_shape(start := 0, end := 0) -> Array:
	var shape :=  []
	var curves = _get_curves(start, end)
	var last_point
	for curve in curves:
		var baked_points = Array(curve.get_baked_points())
		shape += baked_points.slice(0,-2)
		last_point = baked_points[-1]
	if ! range_is_closed(start,end) and curves.size() > 0:
		shape.append(last_point)
	return shape


func get_baked_lengths(start := 0, end := 0) -> Array:
	var lengths := []
	for curve in _get_curves(start, end):
		lengths.append(curve.get_baked_length())
	return lengths


func get_curve(start_point :Node, end_point :Node) -> Curve2D:
	if _curves.has([start_point,end_point]):
		return _curves[[start_point,end_point]]
	else:
		var curve = _get_curve(start_point, end_point)
		_curves[[start_point,end_point]] = curve
		return curve


func get_colors(start := 0, end := 0) -> Array:
	var colors := []
	for node in get_point_nodes(start, end):
		colors.append(node.stroke_color)
	return colors


func get_widths(start := 0, end := 0) -> Array:
	var widths := []
	for node in get_point_nodes(start, end):
		widths.append(node.stroke_width)
	return widths


func get_shape_has_changed() -> bool:
	if _cached_bake_interval != bake_interval:
		return true
	for point in get_point_nodes():
		if point.get_shape_has_changed():
			return true
	return false


func get_stroke_data_has_changed() -> bool:
	for point in get_point_nodes():
		if point.get_stroke_data_has_changed():
			return true
	return false


func set_shape_has_changed(new_value: bool) -> void:
	if new_value:
		_cached_bake_interval = 0.0
	else:
		_cached_bake_interval = bake_interval
	for point in get_point_nodes():
		point.set_shape_has_changed(new_value)


func set_stroke_data_has_changed(new_value: bool) -> void:
	for point in get_point_nodes():
		point.set_stroke_data_has_changed(new_value)


func get_point_nodes(start := 0, end := 0) -> Array:
	var points := []
	for child in get_children():
		if child.get("is_control_point"):
			points.append(child)
	return _get_array_range(points, start, end)


func range_is_closed(start :int, end:int) -> bool:
	var size := get_point_nodes().size()
	return wrapi(start, 0, size) == wrapi(end, 0, size)


func _get_array_range(array :Array, start :int, end:int) -> Array:
	if array.size() == 0:
		return array
	start = wrapi(start, 0, array.size())
	end = wrapi(end, start + 1, start + array.size() + 1)
	var result := []
	for i in range(start, end + 1):
		result.append(array[wrapi(i, 0, array.size())])
	return result


func _get_curves(start := 0, end := 0) -> Array:
	var curves := []
	var point_nodes = get_point_nodes(start, end)
	for i in range(0, point_nodes.size() - 1):
		curves.append(get_curve(point_nodes[i], point_nodes[i+1]))
	return curves


func _get_curve(start_point :Node, end_point :Node) -> Curve2D:
	var curve := Curve2D.new()
	curve.bake_interval = bake_interval
	curve.add_point(
			start_point.get_position_in(self),
			start_point.get_handle_in(self),
			start_point.get_handle_out(self))
	curve.add_point(
			end_point.get_position_in(self),
			end_point.get_handle_in(self),
			end_point.get_handle_out(self))
	return curve
