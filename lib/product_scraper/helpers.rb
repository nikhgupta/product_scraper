module ProductScraper; end
module ProductScraper; module Helpers; end; end
Dir[Pathname.new(__FILE__).dirname.join("helpers", "*.rb")].each{|f| require f}

module ProductScraper::Helpers
  include Selector
  include Markdown
  include Attributes

  attr_reader :page

  def get url
    @page = agent.get url
  end

  def current_uri
    page.uri
  end

  def current_url
    current_uri.to_s
  end

  def absolute_url(path)
    return if path.blank?
    prefix = "#{current_uri.scheme}://#{current_uri.host}"
    path.starts_with?("/") ? "#{prefix}#{path}" : path
  end

  def query_hash
    query = current_uri.query.split('&').map do |part|
      (part.split('=') << "" << "").first(2)
    end
    Hash[query]
  end

  def agent
    @agent ||= Mechanize.new do |a|
      a.user_agent_alias = 'Mac Safari'
    end
  end
end
