tool
extends Object
class_name SelfIntersect

enum {LANDSCAPE, PORTRAIT}


static func self_intersections(points :Array) -> Array:
	if points.size() < 3:
		return []
	var segments := find_segments(points)
	var collisions := colliding_segments(points, segments)
	var intersections := []
	while collisions.size() > 0:
		var pair = collisions.pop_front()
		var a := pair[0] as Segment
		var b := pair[1] as Segment
		if a.length == 1 and b.length == 1:
			if intersects(a, b):
				intersections.append(get_intersection(a, b))
		if a.length > b.length:
			for segment in a.split():
				if overlap(segment.box, b.box):
					collisions.append([segment, b])
		else:
			for segment in b.split():
				if overlap(segment.box, a.box):
					collisions.append([segment, a])
	return intersections


static func intersects(a :Segment, b :Segment) -> bool:
	if ! segment_crosses_line(a,b):
		return false
	if ! segment_crosses_line(b,a):
		return false
	return true


static func segment_crosses_line(segment :Segment, line :Segment) -> bool:
	var compare_1 := point_line_compare(
			segment.start_point(), line.start_point(), line.end_point())
	if compare_1 == 0:
		return false
	var compare_2 := point_line_compare(
			segment.end_point(), line.start_point(), line.end_point()
	)
	if compare_2 == 0 or compare_2 == compare_1:
		return false
	return true


static func point_line_compare(
	point :Vector2, start :Vector2, end :Vector2
) -> int:
	var offset_point := point - start
	var offset_end := end - start
	return compare(cross(offset_point, offset_end), 0)


static func cross(a :Vector2, b :Vector2) -> float:
	return a.x * b.y - b.x * a.y


static func get_intersection(line_1 :Segment, line_2 :Segment) -> Intersection:
	var point_a := line_1.start_point()
	var point_b := line_1.end_point()
	var point_c := line_2.start_point()
	var point_d := line_2.end_point()
	
	var x :float
	var y :float
	
	if point_a.x == point_b.x:
		x = point_a.x
		var p := (x - point_c.x) / point_d.x
		y = lerp(point_c.y, point_d.y, p)
	elif point_c.x == point_d.x:
		x = point_c.x
		var p := (x - point_a.x) / point_b.x
		y = lerp(point_a.y, point_b.y, p)
	else:
		var slope_1 := (point_b.y - point_a.y) / (point_b.x - point_a.x)
		var slope_2 := (point_d.y - point_c.y) / (point_d.x - point_c.x)
		var offset_1 := point_a.y - slope_1 * point_a.x
		var offset_2 := point_c.y - slope_2 * point_c.x
		x = (offset_2 - offset_1) / (slope_1 - slope_2)
		y = slope_1 * x + offset_1
	
	return Intersection.new(line_1.start, line_2.start, Vector2(x,y))


static func get_orientation(points :Array) -> int:
	var min_x := -INF
	var min_y := -INF
	var max_x := INF
	var max_y := INF
	for point in points:
		min_x = min(min_x, point.x)
		min_y = min(min_y, point.y)
		max_x = max(max_x, point.x)
		max_y = max(max_y, point.y)
	if max_y - min_y < max_x - min_x:
		return PORTRAIT
	else:
		return LANDSCAPE


static func colliding_segments(points :Array, segments :Array) -> Array:
	if get_orientation(points) == LANDSCAPE:
		return colliding_segments_landscape(segments)
	return colliding_segments_portrait(segments)


static func colliding_segments_landscape(segments :Array) -> Array:
	var boundaries := []
	for segment in segments:
		boundaries.append(SegmentBoundary.new(
				segment, segment.box.min_x, SegmentBoundary.START))
		boundaries.append(SegmentBoundary.new(
				segment, segment.box.max_x, SegmentBoundary.END))
	boundaries.sort_custom(SegmentBoundary, "sort")
	
	var current_segments := []
	var collisions := []
	var forward_collisions := {}
	var backward_collisions := {}
	for boundary in boundaries:
		var segment := (boundary as SegmentBoundary).segment
		match boundary.type:
			SegmentBoundary.START:
				var i := current_segments.bsearch_custom(
						segment, Segment, "sort_y")
				var candidates := []
				if i < current_segments.size():
					candidates.append(current_segments[i])
				current_segments.insert(i, segment)
				if i > 0:
					candidates.append(current_segments[i-i])
					
				while candidates.size() > 0:
					var previous_segment = candidates.pop_front()
					if overlap(segment.box, previous_segment.box):
						collisions.append([previous_segment, segment])
						dict_append(
								forward_collisions, previous_segment, segment)
						dict_append(
								backward_collisions, segment, previous_segment)
						candidates += forward_collisions.get(
								previous_segment, [])
				
			SegmentBoundary.END:
				var i := current_segments.bsearch_custom(
						boundary.segment,
						Segment,
						"sort_y")
				current_segments.remove(i)
	return collisions


static func dict_append(dict :Dictionary, key, value) -> void:
	if ! dict.has(key):
		dict[key] = []
	dict[key].append(value)


