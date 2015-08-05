require 'digest/md5'

module ProductScraper
  class << self

    def use_cassettes!(path)
      @casettes_path = path
    end

    def fetch_info(url, options = {})
      with_replay(url) { new(url, options).all_info }
    end

    def fetch_basic_info(url, options = {})
      with_replay(url) { new(url, options).basic_info }
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
