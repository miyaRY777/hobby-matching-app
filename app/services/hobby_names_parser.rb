class HobbyNamesParser
  def self.call(raw)
    raw.to_s
       .split(",")
       .map(&:strip)
       .reject(&:blank?)
       .uniq
  end
end
