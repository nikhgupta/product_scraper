# Only used inside RSpec tests.
module ProductScraper
  module Scrapers
    class Test < ProductScraper::BaseScraper

      product -> (uri) { true }
      host -> (uri) { uri.host =~ /\A(?:|www\.)example\.com\z/ }

      def all_info
        { data: true }
      end
      alias :run :all_info
    end
  end
end

