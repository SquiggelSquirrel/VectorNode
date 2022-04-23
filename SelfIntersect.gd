tool
extends Object
class_name SelfIntersect

enum {LANDSCAPE, PORTRAIT, NONE, LEFT, RIGHT, OVERLAP}


static func self_intersections(points :Array) -> Array:
	if points.size() < 3:
		return []
	var segments := find_segments(points)
	var collisions := colliding_segments(points, segments)
	collisions = filter_connection_collisions(collisions)
	var intersections := []
	var iterations := 0
	while collisions.size() > 0:
		iterations += 0
		assert(iterations < 10)
		var pair = collisions.pop_front()
		var a := pair[0] as Segment
		var b := pair[1] as Segment
		if a.length == 1 and b.length == 1:
			if intersect_type(
			[a.start_point(),a.end_point()],
			[b.start_point(),b.end_point()]) != NONE:
				var intersection := Intersection.new(
						a.start, b.start,
						get_intersection(
								[a.start_point(), a.end_point()],
								[b.start_point(), b.end_point()]))
				intersections.append(intersection)
		if a.length > b.length:
			for segment in a.split():
				if overlap(segment.box, b.box):
					collisions.append([segment, b])
		else:
			for segment in b.split():
				if overlap(segment.box, a.box):
					collisions.append([segment, a])
	return intersections


static func intersect_type(a :Array, b :Array) -> int:
	var a_across_b = segment_crosses_line(a,b)
	if a_across_b == NONE:
		return NONE
	return segment_crosses_line(b,a)


static func segment_crosses_line(segment :Array, line :Array) -> int:
	var compare_start := point_line_compare(
			segment[0], line[0], line[1])
	var compare_end := point_line_compare(
			segment[1], line[0], line[1])
	
	if compare_start == OVERLAP and compare_end == OVERLAP:
		return OVERLAP
	if compare_start == compare_end:
		return NONE
	if compare_start == RIGHT or compare_end == LEFT:
		return LEFT
	return RIGHT


static func point_line_compare(
	point :Vector2, start :Vector2, end :Vector2
) -> int:
	var offset_point := point - start
	var offset_end := end - start
	match compare(cross(offset_point, offset_end), 0):
		1: 
			return RIGHT
		-1:
			return LEFT
	return OVERLAP


static func cross(a :Vector2, b :Vector2) -> float:
	return a.x * b.y - b.x * a.y


static func get_intersection(line_1 :Array, line_2 :Array) -> Vector2:
	var point_a := line_1[0] as Vector2
	var point_b := line_1[1] as Vector2
	var point_c := line_2[0] as Vector2
	var point_d := line_2[1] as Vector2
	
	var x :float
	var y :float
	
	if point_a.x == point_b.x:
		if point_c.x == point_d.x:
			return Vector2(NAN, NAN)
		x = point_a.x
		var slope_2 := (point_d.y - point_c.y) / (point_d.x - point_c.x)
		var offset_2 := point_c.y - slope_2 * point_c.x
		y = slope_2 * x + offset_2
	
	elif point_c.x == point_d.x:
		x = point_c.x
		var slope_1 := (point_b.y - point_a.y) / (point_b.x - point_a.x)
		var offset_1 := point_a.y - slope_1 * point_a.x
		y = slope_1 * x + offset_1
	
	else:
		var slope_1 := (point_b.y - point_a.y) / (point_b.x - point_a.x)
		var slope_2 := (point_d.y - point_c.y) / (point_d.x - point_c.x)
		if slope_1 == slope_2:
			return Vector2(NAN, NAN)
		var offset_1 := point_a.y - slope_1 * point_a.x
		var offset_2 := point_c.y - slope_2 * point_c.x
		x = (offset_2 - offset_1) / (slope_1 - slope_2)
		y = slope_1 * x + offset_1
	
	return Vector2(x,y)


static func get_orientation(points :Array) -> int:
	var min_x := INF
	var min_y := INF
	var max_x := -INF
	var max_y := -INF
	for point in points:
		min_x = min(min_x, point.x)
		min_y = min(min_y, point.y)
		max_x = max(max_x, point.x)
		max_y = max(max_y, point.y)
	if abs(max_y - min_y) > abs(max_x - min_x):
		return PORTRAIT
	else:
		return LANDSCAPE


