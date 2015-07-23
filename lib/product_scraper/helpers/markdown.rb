module ProductScraper::Helpers::Markdown
  def to_sanitized_markdown(html)
    conditions = {
      remove_contents: %w[script style],
      allow_doctype: Sanitize::Config::RELAXED[:allow_doctype],
      attributes: Sanitize::Config::RELAXED[:attributes],
      protocols: Sanitize::Config::RELAXED[:protocols],
      elements: %w[
        b em i strong u a blockquote abbr br code kbd li ol ul
          p pre small sub sup h1 h2 h3 h4 h5 h6 hr
      ],
    }
    html = Sanitize.fragment(html, conditions)
    html = html.gsub(/\n+\s+/, "\n\n").gsub(/\#/, '\#').strip
    to_markdown(html)
  end

  def to_markdown(html)
    ReverseMarkdown
      .convert(html)                        # convert HTML to Markdown
      .gsub(/^#+\s*$/, '')                  # remove all empty heading markers
      .gsub(/\n+/, "\n\n")                  # remove unnecessary linebreaks
      .gsub(/^\s+/, '')                     # remove unnecessary whitespace
      .gsub(/^#/, "\n#")                    # add linebreak before a heading
      .gsub(/^(-.*)\n([^-])/, "\\1\n\n\\2") # add linebreak after list
      .strip                                # strip the resulting Markdown
  end
end
