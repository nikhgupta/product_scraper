require 'spec_helper'

describe ProductScraper::Scrapers::Flipkart do
  before(:all) do
    @product_urls = {
      full: 'http://www.flipkart.com/moto-e-2nd-gen-4g/p/itme85hfdv6zztcj?pid=MOBE4G6GTH2QDACF&ref=L%3A2097246794469362389&srno=p_2&query=moto+e2&otracker=from-search',
      no_priority_without_desc_rating: 'http://www.flipkart.com/ksbt-born-have-lxs-001-usb-led-light/p/itme9fxqzwvcz4jn?pid=USGE9FXQGXMYFYA4&otracker=hp_mod_electronics_new-arrivals_pos3',
      out_of_stock: 'http://www.flipkart.com/feye-sp151-10000-mah/p/itmeyzkegzvckb2t?pid=PWBEYZKE66JFZ4KM&al=wzE%2FDHe%2FI54QHYgGL7x0%2FcldugMWZuE7JTWSsYnGIuX1JY2K%2FLcSx20%2BCo7nKoJc6uPFy%2F9dSDc%3D&ref=L%3A-1520850878796181824&srno=b_127',
      # without_image: '',
    }
  end
  it 'can parse Product URLs from Amazon' do
    %w( http://flipkart.com/SOME-NAME/p/X000XXXXXX?ref=xxxxxxxxx
        http://www.flipkart.com/SOME-NAME/p/Z333ABCDEFsdada?ref=xxxxxxxxx
    ).push(@product_urls.values).flatten.each do |url|
      url = URI.parse(url)
      message = "expected #{described_class} to be able to parse #{url}"
      expect(described_class.can_parse?(url)).to be_truthy, message
    end
    %w( http://www.amazon.com/SOME-NAME/dp/X000XXXXXX/ref=xxxxxxxxx
        http://amazon.com/SOME-NAME/p/X000XXXXXX?ref=xxxxxxxxx
        http://www.flipkart.com/SOME-NAME?ref=xxxxxxxx
        http://www.flipkart.com/?pid=xxxxxxxx
        http://www.flipkart.com/
    ).each do |url|
      url = URI.parse(url)
      message = "expected #{described_class} not to be able to parse #{url}"
      expect(described_class.can_parse?(url)).to be_falsey, message
    end
  end
  describe '#run' do
    context 'product with full data' do
      before(:context) do
        setup_scraper_and_run_for_kind :flipkart, :full
      end
      it 'returns a frozen hash with indifferent access' do
        expect(@response).to be_a(HashWithIndifferentAccess)
        expect(@response).to be_frozen
      end
      it 'fetches basic information about the product' do
        expect(@response).to contain_key_pairs(
          uid: "MOBE4G6GTH2QDACF",
          name: 'Moto E (2nd Gen) 4G',
          priority_service: true,
          available: true,
          brand_name: 'WS Retail',
          price: 'INR 6999'.to_money,
          marked_price: nil
        )
      end
      it 'fetches images for the product' do
        expect(@response).to contain_items([
          'http://img5a.flixcart.com/image/mobile/a/c/f/motorola-moto-e-2nd-gen-xt1521-original-imae5yvnugydbf9d.jpeg',
          'http://img5a.flixcart.com/image/mobile/a/c/f/motorola-moto-e-2nd-gen-xt1521-original-imae5yvnyrhtdwhh.jpeg',
          'http://img5a.flixcart.com/image/mobile/a/c/f/motorola-moto-e-2nd-gen-xt1521-original-imae5yvnyktamcfk.jpeg',
          'http://img5a.flixcart.com/image/mobile/a/c/f/motorola-moto-e-2nd-gen-xt1521-original-imae5yvndbpuzsex.jpeg',
          'http://img6a.flixcart.com/image/mobile/a/c/f/motorola-moto-e-2nd-gen-xt1521-original-imae5yvnc7zhg9c3.jpeg',
          'http://img6a.flixcart.com/image/mobile/a/c/f/motorola-moto-e-2nd-gen-xt1521-original-imae5yvnuyfhm6fv.jpeg'
        ]).for_key(:images)
      end
      it 'fetches feature list for the product' do
        expect(@response).to contain_items([
          'Android v5.0 (Lollipop) OS',
          '4.5 inch TFT LCD Touchscreen',
          '1.2 GHz Quad Core Processor',
          'Wi-Fi Enabled',
          'Dual Sim (GSM + LTE)',
          'Expandable Storage Capacity of 32 GB',
          '0.3 MP Secondary Camera',
          '5 MP Primary Camera'
        ]).for_key(:features)
      end
      it 'fetches description for the product' do
        html = '<div class="rpdSection" data-ctrl="RichProductDescription">'
        text = 'efficient quad-core processor'
        mark = '### Moto E 2nd Gen'

        expect(@response[:description][:html]).to include(text)
        expect(@response[:description][:html]).to include(html)
        expect(@response[:description][:html]).not_to include(mark)

        expect(@response[:description][:text]).to include(text)
        expect(@response[:description][:text]).not_to include(html)
        expect(@response[:description][:text]).not_to include(mark)

        expect(@response[:description][:markdown]).to include(text)
        expect(@response[:description][:markdown]).to include(mark)
        expect(@response[:description][:markdown]).not_to include(html)
      end
      it 'fetches ratings for the product' do
        expect(@response[:ratings]).to contain_key_pairs(average: 78, count: 1399)
      end
      it 'fetches primary and other relevant categories for the product' do
        expect(@response).to contain_key_pairs(
          primary_category: 'Mobiles & Accessories'
        )
        expect(@response).to contain_items([
          'Mobiles & Accessories', 'Mobiles', 'Motorola Mobiles'
        ]).for_key(:categories)
      end

      it 'fetches specs for the product' do
        zoom = @response[:extras][:specs][:camera][:zoom]
        expect(zoom).to eq("Digital Zoom - 4x")
      end
    end
    it 'fetches information for a product (with desc, rating) not shipped by Flipkart' do
      setup_scraper_and_run_for_kind :flipkart, :no_priority_without_desc_rating
      expect(@response).to contain_key_pairs(
        uid: 'USGE9FXQGXMYFYA4',
        brand_name: 'Appro',
        marked_price: 'INR 249.00'.to_money,
        name: "KSBT Born To Have LXS-001 USB Led Light",
        price: 'INR 99.00'.to_money,
        available: true,
        priority_service: false,
        primary_category: 'Computers',
        features: [],
        ratings: { 'average' => 0, 'count' => 0 },
        categories: ["Computers", "Laptop Accessories", "USB Gadgets", "KSBT USB Gadgets"],
        images: [
          'http://img6a.flixcart.com/image/usb-gadget/y/a/4/lxs-001-ksbt-original-imae8hmyjfxmgebw.jpeg'
        ])
    end
    it 'fetches information for a product which is out of stock' do
      setup_scraper_and_run_for_kind :flipkart, :out_of_stock
      expect(@response).to contain_key_pairs(
        uid: "PWBEYZKE66JFZ4KM",
        brand_name: "pantagonesatellite",
        name: 'FEYE SP151 10000 mAh',
        marked_price: 'INR 4500.00'.to_money,
        price: 'INR 2199.00'.to_money,
        available: false,
        priority_service: false,
        ratings: { 'average' => 0, 'count' => 0 },
        primary_category: nil,
        categories: [],
        features: [
          'Smart LED  Indicator',
          '7 Layer Protection',
          'Dual USB Ports',
          'Smart LED Torch'
        ],
        images: [
          'http://img6a.flixcart.com/image/power-bank/4/k/m/sp151-feye-original-imaeyzgfdzdf5knu.jpeg'
        ])
    end
  end
end
