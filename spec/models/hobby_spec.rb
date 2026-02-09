# frozen_string_literal: true
require "rails_helper"

RSpec.describe Hobby, type: :model do
  describe "バリデーション" do
    it "name が空だと無効になる" do
      hobby = described_class.new(name: nil)
      expect(hobby).to be_invalid
    end

    it "同じ name は重複して保存できない" do
      described_class.create!(name: "rails")
      hobby = described_class.new(name: "rails")
      expect(hobby).to be_invalid
    end
  end
end
