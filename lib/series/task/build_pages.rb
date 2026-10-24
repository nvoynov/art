require_relative '../config'
require_relative '../model'
require_relative '../decor'

module Series
  module Task

    # Build Pages collection
    class BuildPages < Rawww::Task::Base
      def call
        flatplan = Flatplan::Config.instance
        pattern = File.join(flatplan.stories_dir, '*.md')
        builder = Flatplan::ReadCommand.web
        
        Dir[pattern]
          .map{[it, builder.(it)]}
          .map{|file, page| PageDecor.new(page, file) }
          .then{ PagesModel.new(it) }
      end
    end
    
  end
end


Series::Task::BuildPages.().pages.flat_map(&:title).tap{ pp it } \
  if __FILE__ == $0
