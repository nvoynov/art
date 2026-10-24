require_relative '../config'

module Studio
  class Vault

    # Studio archive index pages builder
    class IndexPages
      def initialize(archive_items, list_page_dir)
        @archive_items = archive_items
        @list_page_dir = list_page_dir
        @items_per_page = 6
        @config = Rawww::Config.instance
      end

      def build
        total_pages = (@archive_items.size.to_f / @items_per_page).ceil

        (1..total_pages).each do |page|
          start_index = (page - 1) * @items_per_page
          page_items = @archive_items[start_index, @items_per_page]
        
          slug_name = page == 1 ? "vault" : "vault-page-#{page}"
          file_name = page == 1 ? "vault.md" : "vault-page-#{page}.md"
        
          list_content = <<~MARKDOWN
            ---
            title: "Studio Vault — Page #{page}"
            layout: studio
            slug: #{slug_name}
            ---

            # Studio Vault

            ::: {.studio-archive-grid}
          MARKDOWN

          page_items.each do |item|
            image = File.join(@config.site_root, item[:img])
            link  = File.join(@config.site_root, VAULT_URL, item[:slug] + '.html')
            list_content += <<~MARKDOWN
            
              ::: {.archive-preview-card .#{item[:type]}}
              [![#{item[:title]}](#{image})](#{link})
            
              ### [#{item[:title]}](#{link})
              #{item[:desc]}
              :::
            MARKDOWN
          end

          list_content += "\n:::\n\n<div class='studio-pagination'>\n"
        
          if page > 1
            prev_slug = page == 2 ? VAULT_URL : "#{VAULT_URL}-page-#{page - 1}"
            list_content += "[← Previous](/#{prev_slug}.html) "
          end
          if page < total_pages
            list_content += " [Next →](#{VAULT_URL}-page-#{page + 1}.html)"
          end
        
          list_content += "\n</div>\n"

          filepath = File.join(@list_page_dir, file_name)
          File.write(filepath, list_content)
        end
      end
    end
  end
end

