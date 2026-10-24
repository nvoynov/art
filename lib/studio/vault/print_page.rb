require_relative '../config'

module Studio
  class Vault

    # Print Page Builder
    class PrintPage
      attr_reader :title, :slug, :img_url, :desc

      def initialize(image_id, options, formats, gallery, output_dir)
        @image_id = image_id
        @options = options
        @formats = formats
        @gallery = gallery
        @output_dir = output_dir

        # prepare metadata for future index
        @slug = "#{VAULT_URL}/#{image_id.downcase}"
        @title = "Untitled #{image_id.upcase}"
        @img_url = gallery[image_id]
        @desc = "Archival single print. Available paper options: #{options.size}."
      end

      # Create studio archive print page
      def build
        md_content = <<~MARKDOWN
          ---
          title: "#{@title}"
          layout: studio
          slug: #{@slug}
          ---
          
          ::: {.studio-print-container}
          
          ::: {.studio-print-left}
          ![#{@title}](#{@img_url})
          :::
          
          ::: {.studio-print-right}
          # #{@title}
          
          Archival fine art print from the studio archive collection.
          
          [Format Reference](#{STUDIO_URL}/formats.html) | [Paper Guide](#{STUDIO_URL}/papers.html)
          
          ### Available physical copies:
        MARKDOWN

        @options.each do |opt|
          fmt = @formats[opt['format']] || {}
          md_content += <<~MARKDOWN
            - **#{opt['paper']}**
              - sheet size: #{fmt['sheet_size'] || 'N/A'}
              - image size: #{fmt['image_size'] || 'N/A'}
              - **$#{opt['price']}**
            ---
          MARKDOWN
        end

        md_content += <<~MARKDOWN
          
          [Place order by Email](#{STUDIO_URL}/order.html?type=print&id=#{@image_id}){.order-button}
          :::
          
          :::
        MARKDOWN

        File.write(File.join(@output_dir, "#{@image_id.downcase}.md"), md_content)
      end
    end
  end
end
