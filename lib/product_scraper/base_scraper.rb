require 'digest/md5'
module ProductScraper
  class BaseScraper
    include ProductScraper::Helpers

    class << self
      def product(uri, &block)
        metaklass = class << self; self; end
        metaklass.send :define_method, :url_matches?, uri, &block
      end

      def host(uri, &block)
        metaklass = class << self; self; end
        metaklass.send :define_method, :host_matches?, uri, &block
      end

      def uuid(uri, &block)
        metaklass = class << self; self; end
        metaklass.send :define_method, :inferred_uuid, uri, &block
      end

      def url_matches?(uri);  nil; end
      def inferred_uuid(uri); nil; end
      def host_matches?(uri); nil; end
    end

    attr_accessor :url, :options

    def initialize(url, options = {})
      self.url = url
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

    def basic_info
      response = all_info
      return {} if response.empty?
      data = {
        name: nil, note: nil,
        pid: response[:uid],
        available: response[:available],
        original_name: response[:name],
        prioritized: !!response[:priority_service],
        merchant: { name: self.class.name.demodulize.underscore },
        url: response[:canonical_url],
        images: response[:images]
      }
      data[:brand] = { name: response[:brand_name] } if response[:brand_name]
      data[:description] = response[:description][:markdown] if response[:description] && response[:description][:markdown]
      data[:price] = response[:price] if response[:price]
      data[:marked_price] = response[:marked_price] if response[:marked_price]
      data[:url_hash] = response[:hash]
      data[:categories] = response[:categories]
      data #.freeze
    end

    def primary_category
      categories ? categories.first : nil
    end

    def extras; {}; end
  end
end
