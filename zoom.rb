require_relative "frustrum.rb"

# Position camera to include points or entities.
module Zoom
  # Position camera to include entities.
  #
  # @param entities [Array<Sketchup::DrawingElement>], Sketchup::Entities]
  # @param view [Sketchup::View]
  #
  # @return [void]
  def self.zoom_entities(entities, view = Sketchup.active_model.active_view)
    zoom_points(points(entities), view)
  end

  # Position camera to include points.
  #
  # @param points [Array<Geom::Point3d>]
  # @param view [Sketchup::View]
  #
  # @return [void]
  def self.zoom_points(points, view = Sketchup.active_model.active_view)
    if view.camera.perspective?
      zoom_perspective(points, view)
    else
      zoom_parallel(points, view)
    end
  end

  # Private
  # TODO: Mark as private.

  def self.zoom_parallel(points, view)
    transformation = camera_space(view)

    extremes = extreme_planes(points, view)
    extremes.each { |p| p.each { |c| c.transform!(transformation.inverse) } }

    height = extremes[3][0].y - extremes[2][0].y
    width = extremes[1][0].x - extremes[0][0].x
    eye = Geom::Point3d.new(
      (extremes[0][0].x + extremes[1][0].x) / 2,
      (extremes[2][0].y + extremes[3][0].y) / 2,
      0
    ).transform(transformation)

    view.camera.set(eye, view.camera.direction, view.camera.up)
    set_zoom(view, width, height)
  end

  def self.set_zoom(view, width, height)
    if View.aspect_ratio(view) > width / height
      View.set_height(height, view)
    else
      View.set_width(width, view)
    end
  end

  def self.zoom_perspective(points, view)
    transformation = camera_space(view)

    extremes = extreme_planes(points, view)
    extremes.each { |p| p.each { |c| c.transform!(transformation.inverse) } }

    line_y = Geom.intersect_plane_plane(extremes[0], extremes[1])
    line_x = Geom.intersect_plane_plane(extremes[2], extremes[3])

    eye = Geom::Point3d.new(
      line_y[0].x,
      line_x[0].y,
      [line_x[0].z, line_y[0].z].min
    ).transform(transformation)

    view.camera.set(eye, view.camera.direction, view.camera.up)
  end

  def self.camera_space(view)
    Geom::Transformation.axes(view.camera.eye, view.camera.xaxis,
                              view.camera.yaxis, view.camera.zaxis)
  end

  # Collect all vertex positions in entities.
  #
  # @param entities [Array<Sketchup::DrawingElement>], Sketchup::Entities]
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
    # TODO: Don't list duplicates
  end

  # Find planes with the most extreme point in each direction, perpendicular to
  # frustrum planes.
  #
  # @param points [Array<Geom::Point3d>]
  # @param view [Sketchup::View]
  #
  # @return [Array<(
  #   Array<(Geom::Point3d, Geom::Vector3d)>,
  #   Array<(Geom::Point3d, Geom::Vector3d)>,
  #   Array<(Geom::Point3d, Geom::Vector3d)>,
  #   Array<(Geom::Point3d, Geom::Vector3d)>
  #   )]
  def self.extreme_planes(points, view)
    Frustrum.planes(view).map do |plane|
      transformation = Geom::Transformation.new(*plane).inverse
      point = points.max_by { |pt| pt.transform(transformation).z }

      [point, plane[1]]
    end
  end
end
