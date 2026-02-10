require "rails_helper"

RSpec.describe HobbyNamesParser do
  describe ".call" do
    it "カンマ区切りで分割して配列で返す" do
      expect(described_class.call("rails,ruby,php")).to eq(%w[rails ruby php])
    end

    it "各タグの前後の空白を除去する" do
      expect(described_class.call(" rails , ruby ")).to eq(%w[rails ruby])
    end

    it "空要素（空文字）を除外する" do
      expect(described_class.call("rails,, ,ruby")).to eq(%w[rails ruby])
    end

    it "同じタグが複数あっても1つにまとめる" do
      expect(described_class.call("rails,rails,ruby")).to eq(%w[rails ruby])
    end

    it "空文字・空白・nilのときは空配列を返す（全て未入力扱い）" do
      expect(described_class.call("")).to eq([])
      expect(described_class.call(" ")).to eq([])
      expect(described_class.call(nil)).to eq([])
    end
  end
end
