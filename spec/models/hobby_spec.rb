require "rails_helper"

RSpec.describe Hobby, type: :model do
  it "name がないと無効" do
    hobby = described_class.new(name: nil)
    expect(hobby).not_to be_valid
  end

  it "name はユニーク" do
    described_class.create!(name: "rails")
    dup = described_class.new(name: "rails")
    expect(dup).not_to be_valid
  end
end
