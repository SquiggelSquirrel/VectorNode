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
export(float, 1.0, 100.0) var bake_interval = 10.0
export(Color) var color_handle_in := Color.red setget set_color_handle_in
export(Color) var color_handle_out := Color.green setget set_color_handle_out
var _curves := {}
var _cached_bake_interval = 10.0


func _process(_delta) -> void:
	if get_shape_has_changed():
		_expire_changed_curves()
		emit_signal("shape_changed")
		set_shape_has_changed(false)
		update()
	if get_stroke_data_has_changed():
		emit_signal("stroke_data_changed")
		set_stroke_data_has_changed(false)


func _draw() -> void:
	for point in get_point_nodes():
		var start := to_global(point.get_position_in(self))
		var end := to_global(point.get_position_in(self) + point.get_handle_in(self))
		draw_line(start, end, color_handle_in)
		end = to_global(point.get_position_in(self) + point.get_handle_out(self))
		draw_line(start, end, color_handle_out)


func set_color_handle_in(new_color :Color) -> void:
	color_handle_in = new_color
	update()


func set_color_handle_out(new_color :Color) -> void:
	color_handle_out = new_color
	update()


func get_shape(start := 0.0, end := 0.0) -> Array:
	var shape :=  []
	var curves := _get_curves(start, end)
	var start_fraction := fposmod(start, 1.0)
	var end_fraction := fposmod(end, 1.0)
	var last_point
	
	for i in curves.size():
		var curve = curves[i]
		if curve is Curve2D:
			var baked_points := Array(curves[i].get_baked_points())
			var first := 0
			var last := -2
			var prepend_point
			last_point = baked_points[-1]
			
			if i == 0 and start_fraction > 0.0:
				var f := start_fraction * (baked_points.size() -1)
				var before := int(f)
				first = before + 1
				prepend_point = lerp(
						baked_points[before],
						baked_points[first],
						f - before)
			
			if i + 1 == curves.size() and end_fraction > 0.0:
				var f := end_fraction * (baked_points.size() -1)
				last = int(f)
				if ! range_is_closed(start, end):
					last_point = lerp(
							baked_points[last],
							baked_points[last + 1],
							f - last)
			
			if prepend_point:
				shape.append(prepend_point)
			shape += baked_points.slice(first, last)
		
		else:
			var start_point = curve[0]
			var end_point = curve[1]
			if i == 0 and start_fraction > 0.0:
				start_point = lerp(
						curve[0],
						curve[1],
						start_fraction)
			if i + 1 == curves.size() and end_fraction > 0.0:
				end_point = lerp(
						curve[0],
						curve[1],
						end_fraction)
				
			shape.append(start_point)
			last_point = end_point
	
	if ! range_is_closed(start, end) and curves.size() > 0:
		shape.append(last_point)
	
	return shape


func get_baked_lengths(start := 0.0, end := 0.0) -> Array:
	var lengths := []
	var curves := _get_curves(start, end)
	for i in curves.size():
		var curve = curves[i]
		
		var length :float
		if curve is Curve2D:
			length = curve.get_baked_length()
		else:
			length = curve[0].distance_to(curve[1])
		
		var start_fraction := 0.0
		if i == 0:
			start_fraction = fposmod(start, 1.0)
		var head_length := length * start_fraction
		
		var end_fraction := 1.0
		if i + 1 == curves.size():
			end_fraction = fposmod(end, 1.0)
			end_fraction = stepify(end_fraction, 0.001)
			if end_fraction == 0.0:
				end_fraction = 1.0
		var tail_length := length * (1.0 - end_fraction)
		
		length -= head_length + tail_length
		lengths.append(length)
		
	return lengths


func get_colors(start := 0.0, end := 0.0) -> Array:
	var colors := []
	for node in get_point_nodes(start, end):
		colors.append(node.stroke_color)
	return colors


func get_widths(start := 0.0, end := 0.0) -> Array:
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
		_cached_bake_interval = null
	else:
		_cached_bake_interval = bake_interval
	for point in get_point_nodes():
		point.set_shape_has_changed(new_value)


func set_stroke_data_has_changed(new_value: bool) -> void:
	for point in get_point_nodes():
		point.set_stroke_data_has_changed(new_value)


func get_point_nodes(start := 0.0, end := 0.0) -> Array:
	var points := []
	for child in get_children():
		if child.get("is_control_point"):
			points.append(child)
	return _get_array_range(points, start, end)


func range_is_closed(start :float, end:float) -> bool:
	var size := float(get_point_nodes().size())
	return wrapf(start, 0.0, size) == wrapf(end, 0.0, size)


func _get_array_range(array :Array, start :float, end:float) -> Array:
	if array.size() == 0:
		return array
	var fsize = float(array.size())
	
	start = fposmod(start, fsize)
	end = wrapf(end, start, start + fsize)
	end = stepify(end, 0.001) # stepify to elimitate floating-point error
	if end == start:
		end += fsize
		
	var int_start := int(floor(start))
	var int_end := int(ceil(end))
	
	var result := []
	for i in range(int_start, int_end + 1):
		result.append(array[wrapi(i, 0, array.size())])
	
	return result


func _get_curves(start := 0.0, end := 0.0) -> Array:
	var curves := []
	var point_nodes = get_point_nodes(start, end)
	for i in range(0, point_nodes.size() - 1):
		curves.append(_get_curve(point_nodes[i], point_nodes[i+1]))
	return curves


func _get_curve(start_point :Node, end_point :Node):
	if _curves.has([start_point,end_point]):
		return _curves[[start_point,end_point]]
	else:
		var curve = _get_new_curve(start_point, end_point)
		_curves[[start_point,end_point]] = curve
		return curve


func _is_straight(start_point :Node, end_point :Node) -> bool:
	return (
			start_point.get_handle_out(self) == Vector2.ZERO
			and
			end_point.get_handle_in(self) == Vector2.ZERO
	);


func _get_new_curve(start_point :Node, end_point :Node):
	if _is_straight(start_point, end_point):
		return [
				start_point.get_position_in(self),
				end_point.get_position_in(self)]
	var curve := Curve2D.new()
	if start_point.bake_interval == 0.0:
		curve.bake_interval = bake_interval
	else:
		curve.bake_interval = start_point.bake_interval
	curve.add_point(
			start_point.get_position_in(self),
			start_point.get_handle_in(self),
			start_point.get_handle_out(self))
	curve.add_point(
			end_point.get_position_in(self),
			end_point.get_handle_in(self),
			end_point.get_handle_out(self))
	return curve


func _expire_changed_curves() -> void:
	var bake_interval_has_changed = _cached_bake_interval != bake_interval
	for key in _curves.keys():
		if (
				key[0].get_has_changed() or key[0].get_handle_out_has_changed()
				or
				key[1].get_has_changed() or key[1].get_handle_in_has_changed()
				or
				(key[0].bake_interval < 1.0 and bake_interval_has_changed)
		):
			# warning-ignore:return_value_discarded
			_curves.erase(key)
