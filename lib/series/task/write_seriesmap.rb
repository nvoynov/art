require 'json'
require_relative '../config'

module Series
  module Task

    # Write map of series images
    class WriteSeriesMap < Rawww::Task::Base
      
      # @param pages [PagesModel]
      def call(pages)
        content = JSON.pretty_generate(
          series: pages
            .map{ [it.slug, imagemap(it)] }
            .to_h
        )
        filename = File.join(config.www, 'seriesmap.json')
        File.write(filename, content)
      end

      private

      # TODO: add image size and other metadata
      # build images map
      def imagemap(page)
        page.images
          .map{ [File.basename(it).ext('webp'), { foo: 'bar' }] }
          .to_h
      end
    end
    
  end
end
