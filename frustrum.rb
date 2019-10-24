require_relative "view.rb"

# Functionality related to the camera frustrum.
module Frustrum
  # Get planes for camera frustrum. Order is left, right, bottom and top.
  # Planes are within gray bars if an explicit aspect ratio is set.
  #
  # @param view [Sketchup::View]
  #
  # @return [Array<(
  #   Array<(Geom::Point3d, Geom::Vector3d)>,
  #   Array<(Geom::Point3d, Geom::Vector3d)>,
  #   Array<(Geom::Point3d, Geom::Vector3d)>,
  #   Array<(Geom::Point3d, Geom::Vector3d)>
  #   )]
  def self.planes(view = Sketchup.active_model.active_view)
    view.camera.perspective? ? perspective_planes(view) : parallel_planes(view)
  end

  # Private

  def self.perspective_planes(view)
    cam = view.camera
    half_fov_h = View.fov_h(view) / 2
    half_fov_v = View.fov_v(view) / 2
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

  def self.parallel_planes(view)
    cam = view.camera
    half_width = View.width(view) / 2
    half_height = View.height(view) / 2
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
