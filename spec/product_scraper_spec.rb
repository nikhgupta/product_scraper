require 'spec_helper'

describe ProductScraper do
  it 'has a version number' do
    expect(ProductScraper::VERSION).not_to be nil
  end

  it 'defines a root path' do
    expect(ProductScraper.root_path).not_to be_nil
  end

  it 'defines path for a given scraper' do
    path = ProductScraper.scrapers_path('test')
    expect(path).to be_end_with('lib/product_scraper/scrapers/test.rb')
  end

  it 'provides a list of all available scrapers' do
    expect(ProductScraper.available_scrapers).to include(:test)
  end

  it 'loads all available scrapers when requested' do
    ProductScraper.load_scrapers
    expect{ ProductScraper.class_for(:test) }.not_to raise_error
  end

  it 'provides method to scrape data from a given URL' do
    url  = 'http://www.example.com/product-url'
    info = ProductScraper.fetch(url)
    expect(info[:data]).to be_truthy
  end

  it 'has a convenient method to raise custom errors' do
    expect {
      ProductScraper.raise_error!('some error')
    }.to raise_error(ProductScraper::Error).with_message('some error')
  end

  it 'can be passed configuration options' do
    described_class.configure{ @key = :val }
    expect(described_class.instance_variable_get("@key")).to eq :val
    described_class.configure{ |config| config.instance_variable_set "@key", :val2 }
    expect(described_class.instance_variable_get("@key")).to eq :val2
  end

  it "can be configured for custom host matching rules for a scraper" do
    described_class.configure do
      validate(:host, for: :test){ |uri| uri.host =~ /whatever/ }
    end
    scraper = described_class.uuid("http://whatever.com")[:scraper]
    expect(scraper).to eq described_class.class_for(:test)
  end

  it "can be configured for custom product url matching rules for a scraper" do
    described_class.configure do |config|
      config.validate(:product, for: :test){ |uri| uri.path =~ /\d+/ }
    end
    scraper = described_class.uuid("http://whatever.com/test")[:scraper]
    expect(scraper).not_to eq described_class.class_for(:test)
    scraper = described_class.uuid("http://whatever.com/1234")[:scraper]
    expect(scraper).to eq described_class.class_for(:test)
  end

  it "can be configured to create custom unique ids for the scraper" do
    described_class.configure do |config|
      config.unique_id_for(:test){ |uri| Digest::MD5.hexdigest(uri.to_s) }
    end

    url  = "http://whatever.com/12345"
    uuid = described_class.uuid(url)[:uuid]
    expect(uuid).to eq "TEST-#{Digest::MD5.hexdigest(url)}".upcase
  end
end
