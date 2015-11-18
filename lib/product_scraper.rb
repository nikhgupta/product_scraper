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

  def self.new(url, options = {})
    scraper = can_parse?(url)
    raise Error, "Merchant not implemented." if scraper.nil?
    scraper.new(url, options)
  end

  def self.url_hash_for(url)
    scraper = can_parse?(url)
    scraper ? scraper.url_hash_for(url) : nil
  end

  def self.can_parse?(url)
    uri = URI.parse(url) rescue nil
    raise_error! "URL to scrape is invalid" unless uri
    uri = URI.parse("http://#{uri}") if uri.scheme.nil?

    available_scrapers.map do |scraper|
      class_for(scraper)
    end.detect do |scraper|
      scraper.can_parse?(uri)
    end
  end

  def self.fetch_info(url, options = {})
    new(url, options).all_info
  end

  def self.fetch_basic_info(url, options = {})
    new(url, options).basic_info
  end

  def self.raise_error!(message)
    raise ProductScraper::Error, message
  end
end

ProductScraper.load_scrapers
