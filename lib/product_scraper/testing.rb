require 'digest/md5'

module ProductScraper
  class << self

    def use_cassettes!(path)
      @casettes_path = path
    end

    def fetch(url, options = {})
      with_replay(url) do
        scraper = new(url, options)
        scraper ? scraper.fetch : nil
      end
    end

    private

    def with_replay(url)
      VCR.use_cassette(cassette_file_for(url)) { yield }
    end

    def cassette_file_for(url)
      hash = Digest::MD5.hexdigest url
      File.join(@casettes_path.to_s, hash)
    end
  end
end
