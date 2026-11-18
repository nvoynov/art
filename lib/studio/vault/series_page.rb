module Studio
  class Vault
    
    # Studio archive series page builder
    class SeriesPage
      attr_reader :title, :slug, :img_url, :desc

      def initialize(series_name, options, formats, gallery, output_dir)
        @series_name = series_name
        @options = options
        @formats = formats
        @gallery = gallery
        @output_dir = output_dir

        @slug = series_name.downcase  # "#{VAULT_URL}/#{series_name.downcase}"
        @title = "Series: #{series_name.capitalize}"
        
        image_ids = options.first['image_ids'] || []
        @img_url = image_ids.first ? gallery[image_ids.first] : ""
        @desc = "Limited edition portfolio containing #{image_ids.size} prints."
        @config = Rawww::Config.instance
      end

      def build
        image_ids = @options.first['image_ids'] || []

        md_content = <<~MARKDOWN
          ---
          title: "#{@title}"
          layout: studio
          slug: #{@slug}
          ---
          
          ::: {.studio-series-container}
          
          ::: {.studio-series-left}
          ### Series Content (#{image_ids.size} prints):
          
          <div class="series-vertical-gallery">
        MARKDOWN

        image_ids.each do |id|
          image_path  = @gallery[id]
          image = 
             if image_path 
               File.join(@config.site_root, image_path)
             else
               id
             end

          md_content += "  ![#{id}](#{image})\n\n"
        end

        md_content += <<~MARKDOWN
          </div>
          :::
          
          ::: {.studio-series-right}
          # #{@title}
          
          Limited archival print series, curated as a single conceptual collection.
          
          [Format Reference](#{STUDIO_URL}/formats.html) | [Paper Guide](#{STUDIO_URL}/papers.html)
          
          ### Editions and configuration:
        MARKDOWN

        @options.each do |opt|
          fmt = @formats[opt['format']] || {}
          md_content += <<~MARKDOWN
            - **Edition #{opt['edition']}**
              - Number of prints: #{image_ids.size}
              - Paper stock: #{opt['paper']}
              - Series format: #{fmt['name'] || opt['format']}
              - sheet size: #{fmt['sheet_size'] || 'N/A'}
              - image size: #{fmt['image_size'] || 'N/A'}
              - **Total series price: $#{opt['price']}**
            ---
          MARKDOWN
        end

        md_content += <<~MARKDOWN
          
          [Place order by Email](#{STUDIO_URL}/order.html?type=series&id=#{@series_name}){.order-button}
          :::
          
          :::
        MARKDOWN

        # TODO: maybe not name but name and edition
        # puts File.join(@output_dir, "#{@series_name.downcase}.md"), @slug; exit
        File.write(File.join(@output_dir, "#{@series_name.downcase}.md"), md_content)
      end
    end
  end
end
