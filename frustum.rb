require_relative "view.rb"

# Functionality related to the camera frustum.
module Frustum
  # Get planes for camera frustum.
  # Planes are within gray bars if an explicit aspect ratio is set.
  # Order is left, right, bottom and top.
  #
  # @param view [Sketchup::View]
  # @param full [Boolean] Whether planes should be including or within gray bars
  #   if an explicit aspect ratio is set.
  # @param padding [Numeric] How many percent of frustum should be left blank on
  #   each side.
  #
  # @return [Array<(
  #   Array<(Geom::Point3d, Geom::Vector3d)>,
  #   Array<(Geom::Point3d, Geom::Vector3d)>,
  #   Array<(Geom::Point3d, Geom::Vector3d)>,
  #   Array<(Geom::Point3d, Geom::Vector3d)>
  #   )]
  def self.planes(view = Sketchup.active_model.active_view, full: false,
                  padding: 0)
    raise ArgumentError, "Padding must be smaller than 50%" if padding >= 50

    if view.camera.perspective?
      perspective_planes(view, full, padding)
    else
      parallel_planes(view, full, padding)
    end
  end

  # Private

  def self.perspective_planes(view, full, padding)
    cam = view.camera
    half_fov_h = (full ? View.full_fov_h(view) : View.fov_h(view)) / 2
    half_fov_v = (full ? View.full_fov_v(view) : View.fov_v(view)) / 2
    half_fov_h *= (1 - padding / 50.0)
    half_fov_v *= (1 - padding / 50.0)

    [
      # xaxis = right.
      [cam.eye, rotate_vector(cam.xaxis.reverse, cam.eye, cam.up, half_fov_h)],
      [cam.eye, rotate_vector(cam.xaxis, cam.eye, cam.up, -half_fov_h)],
      [cam.eye, rotate_vector(cam.up.reverse, cam.eye, cam.xaxis, -half_fov_v)],
      [cam.eye, rotate_vector(cam.up, cam.eye, cam.xaxis, half_fov_v)]
    ]
  end
  private_class_method :perspective_planes

  def self.rotate_vector(vector, point, axis, angle)
    vector.transform(Geom::Transformation.rotation(point, axis, angle.degrees))
  end
  private_class_method :rotate_vector

  def self.parallel_planes(view, full, padding)
    cam = view.camera
    half_height = (full ? View.full_height(view) : View.height(view)) / 2
    half_width = (full ? View.full_width(view) : View.width(view)) / 2
    half_height /= (1 - padding / 50.0)
    half_width /= (1 - padding / 50.0)

    [
      # xaxis = right.
      [cam.eye.offset(cam.xaxis, -half_width), cam.xaxis.reverse],
      [cam.eye.offset(cam.xaxis, half_width), cam.xaxis],
      [cam.eye.offset(cam.up, -half_height), cam.up.reverse],
      [cam.eye.offset(cam.up, half_height), cam.up]
    ]
  end
  private_class_method :parallel_planes
end
