tool
extends Object
class_name SelfIntersect

static func self_intersections(points :PoolVector2Array):
var segments := find_segments(points)
var collisions := []
for i in segments.size():
for j in range(i+1, segments.size():
