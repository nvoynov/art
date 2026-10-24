# frozen_string_literal: true

require_relative '../config'

module Series
  module Model

    # Flatplan Pages collection
    class Pages
      attr_reader :pages

      def initialize(pages)
        @pages = pages
      end
    end
  end
end
