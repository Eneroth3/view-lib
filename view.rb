# TODO: Move to community lib?

# View and Camera related functionality.
module View
  # Get view's vertical field of view in degrees. Honors any explicitly set
  # aspect ratio.
  #
  # @param view [Sketchup::View]
  #
  # @return [Float]
  def self.fov_v(view = Sketchup.active_model.active_view)
    return view.camera.fov if view.camera.fov_is_height?

    frustrum_ratio(view.camera.fov, 1 / current_aspect_ratio(view))
  end

  # Get view's horizontal field of view in degrees. Honors any explicitly set
  # aspect ratio.
  #
  # @param view [Sketchup::View]
  #
  # @return [Float]
  def self.fov_h(view = Sketchup.active_model.active_view)
    return view.camera.fov unless view.camera.fov_is_height?

    frustrum_ratio(view.camera.fov, current_aspect_ratio(view))
  end

  # Get the view's vertical field of view in degrees, including the area covered
  # by any bars if there is an explicitly set aspect ratio.
  #
  # @param view [Sketchup::View]
  #
  # @return [Float]
  def self.full_fov_v(view = Sketchup.active_model.active_view)
    # Cap aspect ratio ratio when bars should not be taken into account.
    frustrum_ratio(fov_v(view), [aspect_ratio_ratio(view), 1].max)
  end

  # Get the view's horisontal field of view in degrees, including the area covered
  # by any bars if there is an explicitly set aspect ratio.
  #
  # @param view [Sketchup::View]
  #
  # @return [Float]
  def self.full_fov_h(view = Sketchup.active_model.active_view)
    # Cap aspect ratio ratio when bars should not be taken into account.
    frustrum_ratio(fov_h(view), [1 / aspect_ratio_ratio(view), 1].max)
  end

  # Set aspect ratio by covering parts of the screen with gray bars.
  # Sets the aspect ratio without visually changing the projection on screen.
  #
  # @param aspect_ratio [Float]
  # @param view [Sketchup::View]
  #
  # @returns [void]
  def self.set_aspect_ratio(aspect_ratio, view = Sketchup.active_model.active_view)
    # Get current look
    # Set new aspect ratio
    # Adapt fov to visually match
    
    old_aspect_ratio = current_aspect_ratio
    # have full_fov_v and full_fov_h getters?
    # have full_fov_v and full_fov_h setters?
    
    # Is height or width going to change?
    # In some cases both change!
  end

  # Reset aspect ratio and remove gray bars from view.
  #
  # @param view [Sketchup::View]
  #
  # @returns [void]
  def self.reset_aspect_ratio(view = Sketchup.active_model.active_view)
    set_aspect_ratio(0, view)
  end

  def self.frustrum_planes

  end

  # Get aspect ratio of viewport.
  #
  # @param view [Sketchup::View]
  #
  # @return [Float]
  def self.vp_aspect_ratio(view = Sketchup.active_model.active_view)
    view.vpwidth / view.vpheight.to_f
  end

  # Get the aspect ratio of the view. If an aspect ratio is explicitly set, this
  # ratio is returned.
  #
  # @param view [Sketchup::View]
  #
  # @return [Float]
  def self.current_aspect_ratio(view = Sketchup.active_model.active_view)
    return view.camera.aspect_ratio unless view.camera.aspect_ratio == 0

    vp_aspect_ratio(view)
  end

  # Get ratio between the explicit aspect ratio and the viewport aspect ratio.
  # When the gray aspect ratio bars are horizontal, this value is larger than 1
  # and when they are vertical this value is smaller than 1.
  #
  # @param view [Sketchup::View]
  #
  # @return [Float]
  def self.aspect_ratio_ratio(view = Sketchup.active_model.active_view)
    current_aspect_ratio(view) / vp_aspect_ratio(view)
  end

  # Private

  # Utility method for finding one frustrum angle based on the other and the
  # ratio between.
  #
  # @param angle [Float] Angle in degrees.
  # @param [Float]
  #
  # @return [Angle] Angle in degrees.
  def self.frustrum_ratio(angle, ratio)
    Math.atan(Math.tan(angle.degrees / 2) * ratio).radians * 2
  end
  private_class_method :frustrum_ratio
end
