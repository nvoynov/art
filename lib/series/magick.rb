require_relative 'config'

module Series

  class Magick < ::Basic::CliTool
    # Declaratively register the ImageMagick 7 binary executable
    executable :magick

    # Converts the source TIFF image to a full-size production WebP asset
    #
    # @param source [String] absolute or relative path to the source .tif file
    # @param destination [String] target output path for the compiled _full.webp
    # @param quality [Integer] WebP compression quality factor (0-100)
    def convert_to_full(source, destination, quality: FULL_IMG_QUALITY)
      args = [
        source,
        "-colorspace", "sRGB",
        "-quality", quality.to_s,
        destination
      ]
      execute_command(*args)
    end

    # Converts the source TIFF image to a scaled thumbnail WebP asset preserving aspect ratio
    #
    # @param source [String] absolute or relative path to the source .tif file
    # @param destination [String] target output path for the compiled _thumb.webp
    # @param max_side [Integer] maximum bounding box dimension in pixels
    # @param quality [Integer] WebP compression quality factor (0-100)
    def convert_to_thumb(source, destination, max_side: 450, quality: THUMB_IMG_QUALITY)
      args = [
        source,
        "-colorspace", "sRGB",
        "-resize", "#{max_side}x#{max_side}>", # Scales down only if image is larger than bounding box
        "-quality", quality.to_s,
        destination
      ]
      execute_command(*args)
    end

    def make_png(source, target)
      tmp_png = "tmp.png"
      system("rsvg-convert -w 1200 -h 630 #{source} -o #{tmp_png}")
      system("magick #{tmp_png} \\( #{WATERMARK} -negate \\) -gravity south -geometry +0+40 -composite #{target}")
      FileUtils.rm_f(tmp_png)
    end

    def make_series_png(target, text)
      tmp_svg = "tmp.svg"
      svg_content = File.read(SERIES_OG)
      modified_svg = svg_content.gsub("SERIES TITLE", text)
      File.write(tmp_svg, modified_svg)
      make_png(tmp_svg, target)
      FileUtils.rm_f(tmp_svg)
    end

  end
end

