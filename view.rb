# View and Camera related functionality.
#
# Wraps much of SketchUp's internal complexity, such as field of view
# sometimes being measured vertically and sometimes horizontally, and handling
# of explicit vs implicit aspect ratios.
module View
  # Get the aspect ratio.
  # If an aspect ratio is explicitly set, return it. Otherwise return viewport
  # aspect ratio.
  #
  # @param view [Sketchup::View]
  #
  # @return [Float]
  def self.aspect_ratio(view = Sketchup.active_model.active_view)
    return view.camera.aspect_ratio unless view.camera.aspect_ratio.zero?

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
    aspect_ratio(view) / vp_aspect_ratio(view)
  end

  # Check if view has an explicitly set aspect ratio, or if it is implicitly
  # taken from the viewport ratio. When explicitly set gray bars covers the
  # remaining sections of the viewport.
  #
  # @param view [Sketchup::View]
  #
  # @return [Float]
  def self.explicit_aspect_ratio?(view = Sketchup.active_model.active_view)
    view.camera.aspect_ratio != 0
  end

  # Get the horizontal field of view.
  # Angle measured within gray bars if an explicit aspect ratio is set.
  #
  # @param view [Sketchup::View]
  #
  # @return [Float] Angle in degrees.
  def self.fov_h(view = Sketchup.active_model.active_view)
    return view.camera.fov unless view.camera.fov_is_height?

    frustrum_ratio(view.camera.fov, aspect_ratio(view))
  end

  # Get the vertical field of view.
  # Angle measured within gray bars if an explicit aspect ratio is set.
  #
  # @param view [Sketchup::View]
  #
  # @return [Float] Angle in degrees.
  def self.fov_v(view = Sketchup.active_model.active_view)
    return view.camera.fov if view.camera.fov_is_height?

    frustrum_ratio(view.camera.fov, 1 / aspect_ratio(view))
  end

  # Get the horizontal field of view.
  # Angle measured including gray bars if an explicit aspect ratio is set.
  #
  # @param view [Sketchup::View]
  #
  # @return [Float] Angle in degrees.
  def self.full_fov_h(view = Sketchup.active_model.active_view)
    # Cap aspect ratio ratio when bars should not be taken into account.
    frustrum_ratio(fov_h(view), [1 / aspect_ratio_ratio(view), 1].max)
  end

  # Get the vertical field of view.
  # Angle measured including gray bars if an explicit aspect ratio is set.
  #
  # @param view [Sketchup::View]
  #
  # @return [Float] Angle in degrees.
  def self.full_fov_v(view = Sketchup.active_model.active_view)
    # Cap aspect ratio ratio when bars should not be taken into account.
    frustrum_ratio(fov_v(view), [aspect_ratio_ratio(view), 1].max)
  end

  # Get the height of a parallel projection camera.
  # Length measured including gray bars if an explicit aspect ratio is set.
  #
  # @param view [Sketchup::View]
  #
  # @return [Length]
  def self.full_height(view = Sketchup.active_model.active_view)
    view.camera.height.to_l
  end

  # Get the width of a parallel projection camera.
  # Length measured including gray bars if an explicit aspect ratio is set.
  #
  # @param view [Sketchup::View]
  #
  # @return [Length]
  def self.full_width(view = Sketchup.active_model.active_view)
    (full_height(view) * vp_aspect_ratio(view)).to_l
  end

  # Get the height of a parallel projection camera.
  # Length measured within gray bars if an explicit aspect ratio is set.
  #
  # @param view [Sketchup::View]
  #
  # @return [Length]
  def self.height(view = Sketchup.active_model.active_view)
    (full_height(view) / [1, aspect_ratio_ratio(view)].max).to_l
  end

  # Reset aspect ratio and remove gray bars from view.
  #
  # @param view [Sketchup::View]
  #
  # @return [void]
  def self.reset_aspect_ratio(view = Sketchup.active_model.active_view)
    set_aspect_ratio(0, view)
  end

  # Set aspect ratio by covering parts of the view with gray bars.
  # Sets the aspect ratio without visually changing the projection on screen.
  #
  # @param aspect_ratio [Float]
  # @param view [Sketchup::View]
  #
  # @return [void]
  def self.set_aspect_ratio(aspect_ratio,
                            view = Sketchup.active_model.active_view)
    fov = full_fov_v(view) if view.camera.perspective?
    view.camera.aspect_ratio = aspect_ratio
    set_full_fov_v(fov, view) if view.camera.perspective?
  end

  # Set the horizontal field of view.
  # Angle measured within gray bars if an explicit aspect ratio is set.
  #
  # @param fov [Float] Angle in degrees
  # @param view [Sketchup::View]
  #
  # @return [void]
  def self.set_fov_h(fov, view = Sketchup.active_model.active_view)
    view.camera.fov =
      if view.camera.fov_is_height?
        frustrum_ratio(fov, 1 / aspect_ratio)
      else
        fov
      end
  end

  # Set the vertical field of view.
  # Angle measured within gray bars if an explicit aspect ratio is set.
  #
  # @param fov [Float] Angle in degrees.
  # @param view [Sketchup::View]
  #
  # @return [void]
  def self.set_fov_v(fov, view = Sketchup.active_model.active_view)
    view.camera.fov =
      if view.camera.fov_is_height?
        fov
      else
        frustrum_ratio(fov, aspect_ratio)
      end
  end

  # Set the horizontal field of view.
  # Angle measured including gray bars if an explicit aspect ratio is set.
  #
  # @param fov [Float] Angle in degrees.
  # @param view [Sketchup::View]
  #
  # @return [void]
  def self.set_full_fov_h(fov, view = Sketchup.active_model.active_view)
    # Cap aspect ratio ratio when bars should not be taken into account.
    set_fov_h(frustrum_ratio(fov, [aspect_ratio_ratio(view), 1].min), view)
  end

  # Set the vertical field of view.
  # Angle measured including gray bars if an explicit aspect ratio is set.
  #
  # @param fov [Float] Angle in degrees.
  # @param view [Sketchup::View]
  #
  # @return [void]
  def self.set_full_fov_v(fov, view = Sketchup.active_model.active_view)
    # Cap aspect ratio ratio when bars should not be taken into account.
    set_fov_v(frustrum_ratio(fov, [1 / aspect_ratio_ratio(view), 1].min), view)
  end

  # Set the height of a parallel projection camera.
  # Length measured including gray bars if an explicit aspect ratio is set.
  #
  # @param height [Length]
  # @param view [Sketchup::View]
  #
  # @return [void]
  def self.set_full_height(height, view = Sketchup.active_model.active_view)
    view.camera.height = height
  end

  # Set the width of a parallel projection camera.
  # Length measured including gray bars if an explicit aspect ratio is set.
  #
  # @param width [Length]
  # @param view [Sketchup::View]
  #
  # @return [void]
  def self.set_full_width(width, view = Sketchup.active_model.active_view)
    set_full_height(width / vp_aspect_ratio, view)
  end

  # Set the height of a parallel projection camera.
  # Length measured within gray bars if an explicit aspect ratio is set.
  #
  # @param height [Length]
  # @param view [Sketchup::View]
  #
  # @return [void]
  def self.set_height(height, view = Sketchup.active_model.active_view)
    set_full_height(height * [aspect_ratio_ratio(view), 1].max, view)
  end

  # Set the width of a parallel projection camera.
  # Length measured within gray bars if an explicit aspect ratio is set.
  #
  # @param width [Length]
  # @param view [Sketchup::View]
  #
  # @return [void]
  def self.set_width(width, view = Sketchup.active_model.active_view)
    set_full_width(width * [1 / aspect_ratio_ratio(view), 1].max, view)
  end

  # Get aspect ratio of viewport.
  #
  # @param view [Sketchup::View]
  #
  # @return [Float]
  def self.vp_aspect_ratio(view = Sketchup.active_model.active_view)
    view.vpwidth / view.vpheight.to_f
  end

  # Get the width of a parallel projection camera.
  # Length measured within gray bars if an explicit aspect ratio is set.
  #
  # @param view [Sketchup::View]
  #
  # @return [Length]
  def self.width(view = Sketchup.active_model.active_view)
    (full_width(view) / [1, 1 / aspect_ratio_ratio(view)].max).to_l
  end

  # Private

  # Utility method for finding one frustrum angle based on the other and the
  # ratio between.
  #
  # @param angle [Float] Angle in degrees.
  #
  # @return [Angle] Angle in degrees.
  def self.frustrum_ratio(angle, ratio)
    Math.atan(Math.tan(angle.degrees / 2) * ratio).radians * 2
  end
  private_class_method :frustrum_ratio
end
