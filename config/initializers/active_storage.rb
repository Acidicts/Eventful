# Configure Active Storage image variant processing.
#
# By default Rails will try to use libvips if the `ruby-vips` gem is
# installed, falling back to MiniMagick if it isn't.  On some development
# hosts (including the container used by the test harness) we don't have
# the libvips library available which leads to the "Could not open library
# 'vips.so.42'" error seen above.  Rather than relying on system packages
# we force the processor to MiniMagick which only needs ImageMagick, a
# dependency that's already documented and easier to install.
#
# See also:
#   https://edgeguides.rubyonrails.org/active_storage_overview.html#transforming-images

processor = :mini_magick

# If ImageMagick isn't installed we can try to fall back to vips (which
# may already be available if the ruby-vips gem loaded successfully). This
# avoids the unpredictable 500 errors caused by MiniMagick trying to call
# `convert` when the binary doesn't exist.  If neither backend is present
# we'll keep the default and log a warning so developers can install one of
# the packages.
if processor == :mini_magick
  require "mini_magick"

  # `MiniMagick.which` isn't available in all versions; just shell out.
  has_convert = system("which convert >/dev/null 2>&1") || system("which magick >/dev/null 2>&1")
  unless has_convert
    if defined?(Vips)
      Rails.logger.warn("ImageMagick not found, switching Active Storage variants to vips")
      processor = :vips
    else
      Rails.logger.warn("ImageMagick not found and libvips unavailable; variants will fail until one is installed")
    end
  end
end

Rails.application.config.active_storage.variant_processor = processor
