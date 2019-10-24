require_relative "view.rb"

# Functionality related to the camera frustum.
module Frustum
  # Get planes for camera frustum.
  # Planes are including gray bars if an explicit aspect ratio is set.
  # Order is left, right, bottom and top.
  #
  # @param view [Sketchup::View]
  #
  # @return [Array<(
  #   Array<(Geom::Point3d, Geom::Vector3d)>,
  #   Array<(Geom::Point3d, Geom::Vector3d)>,
  #   Array<(Geom::Point3d, Geom::Vector3d)>,
  #   Array<(Geom::Point3d, Geom::Vector3d)>
  #   )]
  def self.full_planes(view = Sketchup.active_model.active_view)
    if view.camera.perspective?
      perspective_planes(view.camera, View.full_fov_h(view) / 2,
                         View.full_fov_v(view) / 2)
    else
      parallel_planes(view.camera, View.full_height(view) / 2,
                      View.full_width(view) / 2)
    end
  end

  # Get planes for camera frustum.
  # Planes are within gray bars if an explicit aspect ratio is set.
  # Order is left, right, bottom and top.
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
    if view.camera.perspective?
      perspective_planes(view.camera, View.fov_h(view) / 2,
                         View.fov_v(view) / 2)
    else
      parallel_planes(view.camera, View.height(view) / 2, View.width(view) / 2)
    end
  end

  # Private

  def self.perspective_planes(cam, half_fov_h, half_fov_v)
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

  def self.parallel_planes(cam, half_height, half_width)
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
