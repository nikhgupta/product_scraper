module ProductScraper::Helpers::Attributes

  def attribute_for(selector, attribute, options = {})
    after_find(selector, options) { |el| el.attr(attribute).strip }
  end

  def data_for(selector, name, options = {})
    attribute_for(selector, "data-#{name}", options)
  end

  def first_of_data_for(name)
    data_for("[data-#{name}]", name)
  end

  def text_for(selector, options = {})
    after_find(selector, options) { |el| el.text.strip }
  end

  def sanitize_text_lines_of(selector, options = {}, &block)
    options = options.merge(all: true).except(:each_line)
    lines = text_for(selector, options)
    lines = lines.map {|line| yield line} if block_given?
    lines.compact.map(&:strip).uniq.reject{|a| a.strip.empty?}
  end

  def has_text?(text)
    page.body.include?(text)
  end
end
