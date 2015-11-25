module ProductScraper
  module Scrapers
    class Flipkart < ProductScraper::BaseScraper

      product  { |uri| uri.path =~ %r{/.*?/p/.*} }
      host     { |uri| uri.host =~ /\A(?:|www\.)flipkart\.com\z/ }
      set_uuid { |uri| uri.path.match(%r{/.+/p/(.*)(?:/|$)})[1] }

      def pid
        query_hash['pid'] ||
        first_of_data_for('product-id') ||
        data_for('.reviewSection', 'pid')
      end

      def name
        text_for('h1.title')
      end

      def priority_service
        has_css?('span.fk-advantage')
      end

      def available
        !has_css?('.out-of-stock-section')
      end

      def brand_name
        text_for('.seller-badge a.seller-name')
      end

      def price
        __currency '.pricing .selling-price'
      end

      def marked_price
        __currency '.pricing .price'
      end

      def canonical_url
        attribute_for 'link[rel="canonical"]', :href
      end

      def features
        selectors = ['ul.keyFeaturesList li', 'ul li.key-specification']
        selector  = selectors.detect { |sel| has_css?(sel) }
        sanitize_text_lines_of selector
      end

      def images
        styles = attribute_for '.carousel li .thumb', 'style', all: true
        images = styles.map { |style| style.scan(/url\((.*)\)/) }.flatten
        images = images.select { |url| url =~ /(jpe?g|gif|png|bmp)$/ }
        images = images.map { |a| a.gsub(/-\d+x\d+-/, '-original-') }
      end

      def description
        selector = ['[data-ctrl="RichProductDescription"]',
                    '.description.specSection'].detect do |sel|
          has_css?(sel) && !text_for(sel).empty?
        end

        return { html: nil, text: nil, markdown: nil } unless selector
        description = find selector
        { html: description.to_s.strip,
          text: description.text.strip,
          markdown: to_sanitized_markdown(description.to_s) }
      end

      def ratings
        rating = attribute_for('.ratings [itemprop="ratingValue"]', 'content')
        counter = text_for('.ratings [itemprop="ratingCount"]')
        { average: (rating.to_f * 20).round(0), count: counter.to_i }
      end

      def categories
        cats = sanitize_text_lines_of('.breadcrumb-wrap ul li a')
        return [] if cats.empty?
        cats.shift
        cats
      end

      def extras
        { specs: specs }
      end

      def specs
        rows = find('.productSpecs .specTable tr', all: true)
        return {} if rows.empty?
        header, data = nil, {}; nil    # appending nil is fasterer

        rows.map do |row|
          row.search('td,th').map do |cell|
            cell.text.strip
          end
        end.each do |row|
          case
          when row.count == 1
            header = row[0].to_s.parameterize('_')
            header = 'miscelleneous' if header.strip.empty?
          when row[0].strip.empty?
            data[header] ||= {}
            data[header]['other_features'] ||= []
            data[header]['other_features'] << row[1]
          when row.count == 2
            data[header] ||= {}
            data[header][row[0].parameterize('_')] = row[1]
          end
        end

        data
      end

      private

      def __currency(selector)
        return unless has_css?(selector)
        text = text_for(selector)
        text = text.gsub(/^Rs\./, 'INR')
        text.to_money
      end
    end
  end
end
