# frozen_string_literal: true

require_relative '../basic'
require_relative '../rawww'
require_relative '../../../flatplan/lib/flatplan'

# Series Constants
module Series
  extend ::Basic::AliasMembers

  FLATPLAN_CONFIG = Flatplan::Config.instance

  SERIES_DIR = 'series'
  IMAGES_DIR = File.join('assets', SERIES_DIR)

  OG_IMAGE  = 'og_image.png'
  WATERMARK = File.expand_path('assets/compiled-watermark-inverted.png')
  SERIES_OG = File.expand_path('assets/og_series.svg')
   
  FULL_IMG_QUALITY  = 85
  THUMB_IMG_QUALITY = 80
end