static func filter_connection_collisions(collisions :Array) -> Array:
	var filtered := []
	for collision in collisions:
		if ! segments_overlap_at_connection_only(
				collision[0], collision[1]
		):
			filtered.append(collision)
	return filtered


static func colliding_segments(points :Array, segments :Array) -> Array:
	if get_orientation(points) == LANDSCAPE:
		return colliding_segments_landscape(segments)
	return colliding_segments_portrait(segments)


static func colliding_segments_landscape(segments :Array) -> Array:
	var boundaries := []
	for segment in segments:
		boundaries.append(SegmentBoundary.new(
				segment, segment.box[0].x, SegmentBoundary.START))
		boundaries.append(SegmentBoundary.new(
				segment, segment.box[1].x, SegmentBoundary.END))
	boundaries.sort_custom(SegmentBoundary, "sort")
	
	var collisions := []
	var current_segments := []
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
				
				for j in range(i + 1, current_segments.size()):
					var previous_segment = current_segments[j]
					if overlap(segment.box, previous_segment.box):
						collisions.append([previous_segment, segment])
					else:
						break
				
				for j in range(i - 1, -1, -1):
					var previous_segment = current_segments[j]
					if overlap(segment.box, previous_segment.box):
						collisions.append([previous_segment, segment])
					else:
						break

			SegmentBoundary.END:
				var i := current_segments.bsearch_custom(
						segment, Segment, "sort_y")
				i = current_segments.find(segment, i)
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
				segment, segment.box[0].y, SegmentBoundary.START))
		boundaries.append(SegmentBoundary.new(
				segment, segment.box[1].y, SegmentBoundary.END))
	boundaries.sort_custom(SegmentBoundary, "sort")
	
	var collisions := []
	var current_segments := []
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
				
				for j in range(i + 1, current_segments.size()):
					var previous_segment = current_segments[j]
					if overlap(segment.box, previous_segment.box):
						collisions.append([previous_segment, segment])
					else:
						break
				
				for j in range(i - 1, -1, -1):
					var previous_segment = current_segments[j]
					if overlap(segment.box, previous_segment.box):
						collisions.append([previous_segment, segment])
					else:
						break

			SegmentBoundary.END:
				var i := current_segments.bsearch_custom(
						boundary.segment,
						Segment,
						"sort_x")
				i = current_segments.find(segment, i)
				current_segments.remove(i)
	return collisions


static func overlap(box_a :Array, box_b :Array) -> bool:
	return (box_a[0].x <= box_b[1].x
			and box_a[0].y <= box_b[1].y
			and box_a[1].x >= box_b[0].x
			and box_a[1].y >= box_b[0].y)


static func segments_overlap_at_connection_only(
	segment_a :Segment, segment_b :Segment
) -> bool:
	var points := segment_a._points
	if segment_b._points != points:
		return false
	
	var first :Segment
	var second :Segment
	if segment_a.start == segment_b.end:
		first = segment_b
		second = segment_a
	elif segment_a.end == segment_b.start:
		first = segment_a
		second = segment_b
	else:
		return false
	
	var overlap_x = (segment_a.box[0].x < segment_b.box[1].x
			and segment_a.box[1].x > segment_b.box[0].x)
	var overlap_y = (segment_a.box[0].y < segment_b.box[1].y
			and segment_a.box[1].y > segment_b.box[0].y)
	if overlap_x and overlap_y:
		return false
	
	if overlap_x:
		if points[first.end - 1].y == points[second.start + 1].y:
			return false
		return true
	elif overlap_y:
		if points[first.end - 1].x == points[second.start + 1].x:
			return false
		return true
	else:
		return true


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
				breaks[wrapi(i+1,0,breaks.size())]
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
		if a.value == b.value:
			if a.type == START and b.type == END:
				return true
		return a.value < b.value


class Segment:
	var _points :Array
	var box :Array
	var start :int
	var end :int
	var length :int
	
	
	func _init(points :Array, from :int, to :int) -> void:
		start = from
		end = to
		_points = points
		box = [
			Vector2(min(points[from].x, points[to].x),
					min(points[from].y, points[to].y)),
			Vector2(max(points[from].x, points[to].x),
					max(points[from].y, points[to].y))]
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
	
	
	static func sort_x(a :Segment, b :Segment) -> bool:
		return a.box[0].x < b.box[0].x
	
	
	static func sort_y(a :Segment, b :Segment) -> bool:
		return a.box[0].y < b.box[0].y


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
