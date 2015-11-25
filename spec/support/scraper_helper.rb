def setup_scraper_and_run_for_kind provider, url_kind
  VCR.use_cassette("#{provider}_#{url_kind}") do
    @url = @product_urls[url_kind]
    @response = ProductScraper.fetch(@url)
  end
end

def setup_scraper_and_run provider, url
  hash = Digest::MD5.hexdigest(url)
  VCR.use_cassette("#{provider}_other_#{hash}") do
    ProductScraper.fetch(url)
  end
end
