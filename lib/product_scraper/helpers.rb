module ProductScraper; end
module ProductScraper; module Helpers; end; end
Dir[Pathname.new(__FILE__).dirname.join("helpers", "*.rb")].each{|f| require f}

module ProductScraper::Helpers
  include Selector
  include Markdown
  include Attributes
  include Capybara

  attr_accessor :page

  def get url
    if js?
      agent.visit url
      self.page = Nokogiri::HTML(agent.html)
    else
      self.page = agent.get url
      page.encoding = 'utf-8'
    end
  end

  def current_uri
    js? ? URI.parse(agent.current_url) : page.uri
  end

  def current_url
    current_uri.to_s
  end

  def absolute_url(path)
    return if path.blank?
    prefix = "#{current_uri.scheme}://#{current_uri.host}"
    path.starts_with?("/") ? "#{prefix}#{path}" : path
  end

  def status_code
    js? ? agent.status_code.to_i : page.code.to_i
  end

  def query_hash
    query = current_uri.query.split('&').map do |part|
      (part.split('=') << "" << "").first(2)
    end
    Hash[query]
  end

  def agent
    if js?
      self.class.include ProductScraper::Helpers::Capybara
      @agent ||= new_session
    else
      @agent ||= Mechanize.new{ |a| a.user_agent_alias = 'Mac Safari' }
    end
  end
end
