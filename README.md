# VectorNode
Create shapes with fill/stroke from Node2D control points

## VectorPath
- Defines the path to fill/stroke, along with stroke widths & colors
- Add VectorPoint nodes for each point on the path
- Emits the `shape_changed` signal when the path changes
- Emits the `stroke_data_changed` signal when the stroke widths and/or colors change

## VectorPoint
- Defines a single point in a vector path
- Use as child of VectorPath
- Add VectorHandle nodes to define the vector in/out
- Can specify a stroke width and/or color
  - (will only apply to VectorStroke nodes with `use_data_nodes_width` or `use_data_nodes_color` set
- Supports different handle types:
  - NONE: no handles
  - IN: one handle, defines vector in only
  - OUT: one handle, defines vector out only
  - BOTH: two handles, first defines vector in, second defines vector out
  - MIRROR IN: one handle, defines vector in. Vector out is reflection of vector in
  - MIRROR OUT: one handle, defines vector out. Vector in is reflection of vector out
  - IN OUT: one handle, defines vector in and vector out as same vector
- Points and handles use position relative to VectorPath, so rotating/scaling a VectorPoint can change the handle position

## VectorHandle
- Defines vector in/out for a VectorPoint (see above)

## VectorControl
- Abstract class defining shared behaviour of VectorPoint and VectorHandle

## VectorFill
- Fills a VectorPath
- Set `path_node_path` to the NodePath of the VectorPath
- Call `update_fill` to update
- Commonly you would connect the VectorPath `shape_changed` signal to the `update_fill` method

## VectorStroke
- Strokes a VectorPath
- Set `path_node_path` to the NodePath of the VectorPath
- Call `update_shape` to update the shape
- Call `update_data` to update stroke widths and/or colors:
  - (only if using `use_data_nodes_width` or `use_data_nodes_color`)
- Extends Line2D, so also accepts textures, etc.
- Can stroke part of a path - use start/end to define start and end points
  - These accept negative values and wrap
- Commonly you would connect the VectorPath `shape_changed` signal to the `update_shape` method
- If using width/color, connect `stroke_data_changed` to `update_data` for automatic updates

## VectorCollisionPolygon
- Creates a collision polygon from a VectorPath
- Call `upadate_polygon` to update
- Connect `shape_changed` to `update_polygon` for automatic updates
