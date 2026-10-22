# config/initializers/debug_json_warning.rb (temporary)
module Warning
  def self.warn(message, category: nil, **)
    if message.include?("UTF-8 string passed as BINARY")
      message += caller.reject { |l| l.include?("/gems/json-") }.first(15).join("\n") + "\n"
    end
    super(message, **(category ? { category: category } : {}))
  end
end