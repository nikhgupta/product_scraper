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

  it 'provides method to scraper data from a given URL' do
    url  = 'http://www.example.com/product-url'
    info = ProductScraper.fetch_info(url)
    expect(info[:data]).to be_truthy
  end

  it 'has a convenient method to raise custom errors' do
    expect {
      ProductScraper.raise_error!('some error')
    }.to raise_error(ProductScraper::Error).with_message('some error')
  end
end
