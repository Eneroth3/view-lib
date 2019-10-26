require_relative "frustum.rb"

# Position camera to include points or entities. As the camera isn't rotated
# objects can appear asymmetrically placed in perspective views, especially if
# reaching deep into the view.
#
# In perspective projection this zoom is not identical to SketchUp's native one.
# This version contains everything within the padding while SketchUp's version
# lets the far side of an object stick outside of it.
# https://forums.sketchup.com/t/view-camera-wrapper/107261/6
module Zoom
  # Position camera to include entities.
  #
  # @param entities [Array<Sketchup::Drawingelement>], Sketchup::Entities,
  #   Sketchup::Selection, Sketchup::Drawingelement]
  # @param view [Sketchup::View]
  # @param padding [Numeric] How many percent of view should be left blank on
  #   each side.
  # @param full [Boolean] Fit content to full view, including gray bars if
  #   aspect ratio is set.
  #
  # @example
  #   // Zoom extents
  #   Zoom.zoom_entities(Sketchup.active_model.entities)
  #
  #   // Zoom selection
  #   Zoom.zoom_entities(Sketchup.active_model.selection)
  #
  #   // Zoom extents and adapt aspect ratio
  #   View.set_aspect_ratio(Zoom.zoom_entities(Sketchup.active_model.entities,
  #                         padding: 0, full: true))
  #
  # @return [Float] Aspect ratio.
  def self.zoom_entities(entities, view = Sketchup.active_model.active_view,
                         padding: 2.5, full: false)
    entities = [entities] unless entities.respond_to?(:each)
    zoom_points(points(entities), view, padding: padding, full: full)
  end

  # Position camera to include points.
  #
  # @param points [Array<Geom::Point3d>]
  # @param view [Sketchup::View]
  # @param padding [Numeric] How many percent of view should be left blank on
  #   each side.
  # @param full [Boolean] Fit content to full view, including gray bars if
  #   aspect ratio is set.
  #
  # @return [Float] Aspect ratio.
  def self.zoom_points(points, view = Sketchup.active_model.active_view,
                       padding: 2.5, full: false)
    raise ArgumentError, "Padding must be smaller than 50%" if padding >= 50
    return if points.empty?

    if view.camera.perspective?
      zoom_perspective(points, view, padding, full)
    else
      zoom_parallel(points, view, padding, full)
    end
  end

  # Private

  def self.zoom_parallel(points, view, padding, full)
    transformation = camera_space(view)

    extremes = extreme_planes(points, view, padding, full)
    extremes.map! { |pl| pl.map { |c| c.transform(transformation.inverse) } }

    # Honor padding. Even if included when creating the frustum it is lost
    # when finding the extreme points.
    height = (extremes[3][0].y - extremes[2][0].y) / (1 - padding / 50.0)
    width = (extremes[1][0].x - extremes[0][0].x) / (1 - padding / 50.0)
    eye = Geom::Point3d.new(
      (extremes[0][0].x + extremes[1][0].x) / 2,
      (extremes[2][0].y + extremes[3][0].y) / 2,
      0
    ).transform(transformation)

    view.camera.set(eye, view.camera.direction, view.camera.up)
    set_zoom(view, width, height, full)

    width / height
  end
  private_class_method :zoom_parallel

  def self.set_zoom(view, width, height, full)
    aspect_ratio = full ? View.vp_aspect_ratio(view) : View.aspect_ratio(view)
    if aspect_ratio > width / height
      View.set_height(height, view)
    else
      View.set_width(width, view)
    end
  end
  private_class_method :set_zoom

  def self.zoom_perspective(points, view, padding, full)
    transformation = camera_space(view)

    extremes = extreme_planes(points, view, padding, full)
    extremes.map! { |pl| pl.map { |c| c.transform(transformation.inverse) } }

    line_y = Geom.intersect_plane_plane(extremes[0], extremes[1])
    line_x = Geom.intersect_plane_plane(extremes[2], extremes[3])

    eye = Geom::Point3d.new(
      line_y[0].x,
      line_x[0].y,
      [line_x[0].z, line_y[0].z].min
    ).transform(transformation)

    view.camera.set(eye, view.camera.direction, view.camera.up)

    bb = Geom::BoundingBox.new
    bb.add(points.map { |pt| view.screen_coords(pt) })
    width = [(bb.max.x - view.center.x).abs, (bb.min.x - view.center.x).abs].max
    height =
      [(bb.max.y - view.center.y).abs, (bb.min.y - view.center.y).abs].max

    width / height
  end
  private_class_method :zoom_perspective

  def self.camera_space(view)
    Geom::Transformation.axes(view.camera.eye, view.camera.xaxis,
                              view.camera.yaxis, view.camera.zaxis)
  end
  private_class_method :camera_space

  # Collect all vertex positions in entities.
  #
  # @param entities [Array<Sketchup::DrawingElement>], Sketchup::Entities,
  #   Sketchup::Selection]
  # @param transformation [Geom::Transformation]
  #
  # @return [Array<Geom::Point3d>]
  def self.points(entities, transformation = IDENTITY)
    entities.flat_map do |entity|
      case entity
      when Sketchup::Edge, Sketchup::Face
        entity.vertices.map { |v| v.position.transform(transformation) }
      when Sketchup::Group, Sketchup::ComponentInstance
        points(entity.definition.entities,
               transformation * entity.transformation)
      end
    end.compact
  end
  private_class_method :points

  # Find planes with the most extreme point in each direction, perpendicular to
  # frustum planes.
  #
  # @param points [Array<Geom::Point3d>]
  # @param view [Sketchup::View]
  # @param padding [Numeric]
  # @param full [Boolean]
  #
  # @return [Array<(
  #   Array<(Geom::Point3d, Geom::Vector3d)>,
  #   Array<(Geom::Point3d, Geom::Vector3d)>,
  #   Array<(Geom::Point3d, Geom::Vector3d)>,
  #   Array<(Geom::Point3d, Geom::Vector3d)>
  #   )]
  def self.extreme_planes(points, view, padding, full)
    Frustum.planes(view, padding: padding, full: full).map do |plane|
      transformation = Geom::Transformation.new(*plane).inverse
      point = points.max_by { |pt| pt.transform(transformation).z }

      [point, plane[1]]
    end
  end
  private_class_method :extreme_planes
end
