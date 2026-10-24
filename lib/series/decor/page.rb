require 'delegate'

module Series
  module Decor

    # Flatplan Page decorator
    class Page < SimpleDelegator
      attr_reader :filepath
      
      def initialize(master, filepath)
        @filepath = filepath
        super(master)
      end
      
      # Page considered hidden when it has no text_narrative
      def hidden? = text_narrative.empty?

      # @return [Array<String>] images filepaths
      def images
        @images ||= all_media_assets.map(&:filepath)
      end

      def latest_media_asset
        all_media_assets.map(&:captured_at).max
      end

      def assets_dir
        @assets_dir = File.join(IMAGES_DIR, slug)
      end
    end
  end
end
