# Only used inside RSpec tests.
module ProductScraper
  module Scrapers
    class Test < ProductScraper::BaseScraper

      product { |uri| true }
      host    { |uri| uri.host =~ /\A(?:|www\.)example\.com\z/ }

      def fetch
        { data: true }
      end
    end
  end
end

