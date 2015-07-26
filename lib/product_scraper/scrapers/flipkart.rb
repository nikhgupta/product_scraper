module ProductScraper
  module Scrapers
    class Flipkart < ProductScraper::BaseScraper
      def self.can_parse?(uri)
        return false unless uri.host =~ /\A(?:|www\.)flipkart\.com\z/
        uri.path =~ %r{/p/.*}
      end

      def extract_uid
        query_hash['pid'] ||
        first_of_data_for('product-id') ||
        data_for('.reviewSection', 'pid')
      end

      def extract_name
        text_for('h1.title')
      end

      def extract_priority_service
        has_css?('span.fk-advantage')
      end

      def extract_available
        !has_css?('.out-of-stock-section')
      end

      def extract_brand_name
        text_for('.seller-badge a.seller-name')
      end

      def extract_price
        __extract_currency '.pricing .selling-price'
      end

      def extract_marked_price
        __extract_currency '.pricing .price'
      end

      def extract_canonical_url
        attribute_for 'link[rel="canonical"]', :href
      end

      def extract_features
        selectors = ['ul.keyFeaturesList li', 'ul li.key-specification']
        selector  = selectors.detect { |sel| has_css?(sel) }
        sanitize_text_lines_of selector
      end

      def extract_images
        styles = attribute_for '.carousel li .thumb', 'style', all: true
        images = styles.map { |style| style.scan(/url\((.*)\)/) }.flatten
        images = images.select { |url| url =~ /(jpe?g|gif|png|bmp)$/ }
        images = images.map { |a| a.gsub(/-\d+x\d+-/, '-1100x1100-') }
      end

      def extract_description
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

      def extract_ratings
        rating = attribute_for('.ratings [itemprop="ratingValue"]', 'content')
        counter = text_for('.ratings [itemprop="ratingCount"]')
        { average: (rating.to_f * 20).round(0), count: counter.to_i }
      end

      def extract_categories
        cats = sanitize_text_lines_of('.breadcrumb-wrap ul li a')
        return if cats.empty?
        cats.shift
        cats
      end

      def extract_extras
        { specs: extract_specs }
      end

      def extract_specs
        rows = find('.productSpecs .specTable tr', all: true)
        return {} if rows.empty?
        header, data = nil, {}

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

      def __extract_currency(selector)
        return unless has_css?(selector)
        text = text_for(selector)
        text = text.gsub(/^Rs\./, 'INR')
        text.to_money
      end
    end
  end
end
