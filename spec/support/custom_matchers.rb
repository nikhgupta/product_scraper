# # FIXME: incorrectly highlights extra items in include/contain items matchers
class RSpec::Matchers::ExpectedsForMultipleDiffs
  def diffs(differ, actual)
    if actual.is_a?(Array) && @expected_list.all?{|a| a[0].is_a?(Array)}
      actual = actual.sort_by(&:to_s).map(&:inspect).join("\n")
      @expected_list = @expected_list.map{|e,dl| [e.sort_by(&:to_s).map(&:inspect).join("\n"), dl]}
    end

    @expected_list.map do |(expected, diff_label)|
      diff = differ.diff(actual, expected)
      next if diff.strip.empty?
      "#{diff_label}#{diff}"
    end.compact.join("\n")
  end
end

RSpec::Matchers.define :contain_key_pairs do |expected|
  match do |actual|
    expect(@actual).to be_a(Hash)
    if @actual.is_a?(HashWithIndifferentAccess) && expected.is_a?(Hash)
      method = expected.keys.first.is_a?(Symbol) ? :to_sym : :to_s
      @actual = Hash[@actual.map{|k,v| [k.send(method),v]}]
      @actual = @actual.select{|k,v| expected.keys.include?(k)}
    end
    expect(@actual).to eq(expected)
  end
  diffable

  failure_message do |actual|
    "expected it to #{description}"
  end

  failure_message_when_negated do |actual|
    "expected it not to #{description}"
  end

  description do
    return "be a Hash" unless @actual.is_a?(Hash)
    "contain the following key value pairs:"
  end
end
RSpec::Matchers.define :contain_items do |expected|
  match do |actual|
    @old_actual = actual
    @actual = key ? actual[key] : actual
    expect(@actual).to be_a(Array)
    @actual -= (@actual - expected)
    expect(@actual).to eq(expected)
  end
  chain :for_key, :key
  diffable

  failure_message do |actual|
    "expected it to #{description}"
  end

  failure_message_when_negated do |actual|
    "expected it not to #{description}"
  end

  description do
    return "be an array#{key ? " for key #{key.inspect}" : ":"}" unless @actual.is_a?(Array)
    message = "contain the following items#{key ? " for key #{key.inspect}" : ":"}"
    expected.count == 1 ? "#{message}\n- #{expected[0]}" : message
  end
end
