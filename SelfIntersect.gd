tool
extends Object
class_name SelfIntersect

enum {LANDSCAPE, PORTRAIT, NONE, LEFT, RIGHT, OVERLAP}


static func get_self_intersections(points :Array) -> Array:
	if points.size() < 3:
		return []
	var sections := find_directed_sections(points)
	var overlaps := overlapping_sections(points, sections)
	overlaps = filter_connection_overlaps(points, overlaps)
	var segments = get_overlapping_segments(points, overlaps)
	var intersections = get_intersecting_segments(points, segments)
	return intersections


static func merge_intersections(intersections :Array) -> Array:
	var merged_intersections := intersections
	merged_intersections.sort_custom(SelfIntersect, 'sort_segments_a')
	for i in intersections.size():
		var intersection = intersections[i]
	return merged_intersections


static func sort_segments_a(a :Dictionary, b :Dictionary) -> bool:
	return a.segments_a[0] < b.segments_a[0];


static func get_intersecting_segments(points :Array, overlapping_segments :Array) -> Array:
	var intersections := []
	for segments in overlapping_segments:
		var segment_a := [points[segments[0][0]], points[segments[0][1]]]
		var segment_b := [points[segments[1][0]], points[segments[1][1]]]
		var type := get_intersect_type(segment_a, segment_b)
		if type == NONE:
			continue
		var connecting := bool(
			segments[0][0] == segments[1][1]
			or
			segments[0][1] == segments[1][0]
		)
		if connecting and type != OVERLAP:
			continue
		intersections.append({
			'segments_a': [segments[0][0]],
			'segments_b': [segments[1][0]],
			'type': type,
			'points': get_line_intersection(segment_a, segment_b)
		})
	return intersections


static func get_overlapping_segments(
		points :Array, overlapping_sections :Array
) -> Array:
	var overlapping_segments := []
	var limit := points.size() * points.size()
	while overlapping_sections.size() > 0:
		limit -= 1
		assert(limit > 0)
		var overlap := overlapping_sections.pop_front() as Array
		var section_a := overlap[0] as Array
		var section_b := overlap[1] as Array
		
		var length_a :int
		if section_a[1] > section_a[0]:
			length_a = (section_a[1] - section_a[0])
		else:
			length_a = points.size() + section_a[1] - section_a[0]
			
		var length_b :int
		if section_b[1] > section_b[0]:
			length_b = (section_b[1] - section_b[0])
		else:
			length_b = points.size() + section_b[1] - section_b[0]
		
		if length_a == 1 and length_b == 1:
			overlapping_segments.append([section_a, section_b])
		
		elif length_a > length_b:
# warning-ignore:integer_division
			var split_length := length_a / 2
			var split := wrapi(section_a[0] + split_length, 0, points.size())
			for sub_section in [
				[section_a[0], split],
				[split, section_a[1]]
			]:
				if sections_overlap(points, sub_section, section_b):
					overlapping_sections.append([sub_section, section_b])
		
		else:
# warning-ignore:integer_division
			var split_length := length_b / 2
			var split := wrapi(section_b[0] + split_length, 0, points.size())
			for sub_section in [
				[section_b[0], split],
				[split, section_b[1]]
			]:
				if sections_overlap(points, section_a, sub_section):
					overlapping_sections.append([section_a, sub_section])
			
	return overlapping_segments


static func get_intersect_type(segment_a :Array, segment_b :Array) -> int:
	var a_across_b = segment_crosses_line(segment_a, segment_b)
	if a_across_b == NONE:
		return NONE
	return segment_crosses_line(segment_b, segment_a)


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
	match compare(cross_points(offset_point, offset_end), 0):
		1: 
			return RIGHT
		-1:
			return LEFT
	return OVERLAP


static func cross_points(a :Vector2, b :Vector2) -> float:
	return a.x * b.y - b.x * a.y


static func get_line_intersection(line_1 :Array, line_2 :Array) -> Array:
	var point_a := line_1[0] as Vector2
	var point_b := line_1[1] as Vector2
	var point_c := line_2[0] as Vector2
	var point_d := line_2[1] as Vector2
	
	var x :float
	var y :float
	
	if point_a.x == point_b.x:
		if point_c.x == point_d.x:
			return [
					max_y(min_y(point_a, point_b), min_y(point_c,point_d)),
					min_y(max_y(point_a, point_b), max_y(point_c,point_d))]
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
			return [
					max_x(min_x(point_a, point_b), min_x(point_c,point_d)),
					min_x(max_x(point_a, point_b), max_x(point_c,point_d))]
		var offset_1 := point_a.y - slope_1 * point_a.x
		var offset_2 := point_c.y - slope_2 * point_c.x
		x = (offset_2 - offset_1) / (slope_1 - slope_2)
		y = slope_1 * x + offset_1
	
	return [Vector2(x,y), Vector2(x,y)]


