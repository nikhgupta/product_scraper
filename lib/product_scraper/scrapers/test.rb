# Only used inside RSpec tests.
module ProductScraper
  module Scrapers
    class Test < ProductScraper::BaseScraper
      def self.can_parse?(uri)
        uri.host =~ /\A(?:|www\.)example\.com\z/
      end

      def all_info
        { data: true }
      end
      alias :run :all_info
    end
  end
end

