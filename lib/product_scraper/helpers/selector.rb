module ProductScraper::Helpers::Selector

  # Find the first element matching the given selector.
  #
  # Options:
  # - all (default: false): find all elements, instead.
  #
  def find(selector, options = {})
    els = selector ? page.search(selector, options.except(:all)) : []
    options[:all] ? els : els.first
  end

  # Find first element that matches the given selector,
  # and has `locator` as its ID or text.
  def with_locator(selector, locator)
    with_id  = find("#{selector}##{locator}")
    with_id || find(selector, all: true).detect { |el| el.text.strip == locator }
  end

  # Check if the page has an element with given selector.
  def has_css?(selector)
    !find(selector).nil?
  end

  def visible_in(selectors)
    selectors.select{|selector| has_css?(selector)}
  end

  # Check if the page has a link with given ID or text.
  def has_link?(locator)
    !with_locator('a', locator).nil?
  end

  def after_find(selector, options, &block)
    results  = find(selector, options)
    multiple = results.respond_to?(:length)
    results  = [results].flatten(1).compact.map { |result| yield(result) }
    multiple ? results : results.first
  end
end
