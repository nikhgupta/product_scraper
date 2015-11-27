require 'mechanize'
require 'active_support/inflector'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/hash_with_indifferent_access'
require 'sanitize'
require 'monetize'
require 'reverse_markdown'
require 'product_scraper/version'
require 'product_scraper/helpers'
require 'product_scraper/base_scraper'

module ProductScraper
  class Error < StandardError; end

  def self.root_path
    File.dirname(File.dirname(__FILE__))
  end

  def self.scrapers_path(scraper = nil)
    dir = File.join(root_path, "lib", "product_scraper", "scrapers")
    scraper ? File.join(dir, "#{scraper}.rb") : dir
  end

  def self.available_scrapers
    Dir.glob(scrapers_path('*')).map{ |f| File.basename(f, ".rb").to_sym }
  end

  def self.load_scrapers
    available_scrapers.each{ |scraper| load scrapers_path(scraper) }
  end

  def self.class_for(scraper)
    ProductScraper::Scrapers.const_get(scraper.to_s.camelize)
  end

  def self.raise_error!(message)
    raise ProductScraper::Error, message
  end

  def self.configure(&block)
    raise Error, "must provide a block" unless block_given?
    block.arity.zero? ? instance_eval(&block) : yield(self)
  end

  class << self
    def configure(&block)
      raise Error, "must provide a block" unless block_given?
      block.arity.zero? ? instance_eval(&block) : yield(self)
    end

    def validate(key, options, &block)
      klass = class_for(options[:for]) rescue nil
      klass.send(key, &block) if klass
    end

    def unique_id_for(scraper, &block)
      klass = class_for(scraper) rescue nil
      klass.send(:set_uuid, &block) if klass
    end

    def sanitize_url_for(scraper, &block)
      klass = class_for(scraper) rescue nil
      klass.send(:sanitize, &block) if klass
    end

    def fetch(url, options = {})
      new(url, options).fetch
    end

    def new(url, options = {})
      info = uuid(url)
      info[:scraper].new(url, options) unless info[:uuid].to_s.empty?
    end

    def uuid(url)
      uri = URI.parse(URI.encode(url)) rescue url
      uri = URI.parse("http://#{uri}") if uri.scheme.nil?

      scrapers = available_scrapers.map do |scraper|
        class_for(scraper)
      end.select do |scraper|
        scraper.host_matches?(scraper.sanitize_uri(uri))
      end

      tmp_uri = nil
      scraper = scrapers.detect do |scraper|
        tmp_uri = scraper.sanitize_uri(uri)
        scraper.url_matches?(tmp_uri)
      end

      unique_id = (scraper.inferred_uuid(tmp_uri) rescue nil) if scraper
      unique_id = Digest::MD5.hexdigest(uri.path) if unique_id.to_s.empty?
      unique_id = "#{scraper.to_s.demodulize.parameterize}-#{unique_id}"

      case
      when scraper then { uuid: unique_id.upcase, scraper: scraper, url: tmp_uri.to_s }
      when scrapers.any? then { scrapers: scrapers, reason: :not_a_product }
      else { reason: :not_implemented }
      end
    rescue URI::InvalidURIError, ProductScraper::Error => e
      { reason: :error, error: { class: e.class, message: e.message }}
    end
  end
end

ProductScraper.load_scrapers