static func min_x(a :Vector2, b :Vector2) -> Vector2:
	if a.x < b.x:
		return a
	return b


static func min_y(a :Vector2, b :Vector2) -> Vector2:
	if a.y < b.y:
		return a
	return b


static func max_x(a :Vector2, b :Vector2) -> Vector2:
	if a.x > b.x:
		return a
	return b


static func max_y(a :Vector2, b :Vector2) -> Vector2:
	if a.y > b.y:
		return a
	return b


static func get_path_orientation(points :Array) -> int:
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


static func filter_connection_overlaps(points :Array, overlaps :Array) -> Array:
	var filtered := []
	for overlap in overlaps:
		if ! sections_overlap_at_connection_only(
				points, overlap[0], overlap[1]
		):
			filtered.append(overlap)
	return filtered


static func overlapping_sections(points :Array, sections :Array) -> Array:
	var orientation = get_path_orientation(points)
	
	var boundaries := []
	var boundary_axis = {
		PORTRAIT: 'y',
		LANDSCAPE: 'x'
	}[orientation]
	for section in sections:
		var box := bounding_box(points[section[0]], points[section[1]])
		boundaries.append(SectionBoundary.new(
				section, box[0][boundary_axis], SectionBoundary.START))
		boundaries.append(SectionBoundary.new(
				section, box[1][boundary_axis], SectionBoundary.END))
	boundaries.sort_custom(SectionBoundary, "sort")
	
	var overlaps := []
	var current_sections := []
	for boundary in boundaries:
		var section := (boundary as SectionBoundary).section
		match boundary.type:
			SectionBoundary.START:
				for other_section in current_sections:
					if sections_overlap(points, section, other_section):
						overlaps.append([other_section, section])
				
				current_sections.append(section)

			SectionBoundary.END:
				current_sections.erase(section)
	return overlaps


static func dict_append(dict :Dictionary, key, value) -> void:
	if ! dict.has(key):
		dict[key] = []
	dict[key].append(value)


static func sections_overlap(
		points :Array, section_a :Array, section_b :Array
) -> bool:
	return overlap(
			bounding_box(points[section_a[0]], points[section_a[1]]),
			bounding_box(points[section_b[0]], points[section_b[1]]))


static func overlap(box_a :Array, box_b :Array) -> bool:
	return (box_a[0].x <= box_b[1].x
			and box_a[0].y <= box_b[1].y
			and box_a[1].x >= box_b[0].x
			and box_a[1].y >= box_b[0].y)


static func sections_overlap_at_connection_only(
	points :Array, section_a :Array, section_b :Array
) -> bool:
	var first :Array
	var second :Array
	if section_a[0] == section_b[1]:
		first = section_b
		second = section_a
	elif section_a[1] == section_b[0]:
		first = section_a
		second = section_b
	else:
		return false
	
	var box_a := bounding_box(points[section_a[0]], points[section_a[1]])
	var box_b := bounding_box(points[section_b[0]], points[section_b[1]])
	
	var overlap_x = (box_a[0].x < box_b[1].x and box_a[1].x > box_b[0].x)
	var overlap_y = (box_a[0].y < box_b[1].y and box_a[1].y > box_b[0].y)
	if overlap_x and overlap_y:
		return false
	
	if overlap_x:
		if (
				points[first[-1] - 1].y
				==
				points[wrapi(second[0] + 1, 0, points.size())].y
		):
			return false
		return true
	elif overlap_y:
		if (
				points[first[-1] - 1].x
				==
				points[wrapi(second[0] + 1, 0, points.size())].x
		):
			return false
		return true
	else:
		return true


static func find_directed_sections(points :Array) -> Array:
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
	
	var sections := []
	for i in breaks.size():
		sections.append([
				breaks[i],
				breaks[wrapi(i+1,0,breaks.size())]
		])
	return sections


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


static func bounding_box(point_a :Vector2, point_b :Vector2) -> Array:
	return [
			Vector2(min(point_a.x, point_b.x), min(point_a.y, point_b.y)),
			Vector2(max(point_a.x, point_b.x), max(point_a.y, point_b.y))]


class SectionBoundary:
	enum {START, END}
	var value :float
	var type :int
	var section :Array
	
	
	func _init(_section :Array, _value :float, _type :int) -> void:
		value = _value
		type = _type
		section = _section
	
	
	static func sort(a :SectionBoundary, b :SectionBoundary) -> bool:
		if a.value == b.value:
			if a.type == START and b.type == END:
				return true
		return a.value < b.value
