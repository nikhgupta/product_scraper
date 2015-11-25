# ProductScraper

Scraper to fetch product information for various merchants online, like
Amazon, Flipkart, Snapdeal, etc. Aimed for an Indian startup, this repo
will incline towards Indian merchants, initially, but with a little
community support, we should be able to support many merchants
internationally.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'product_scraper'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install product_scraper

## Usage

To get information about a product, use `fetch`:

    ProductScraper.fetch 'http://www.amazon.com/gp/product/B00KC6I06S/'

#### Unique IDs

Sometimes, its useful to check (without making external requests) the
unique identifier for a given product url to know if we should fetch
information for the product or we already have it in our database. Most
of the times, this will be the product ID of the product on the given
merchant's website (namespaced).

To get the unique ID for a given product URL, use `uuid`:

    ProductScraper.uuid 'http://www.amazon.com/gp/product/B00KC6I06S/'
    # => { uuid: "AMAZON-B00KC6I06S", scraper: ProductScraper::Scrapers::Amazon }
    
    ProductScraper.uuid 'http://www.amazon.com'
    # => { scrapers: [ProductScraper::Scrapers::Amazon], reason: :not_a_product}

Possible return value for these reasons can be:

    :invalid_url     # non existent or malformed URL
    :not_implemented # No merchant has been configured for this URL
    :not_a_product   # Merchant found, but URL is not a product
    :error           # An error was encountered. More info in `error` key.

Therefore, this method can, also, be used to check if the scraper can
support a given URL or not.

#### Configuring Rules for Scrapers

Each scraper has its own set of rules, which dictate what domains it can
scrape on, and what URLs on that domain constitute a valid product URL.
You can change these rules as per your own use-case:

    ProductScraper.configure do
      config.validate :host, for: :amazon do |uri|
        uri.host =~ /\A(?:|www\.)amazon\.in\z/
      end

      config.validate :product, for: :amazon do |uri|
        uri.path =~ /(gp|dp)\/product\//
      end

      # Prefix Unique ID for Amazon with Host domain's TLD, thereby,
      # distinguishing between products from Amazon Canada and Amazon
      # India.
      config.unique_id_for :amazon do |uri|
        tld = uri.host.gsub(/^(?:|www\.)amazon\.(.+)/, '\1')
        uid = uri.path.match(%r{/(?:dp|gp/product)/(.*?)(?:/|$)})
        "#{tld}-#{uid[1]}"
      end
    end

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `rake rspec` to run the tests. You can also run `bin/console`
for an interactive prompt that will allow you to experiment. Run `bundle
exec product_scraper` to use the gem in this directory, ignoring other
installed copies of this gem.

To install this gem onto your local machine, run `bundle exec rake
install`. To release a new version, update the version number in
`version.rb`, and then run `bundle exec rake release`, which will create
a git tag for the version, push git commits and tags, and push the
`.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/[USERNAME]/product_scraper.
