require_relative '../config'
require_relative '../model'
require_relative '../decor'

module Series
  module Task

    # Write Pages
    class WritePage < Rawww::Task::Base
      PRESENTER = Flatplan::Medium::Web::Presenter
      
      # @param pages [PagesModel]
      def call(page)
        path_modifier = {
          dir: File.join(config.site_root, page.assets_dir, 'thumb'),
          ext: '.webp'
        }
        og_image = File.join(page.assets_dir, 'og_image.png')
        
        presenter = PRESENTER.new(path_modifier:, og_image:, og_type: 'article')
        content = presenter.serialize(page) + ?\n
        content << LIGHTBOX % {root: config.site_root }
        filepath = File.join(config.raw, SERIES_DIR, "#{page.slug}.md")
        File.write(filepath, content)
      end
      
      LIGHTBOX = <<~HTML
        <script src="%{root}/assets/js/lightbox.js" defer></script>
      HTML

    end
    
  end
end

