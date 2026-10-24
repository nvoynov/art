require 'fileutils'
require_relative 'vault/print_page'
require_relative 'vault/series_page'
require_relative 'vault/index_pages'

module Studio
  
  # Studio Vault Builder
  class Vault
    def initialize(inventory_data, gallery, src_dir = 'src')
      @inventory = inventory_data
      @gallery = gallery
      @src_dir = src_dir
      
      @formats = @inventory['formats'] || {}
      @prints = @inventory['prints'] || {}
      @series = @inventory['series'] || {}
      
      @output_dir = File.join(src_dir, 'studio', 'vault')
      @list_page_dir = File.join(src_dir, 'studio')
      
      FileUtils.mkdir_p(@output_dir)
    end

    def call
      archive_items = []

      # Loop and build each print unit atomically
      @prints.each do |image_id, options|
        page = PrintPage.new(image_id, options, @formats, @gallery, @output_dir)
        page.build
        archive_items << { title: page.title, slug: page.slug, img: page.img_url, type: :print, desc: page.desc }
      end

      # Loop and build each series unit atomically
      @series.each do |series_name, options|
        page = SeriesPage.new(series_name, options, @formats, @gallery, @output_dir)
        page.build
        archive_items << { title: page.title, slug: page.slug, img: page.img_url, type: :series, desc: page.desc }
      end

      # Build paginated indexes using accumulated structural metadata
      index_builder = IndexPages.new(archive_items, @list_page_dir)
      index_builder.build
    end
  end
end
