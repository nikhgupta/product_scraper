require 'digest/md5'
module ProductScraper
  class BaseScraper
    include ProductScraper::Helpers

    class << self
      def product(&block)
        metaklass = class << self; self; end
        metaklass.send :define_method, :url_matches?, &block
      end

      def host(&block)
        metaklass = class << self; self; end
        metaklass.send :define_method, :host_matches?, &block
      end

      def set_uuid(&block)
        metaklass = class << self; self; end
        metaklass.send :define_method, :inferred_uuid, &block
      end

      def sanitize(&block)
        metaklass = class << self; self; end
        metaklass.send :define_method, :sanitize_uri, &block
      end

      def sanitize_uri(url);  url; end
      def url_matches?(uri);  nil; end
      def inferred_uuid(uri); nil; end
      def host_matches?(uri); nil; end
      def can_parse?(uri)
        host_matches?(uri) && url_matches?(sanitize_uri uri)
      end
    end

    attr_accessor :url, :options

    def initialize(url, options = {})
      self.url = ProductScraper.uuid(url)[:url]
      self.options = options
    end

    def uuid
      ProductScraper.uuid(url)[:uuid]
    end

    def fetch
      response = { 'scraper' => self.class, 'uuid' => self.uuid }

      get url
      response["response_code"] = page.code.to_i

      %w[pid name priority_service available brand_name price marked_price
      canonical_url primary_category categories ratings images features
      description extras].each do |method|
        value = send(method) if respond_to?(method)
        value = Hash[value.map{|k,v| [k.to_s, v]}] if value.is_a?(Hash)
        response[method] = value
      end
      response
    rescue Mechanize::ResponseCodeError => e
      response["error"] = e.message
      response["response_code"] = e.response_code.to_i
      response
    end

    def primary_category
      categories ? categories.first : nil
    end

    def extras; {}; end
  end
end
