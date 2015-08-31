module ProductScraper
  module Scrapers
    class Amazon < ProductScraper::BaseScraper

      def self.can_parse?(uri)
        return false unless uri.host =~ /\A(?:|www\.)amazon\.((?:[a-z]+\.?)+)\z/
        uri.path =~ /\/(dp|gp\/product)\/[A-Z0-9]{10}/
      end

      def self.normalize(uri)
        match = uri.path.match(%r{/(?:dp|gp/product)/(.*?)(?:/|$)})
        match ? match[1] : nil
      end

      def extract_uid
        attribute_for '#addToCart #ASIN', 'value'
      end

      def extract_name
        text_for('#productTitle') || text_for("#heroImage #title")
      end

      def extract_priority_service
        return "Sold by Amazon" if has_text?("Ships from and sold by Amazon.com")
        return "Fulfilled by Amazon" if has_link?("Fulfilled by Amazon")
        return false
      end

      def extract_available
        selector = '[data-feature-name="availability"]'
        return true unless has_css?(selector)
        text  = text_for(selector).downcase
        unavailable_regex = /(out of stock|unavailable)/
        !(text =~ unavailable_regex)
      end

      def extract_brand_name
        text_for('#brand') if has_css?('#brand')
      end

      def extract_price
        if has_css?('#unqualifiedBuyBox')
          selector = '#unqualifiedBuyBox .a-color-price'
        else
          selector = '#price .a-size-medium.a-color-price:not(.a-text-strike)'
        end
        __extract_currency(selector)
      end

      def extract_marked_price
        __extract_currency('#price .a-text-strike')
      end

      def extract_canonical_url
        attribute_for('link[rel="canonical"]', :href) ||
          "#{@page.uri.scheme}://#{@page.uri.host}/gp/product/#{extract_uid}"
      end

      def extract_features
        sanitize_text_lines_of '[data-feature-name="featurebullets"] li'
      end

      def extract_images
        thumbs = attribute_for("#altImages img", :src, all: true)
        thumbs = thumbs.map{|a| a.gsub(/\._(.*?)\d+\_\./, '.')}
        no_image = thumbs.count == 1 && thumbs[0] =~ /\/no-img-.*?\.gif$/
        no_image ? [] : thumbs
      end

      def extract_description
        if has_css?('#productDescription .content')
          description = find('#productDescription .content')
        elsif has_css?('#productDescription')
          description = find('#productDescription')
        elsif has_css?('.kmd-section-container')
          description = find('.kmd-section-container', all: true)
        elsif iframe_html = page.body.match(/var iframeContent = "(.*?)";/)
          iframe_html = URI.decode(iframe_html[1]).strip
          iframe_html = Nokogiri::HTML(iframe_html)
          description = iframe_html.search("#productDescription .content")
        else
          return
        end
        { html: description.to_s.strip,
          text: description.text.strip,
          markdown: to_sanitized_markdown(description.to_s) }
      end

      def extract_ratings
        default = { average: 0, count: 0 }
        if has_css?('.reviewCountTextLinkedHistogram')
          rating  = '.reviewCountTextLinkedHistogram'
          counter = '#acrCustomerReviewText'
        elsif has_css?('#revFMSR')
          rating  = '#revFMSR a'
          counter = '#revFMSR'
        else
          return default
        end

        regex = /((?:\d+\.*)+) out of ((?:\d+\.*)+) stars/
        match = attribute_for(rating, :title).match(regex)
        return default unless match
        rating = (match[1].to_f / match[2].to_f * 100).to_i

        regex  = /((?:\d+,*)+) (?:|customer )reviews/
        match  = text_for(counter).match(regex)
        return default unless match
        counter = match[1].gsub(',', '').to_i

        { average: rating, count: counter }
      end

      def extract_categories
        selector = "#wayfinding-breadcrumbs_container li a"
        cats = sanitize_text_lines_of(selector)
        return cats if cats.any?
        [attribute_for('#addToCart #storeID', 'value').titleize]
      end

      def extract_extras
        { can_gift: has_text?("Gift-wrap available") }
      end

      private

      def __extract_currency(selector)
        return unless has_css?(selector)
        text = text_for(selector)
        text = case
               when current_uri.host =~ /\.ca$/
                 text.gsub(/^CDN\$/, 'CAD')
               when current_uri.host =~ /\.in$/
                 "INR #{text}"
               else text
               end
        text = text.split("-")[0].strip
        text.to_money
      end
    end
  end
end
