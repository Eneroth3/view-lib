require_relative "frustum.rb"

# Position camera to include points or entities.
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
  #
  # @example
  #   // Zoom extents
  #   Zoom.zoom_entities(Sketchup.active_model.entities)
  #
  #   // Zoom selection
  #   Zoom.zoom_entities(Sketchup.active_model.selection)
  #
  # @return [void]
  def self.zoom_entities(entities, view = Sketchup.active_model.active_view,
                         padding: 2.5)
    entities = [entities] unless entities.respond_to?(:each)
    zoom_points(points(entities), view, padding: padding)
  end

  # Position camera to include points.
  #
  # @param points [Array<Geom::Point3d>]
  # @param view [Sketchup::View]
  # @param padding [Numeric] How many percent of view should be left blank on
  #   each side.
  #
  # @return [void]
  def self.zoom_points(points, view = Sketchup.active_model.active_view,
                       padding: 2.5)
    raise ArgumentError, "Padding must be smaller than 50%" if padding >= 50
    return if points.empty?

    if view.camera.perspective?
      zoom_perspective(points, view, padding)
    else
      zoom_parallel(points, view, padding)
    end
  end

  # Private

  def self.zoom_parallel(points, view, padding)
    transformation = camera_space(view)

    extremes = extreme_planes(points, view, padding)
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
    set_zoom(view, width, height)
  end
  private_class_method :zoom_parallel

  def self.set_zoom(view, width, height)
    if View.aspect_ratio(view) > width / height
      View.set_height(height, view)
    else
      View.set_width(width, view)
    end
  end
  private_class_method :set_zoom

  def self.zoom_perspective(points, view, padding)
    transformation = camera_space(view)

    extremes = extreme_planes(points, view, padding)
    extremes.map! { |pl| pl.map { |c| c.transform(transformation.inverse) } }

    line_y = Geom.intersect_plane_plane(extremes[0], extremes[1])
    line_x = Geom.intersect_plane_plane(extremes[2], extremes[3])

    eye = Geom::Point3d.new(
      line_y[0].x,
      line_x[0].y,
      [line_x[0].z, line_y[0].z].min
    ).transform(transformation)

    view.camera.set(eye, view.camera.direction, view.camera.up)
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
  #
  # @return [Array<(
  #   Array<(Geom::Point3d, Geom::Vector3d)>,
  #   Array<(Geom::Point3d, Geom::Vector3d)>,
  #   Array<(Geom::Point3d, Geom::Vector3d)>,
  #   Array<(Geom::Point3d, Geom::Vector3d)>
  #   )]
  def self.extreme_planes(points, view, padding)
    Frustum.planes(view, padding: padding).map do |plane|
      transformation = Geom::Transformation.new(*plane).inverse
      point = points.max_by { |pt| pt.transform(transformation).z }

      [point, plane[1]]
    end
  end
  private_class_method :extreme_planes
end