static func colliding_segments_portrait(segments :Array) -> Array:
	var boundaries := []
	for segment in segments:
		boundaries.append(SegmentBoundary.new(
				segment, segment.box.min_y, SegmentBoundary.START))
		boundaries.append(SegmentBoundary.new(
				segment, segment.box.max_y, SegmentBoundary.END))
	boundaries.sort_custom(SegmentBoundary, "sort")
	
	var current_segments := []
	var collisions := []
	var forward_collisions := {}
	var backward_collisions := {}
	for boundary in boundaries:
		var segment := (boundary as SegmentBoundary).segment
		match boundary.type:
			SegmentBoundary.START:
				var i := current_segments.bsearch_custom(
						segment, Segment, "sort_x")
				var candidates := []
				if i < current_segments.size():
					candidates.append(current_segments[i])
				current_segments.insert(i, segment)
				if i > 0:
					candidates.append(current_segments[i-i])
					
				while candidates.size() > 0:
					var previous_segment = candidates.pop_front()
					if overlap(segment.box, previous_segment.box):
						collisions.append([previous_segment, segment])
						dict_append(
								forward_collisions, previous_segment, segment)
						dict_append(
								backward_collisions, segment, previous_segment)
						candidates += forward_collisions.get(
								previous_segment, [])
				
			SegmentBoundary.END:
				var i := current_segments.bsearch_custom(
						boundary.segment,
						Segment,
						"sort_x")
				current_segments.remove(i)
	return collisions


static func overlap(box_a :Box, box_b :Box) -> bool:
	return (box_a.min_x < box_b.max_x
			and box_a.min_y < box_b.max_y
			and box_a.max_x > box_b.min_x
			and box_a.max_y > box_b.min_y)


static func find_segments(points :Array) -> Array:
	var first_direction := direction(points[-1], points[0])
	var previous_direction := first_direction
	var breaks := Array()
	
	for i in points.size() - 1:
		var direction := direction(points[i], points[i + 1])
		if ! directions_are_compatible(previous_direction, direction):
			breaks.append(i)
			previous_direction = direction
		else:
			previous_direction = common_direction(previous_direction, direction)
	if ! directions_are_compatible(previous_direction, first_direction):
		breaks.append(points.size() - 1)
	
	var segments := []
	for i in breaks.size():
		segments.append(Segment.new(
				points,
				breaks[i],
				breaks[wrapi(i,0,breaks.size())]
		))
	return segments


static func direction(start :Vector2, end: Vector2) -> Vector2:
	return Vector2(
			compare(start.x, end.x),
			compare(start.y, end.y))


static func common_direction(a :Vector2, b :Vector2) -> Vector2:
	return Vector2(
			a.x if a.x != 0 else b.x,
			a.y if a.y != 0 else b.y
	)


static func directions_are_compatible(a :Vector2, b :Vector2) -> bool:
	return ! (
			(a.x == 1 and b.x == -1)
			or
			(a.x == -1 and b.x == 1)
			or
			(a.y == 1 and b.y == -1)
			or
			(a.y == -1 and b.y == 1)
	)


static func compare(a :float, b :float) -> int:
	if a < b:
		return 1
	elif a > b:
		return -1
	else:
		return 0


class SegmentBoundary:
	enum {START, END}
	var value :float
	var type :int
	var segment :Segment
	
	
	func _init(_segment :Segment, _value :float, _type :int) -> void:
		value = _value
		type = _type
		segment = _segment
	
	
	static func sort(a :SegmentBoundary, b :SegmentBoundary) -> bool:
		return a.value < b.value


class Segment:
	var _points :Array
	var box :Box
	var start :int
	var end :int
	var length :int
	
	
	func _init(points :Array, from :int, to :int) -> void:
		start = from
		end = to
		_points = points
		box = Box.new(points[from],points[to])
		length = to - from
	
	
	func start_point() -> Vector2:
		return _points[start]
	
	
	func end_point() -> Vector2:
		return _points[end]
	
	
	func split() -> Array:
# warning-ignore:integer_division
		var split_length := length / 2
		return [Segment.new(_points, start, start + split_length),
				Segment.new(_points, start + split_length, end)]
	
	
	func sort_x(a :Segment, b :Segment) -> bool:
		return a.box.min_x < b.box.min_x
	
	
	func sort_y(a :Segment, b :Segment) -> bool:
		return a.box.min_x < b.box.min_x


class Box:
	var min_x :float
	var min_y :float
	var max_x :float
	var max_y :float
	
	
	func _init(corner_a :Vector2, corner_b :Vector2) -> void:
		min_x = min(corner_a.x, corner_b.x)
		min_y = min(corner_a.y, corner_b.y)
		max_x = max(corner_a.x, corner_b.x)
		max_y = max(corner_a.y, corner_b.y)


class Intersection:
	var line_1 :int
	var line_2 :int
	var point :Vector2
	
	
# warning-ignore:shadowed_variable
# warning-ignore:shadowed_variable
# warning-ignore:shadowed_variable
	func _init(line_1 :int, line_2 :int, point :Vector2) -> void:
		self.line_1 = line_1
		self.line_2 = line_2
		self.point = point
