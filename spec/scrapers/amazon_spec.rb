require 'spec_helper'

describe ProductScraper::Scrapers::Amazon do
  before(:all) do
    @product_urls = {
      com_full: 'http://www.amazon.com/Full-Acoustic-Guitar-Accessories-Combo/dp/B004HZIR9A/ref=sr_1_1?s=musical-instruments&ie=UTF8&qid=1436652308&sr=1-1&keywords=acoustic+guitar&refinements=p_72%3A1248939011%2Cp_89%3ABest+Choice+Products',
      ca_not_fulfilled: 'http://www.amazon.ca/Omega-212-30-41-20-01-003-Seamaster-Black-Watch/dp/B0072C8SMQ/ref=sr_1_29?s=watch&ie=UTF8&qid=1436690429&sr=1-29',
      ca_price_range_no_ratings: 'http://www.amazon.ca/FABULICIOUS-CLEARLY-430-Womens-Closed-Sandal/dp/B00JEY0EAE/ref=sr_1_36?s=shoes&ie=UTF8&qid=1436695621&sr=1-36',
      ca_without_image: 'http://www.amazon.ca/Vince-Camuto-Womens-Kain-Jean/dp/B00Y3QICZ2/ref=pd_sim_sbs_309_1?ie=UTF8&refRID=0SXVS3Q50BYMAQ6EQWP1',
      in_no_buybox: 'http://www.amazon.in/Idee-Aviator-Sunglasses-Black-S1909/dp/B00O376XTI/ref=sr_1_4?s=apparel&ie=UTF8&qid=1436699589&sr=1-4',
      in_fulfilled: 'http://www.amazon.in/Idee-Aviator-Sunglasses-Gunmetal-S1909/dp/B00O37711M/ref=sr_1_1?s=apparel&ie=UTF8&qid=1436699589&sr=1-1',
      has_video: 'http://www.amazon.com/dp/B00X4WHP5E/ref=cs_va_lb_0?pf_rd_m=ATVPDKIKX0DER&pf_rd_s=desktop-hero-kindle-A&pf_rd_r=03ZSTRPA3RD5B0HXWT73&pf_rd_t=36701&pf_rd_p=2131589782&pf_rd_i=desktop',
      has_unique_desc: 'http://www.amazon.com/dp/B00X4WHP5E/ref=cs_va_lb_0?pf_rd_m=ATVPDKIKX0DER&pf_rd_s=desktop-hero-kindle-A&pf_rd_r=03ZSTRPA3RD5B0HXWT73&pf_rd_t=36701&pf_rd_p=2131589782&pf_rd_i=desktop',
      in_has_more_features: 'http://www.amazon.in/gp/product/B00YSDS1VA?ref_=gb1h_img_c11_7427_18b2d009&smid=AKXO6PTDSQVOC#productDetails'
    }
  end
  it 'can parse Product URLs from Amazon' do
    %w( http://www.amazon.co.uk/SOME-NAME/dp/X000XXXXXX/ref=xxxxxxxxx
        http://www.amazon.in/SOME-NAME/dp/Z333ABCDEF/ref=xxxxxxxxx
        http://www.amazon.co.uk/MKD-child-2255-Golf-Finder-Glasses/dp/B004KXWGJQ/ref=pd_sim_229_8?ie=UTF8&refRID=0BKYY9E8QT7VS8CR78TK
        http://www.amazon.in/Drape-Shantanu-Nikhil-Readymade-SNAMZSAREESL06_Emerald_38/dp/B00T63FFRK/ref=sr_1_3?s=apparel&ie=UTF8&qid=1436591180&sr=1-3
    ).push(@product_urls.values).flatten.each do |url|
      url = URI.parse(url)
      message = "expected #{described_class} to be able to parse #{url}"
      expect(described_class.can_parse?(url)).to be_truthy, message
    end
    %w( http://www.flipkart.com/SOME-NAME/dp/X000XXXXXX/ref=xxxxxxxxx
        http://www.amazon.co.uk/SOME-NAME/ref=xxxxxxxx
        http://www.amazon.in/
    ).each do |url|
      url = URI.parse(url)
      message = "expected #{described_class} not to be able to parse #{url}"
      expect(described_class.can_parse?(url)).to be_falsey, message
    end
  end
  describe '#run' do
    context 'product with full data' do
      before(:context) do
        setup_scraper_and_run_for_kind :amazon, :com_full
      end
      it 'returns a frozen hash with indifferent access' do
        expect(@response).to be_a(HashWithIndifferentAccess)
        expect(@response).to be_frozen
      end
      it 'fetches basic information about the product' do
        expect(@response).to contain_key_pairs(
          uid: 'B004HZIR9A',
          name: 'Full 41" Acoustic Guitar with Guitar Case & More Accessories Combo Kit Guitar Blue',
          priority_service: 'Sold by Amazon',
          available: true,
          brand_name: 'Best Choice Products',
          price: '$69.00'.to_money,
          marked_price: '$124.95'.to_money,
        )
      end
      it 'fetches images for the product' do
        expect(@response).to contain_items([
          'http://ecx.images-amazon.com/images/I/31rQvWo0KyL.jpg',
          'http://ecx.images-amazon.com/images/I/41gEv8fEolL.jpg',
        ]).for_key(:images)
      end
      it 'fetches feature list for the product' do
        expect(@response).to contain_items([
          '41" Full Size Guitar',
          'Hard wood construction',
          'Attractive Blue Finish',
          'Includes, Case, Pick, Extra strings',
          'Brand new in retail packaging',
        ]).for_key(:features)
      end
      it 'fetches description for the product' do
        html = '<div id="productDescription"'
        text = 'This guitar has an attractive blue finish'

        expect(@response[:description][:html]).to include(text)
        expect(@response[:description][:html]).to include(html)

        expect(@response[:description][:text]).to include(text)
        expect(@response[:description][:text]).not_to include(html)

        expect(@response[:description][:markdown]).to include(text)
        expect(@response[:description][:markdown]).not_to include(html)
      end
      it 'fetches ratings for the product' do
        expect(@response[:ratings]).to contain_key_pairs(average: 90, count: 39)
      end
      it 'fetches primary and other relevant categories for the product' do
        expect(@response).to contain_key_pairs(
          primary_category: 'Musical Instruments'
        )
        expect(@response).to contain_items([
          'Musical Instruments', 'Guitars', 'Acoustic Guitars', 'Beginner Kits'
        ]).for_key(:categories)
      end
    end
    it 'fetches information for a product (amazon.ca) not fulfilled by Amazon' do
      setup_scraper_and_run_for_kind :amazon, :ca_not_fulfilled
      expect(@response).to contain_key_pairs(
        uid: 'B0072C8SMQ',
        name: "Omega Men's 212.30.41.20.01.003 Seamaster Black Dial Watch",
        priority_service: false,
        available: true,
        brand_name: 'Omega',
        price: 'CAD 4278.00'.to_money,
        marked_price: 'CAD 5551.04'.to_money,
        primary_category: 'Watches',
        categories: ['Watches', 'Men', 'Wrist Watches'],
        ratings: { 'average' => 88, 'count' => 12 },
        images: [
          'http://ecx.images-amazon.com/images/I/51dpiEHcAoL.jpg',
          'http://ecx.images-amazon.com/images/I/31fExLiRjVL.jpg',
          'http://ecx.images-amazon.com/images/I/41FfUhyWQUL.jpg',
          'http://ecx.images-amazon.com/images/I/31MpUA8mLjL.jpg'
        ], features: [
          'Automatic-self-wind movement',
          'Case diameter: 38 mm',
          'Blackdial watch',
          'Durable sapphire crystal protects watch from scratches,',
          'Water-resistant to 300 M (984 feet)'
        ])
    end
    it 'fetches information for a product with price range and no ratings' do
      setup_scraper_and_run_for_kind :amazon, :ca_price_range_no_ratings
      expect(@response).to contain_key_pairs(
        marked_price: nil,
        uid: 'B00ZQ0NRDQ',
        available: true,
        priority_service: false,
        brand_name: 'Fabulicious',
        price: "CAD 58.98".to_money,
        primary_category: 'Shoes & Handbags',
        name: "Fabulicious Women's Clearly430 Ankle Strap Fashion Pump",
        ratings: { 'average' => 0, 'count' => 0 },
        categories: ['Shoes & Handbags', 'Shoes', 'Women'],
        images: [
          'http://ecx.images-amazon.com/images/I/41p3tfJe7rL.jpg',
          'http://ecx.images-amazon.com/images/I/41p3tfJe7rL.jpg'
        ],
        features: [
          'rubber sole',
          'Platform measures approximately 0.05"',
          'TPU',
          'Imported',
          'Platform measures approximately 0.05""',
          'Closed Back Ankle Strap Sandal'
        ]
      )
    end
    it 'fetches information for a product without an image' do
      setup_scraper_and_run_for_kind :amazon, :ca_without_image
      expect(@response).to contain_key_pairs(
        uid: 'B00LVBHQAE',
        images: []
      )
    end
    it 'fetches information for a product (amazon.in) without a buyBox' do
      setup_scraper_and_run_for_kind :amazon, :in_no_buybox
      expect(@response).to contain_key_pairs(
        marked_price: nil,
        uid: 'B00O376XTI',
        priority_service: false,
        available: true,
        brand_name: 'Idee',
        price: 'INR 2,575.00'.to_money,
        canonical_url: 'http://www.amazon.in/Idee-Aviator-Sunglasses-Black-S1909/dp/B00O376XTI',
        primary_category: 'Clothing & Accessories',
        categories: ['Clothing & Accessories', 'Women', 'Sunglasses & Eyewear Accessories', 'Sunglasses'],
        ratings: { 'average' => 0, 'count' => 0},
        images: [
          'http://ecx.images-amazon.com/images/I/41AzpxTL9mL.jpg',
          'http://ecx.images-amazon.com/images/I/41V9CXxPMdL.jpg',
          'http://ecx.images-amazon.com/images/I/31EI%2BtVxmTL.jpg',
          'http://ecx.images-amazon.com/images/I/41mYjmeJvkL.jpg'
        ], features: [
          'Plastic lens with Metal frame',
          'Lens Type: Gradient',
          'Ideal for: Men. Women',
          'Grey lens with Black  colored frame',
          'Non-Polarized',
          'Eye Width: 57 MM; Nose Bridge: 15 MM; Temple Length: 140 MM',
          '100% UV Protected'
        ]
      )
    end
    it 'fetches information for a product on amazon.in' do
      setup_scraper_and_run_for_kind :amazon, :in_fulfilled
      expect(@response).to contain_key_pairs(
        uid: "B00O37711M",
        brand_name: "Idee",
        available: true,
        priority_service: false,
        price: "INR 2,670.00".to_money,
        marked_price: nil,
        canonical_url: "http://www.amazon.in/Idee-Aviator-Sunglasses-Gunmetal-S1909/dp/B00O37711M",
        primary_category: "Clothing & Accessories",
        categories: ["Clothing & Accessories", "Women", "Sunglasses & Eyewear Accessories", "Sunglasses"],
        ratings: { "average" => 0, "count" => 0},
        images: [
          "http://ecx.images-amazon.com/images/I/31DbGrLMylL.jpg",
          "http://ecx.images-amazon.com/images/I/41cAWFyWV1L.jpg",
          "http://ecx.images-amazon.com/images/I/31EFWBi7oUL.jpg",
          "http://ecx.images-amazon.com/images/I/41umojjysoL.jpg"
        ], features: [
          "Plastic lens with Metal frame",
          "Lens Type: Gradient",
          "Ideal for: Men. Women",
          "Grey lens with Gunmetal  colored frame",
          "Non-Polarized",
          "Eye Width: 57 MM; Nose Bridge: 15 MM; Temple Length: 140 MM",
          "100% UV Protected"
        ]
      )
    end
    it 'fetches information for a product with more features correctly' do
      setup_scraper_and_run_for_kind :amazon, :in_has_more_features
      markdown = "### From the Manufacturer\n\n##### TITANIUM S310"
      expect(@response[:description][:markdown]).to include(markdown)
      expect(@response[:extras]).to contain_key_pairs(can_gift: true)
      expect(@response).not_to contain_items([
        "See more product details"
      ]).for_key(:features)
    end
  end
end
