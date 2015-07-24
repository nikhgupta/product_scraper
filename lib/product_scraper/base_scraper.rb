module ProductScraper
  class BaseScraper
    include ProductScraper::Helpers

    # By default, reject all URLs for scraping purposes.
    def self.can_parse?(uri); false; end

    attr_accessor :url, :options

    def initialize(url, options = {})
      self.url = url
      self.options = options
    end

    def run
      get url
      response = HashWithIndifferentAccess.new
      return response unless page && page.body

      %w[ uid name priority_service available brand_name price marked_price
       canonical_url primary_category categories ratings images features
      description extras ].each do |field|
        method = "extract_#{field}"
        value = send(method) if respond_to?(method)
        value = HashWithIndifferentAccess.new(value) if value.is_a?(Hash)
        response[field] = value # unless value.nil?
      end
      response.freeze
    end
    alias :all_info :run

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
        images: response[:images].map do |image|
          { url: image.gsub(/.*\/I\/(.*?)\._.*_\..*/, '\1') }
        end
      }
      data[:brand] = { name: response[:brand_name] } if response[:brand_name]
      data[:description] = response[:description][:markdown] if response[:description] && response[:description][:markdown]
      data[:price] = response[:price] if response[:price]
      data[:marked_price] = response[:marked_price] if response[:marked_price]
      data.freeze
    end

    def extract_primary_category
      extract_categories.first
    end

    def extract_extras; {}; end
  end
end