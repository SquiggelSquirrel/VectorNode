# VectorNode
Create shapes with fill/stroke from Node2D control points

Note: As of 1.7.0 I recommend using with the Bit Flags Editor plugin: https://github.com/SquiggelSquirrel/BitFlagEditor

## VectorPath
- Defines the path to fill/stroke
- Add VectorPoint nodes for each point on the path
- Emits the `shape_changed` signal when the path changes
- Emits the `stroke_data_changed` signal when the stroke widths and/or colors change
- Sets the default bake interval for the shape
- Has editor-preview-only color settings for handle-in, handle-out and path
- Uses VectorPoint to define stroke widths & colors, and specific bake intervals
- Can define an array of tag name strings (only for editor UI purposes), for use with VectorPoint "tags" bitmask

## VectorPoint
- Defines a single point in a vector path
- Use as child of VectorPath or VectorPointGroup
- Add VectorHandle nodes to define the vector in/out
- Can specify a stroke width and/or color
  - (will only apply to VectorStroke nodes with `use_data_nodes_width` or `use_data_nodes_color` set
- Can specify a bake interval for outgoing edge
  - When set to 0.0, use default value specified on VectorPath node
- Supports different handle types:
  - NONE: no handles
  - IN: one handle, defines vector in only
  - OUT: one handle, defines vector out only
  - BOTH: two handles, first defines vector in, second defines vector out
  - MIRROR IN: one handle, defines vector in. Vector out is reflection of vector in
  - MIRROR OUT: one handle, defines vector out. Vector in is reflection of vector out
  - IN OUT: one handle, defines vector in and vector out as same vector
- Points and handles use position relative to VectorPath, so rotating/scaling a VectorPoint can change the handle position
- Has an integer bitmask of tags, which can be used by fill and stroke to filter for different sub-paths

## VectorHandle
- Defines vector in/out for a VectorPoint (see above)
- Has an integer bitmask of tags, which can be used by fill and stroke to filter for different sub-paths

## VectorControl
- Abstract class defining shared behaviour of VectorPoint and VectorHandle

## VectorPointGroup
- Use as child of VectorPath or another VectorPointGroup
- Usually contains one or more VectorPoints and/or other VectorPointGroups
- Allows one or more VectorPoints to be moved, rotated, and/or scaled together

## VectorFill
- Fills a VectorPath
- Set `path_node_path` to the NodePath of the VectorPath
- Call `update_fill` to update
- Commonly you would connect the VectorPath `shape_changed` signal to the `update_fill` method
- Has an integer mask (normally I would only set one bit) to specify which VectorControls to use

## VectorStroke
- Strokes a VectorPath
- Set `path_node_path` to the NodePath of the VectorPath
- Call `update_shape` to update the shape
- Call `update_data` to update stroke widths and/or colors:
  - (only if using `use_data_nodes_width` or `use_data_nodes_color`)
- Extends Line2D, so also accepts textures, etc.
- Can stroke part of a path - use start/end to define start and end points
  - These accept negative values and wrap
  - These also now accept floating values, and will interpolate along the path between points
- Has `start_pinch length` and `end_pinch_length`, interpolate the width to 0.0 towards the start/end
  - Lengths are defined as fraction of total stroke length
- Has `use_close_fix`, attempts to work around the fact that Line2D cannot be closed by creating
  a small overlap when the stroke is closed
- Commonly you would connect the VectorPath `shape_changed` signal to the `update_shape` method
- If using width/color, connect `stroke_data_changed` to `update_data` for automatic updates
- Has an integer mask (normally I would only set one bit) to specify which VectorControls to use

## VectorCollisionPolygon
- Creates a collision polygon from a VectorPath
- Almost identical to VectorFill
- Call `upadate_polygon` to update
- Connect `shape_changed` to `update_polygon` for automatic updates
