$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'vcr'
require 'webmock/rspec'
require 'product_scraper'

# require all spec support files
Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}
RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.include_chain_clauses_in_custom_matcher_descriptions = true
  end
end

VCR.configure do |config|
  config.cassette_library_dir = "spec/cache/vcr"
  config.hook_into :webmock # or :fakeweb
  config.allow_http_connections_when_no_cassette = true
end

# Stub PhantomJS to enable caching - simple VCR like behaviour
# module Capybara::Poltergeist
#   class Browser
#     def visit(url)
#       @current_url = url
#       hash = Digest::MD5.hexdigest url
#       path = File.join(ProductScraper.root_path, "spec", "cache", "phantomjs", "#{hash}.html")
#       if File.exists?(path)
#         command 'visit', "file://#{path}"
#       else
#         command 'visit', url
#         File.open(path, "w"){|f| f.puts source}
#       end
#     end

#     def current_url
#       @current_url
#     end
#   end
# end
