require "rails_helper"

RSpec.describe Profile, type: :model do
  it "has room-related associations" do
    expect(described_class.reflect_on_association(:room_memberships).macro).to eq(:has_many)
    expect(described_class.reflect_on_association(:joined_rooms).macro).to eq(:has_many)
    expect(described_class.reflect_on_association(:issued_rooms).macro).to eq(:has_many)
  end

  describe "hobbies_text バリデーション（JSON形式）" do
    let(:profile) { build(:profile) }

    it "10個以下のタグは有効" do
      profile.hobbies_text = (1..10).map { |i| { name: "タグ#{i}", description: "" } }.to_json
      expect(profile).to be_valid
    end

    it "11個以上のタグは無効" do
      profile.hobbies_text = (1..11).map { |i| { name: "タグ#{i}", description: "" } }.to_json
      expect(profile).not_to be_valid
      expect(profile.errors[:hobbies_text]).to be_present
    end

    it "新規作成時に hobbies_textが未設定の場合は無効" do
      profile.hobbies_text = nil
      expect(profile).not_to be_valid
      expect(profile.errors[:hobbies_text]).to include("は1つ以上のタグを追加してください")
    end
  end

  describe "bio バリデーション" do
    it "bio が空だと無効" do
      profile = build(:profile, bio: "")

      expect(profile).not_to be_valid
      expect(profile.errors[:bio]).to include("を入力してください")
    end
  end

  describe "hobbies_text の必須バリデーション" do
    it "新規作成時に hobbies_text が空だと無効" do
      profile = build(:profile)
      profile.hobbies_text = ""

      expect(profile).not_to be_valid
      expect(profile.errors[:hobbies_text]).to include("は1つ以上のタグを追加してください")
    end

    it "新規作成時に hobbies_text が空配列だと無効" do
      profile = build(:profile)
      profile.hobbies_text = [].to_json

      expect(profile).not_to be_valid
      expect(profile.errors[:hobbies_text]).to include("は1つ以上のタグを追加してください")
    end

    it "更新時に hobbies_text が空配列だと無効" do
      profile = create(:profile)
      profile.hobbies_text = [].to_json

      expect(profile).not_to be_valid
      expect(profile.errors[:hobbies_text]).to include("は1つ以上のタグを追加してください")
    end
  end

  describe "#update_hobbies_from_json" do
    it "JSONからhobbyを作成/取得しdescriptionを保存する" do
      profile = create(:profile)
      old = create(:hobby, name: "old")
      create(:profile_hobby, profile:, hobby: old)

      profile.update_hobbies_from_json([ { name: "rails", description: "好き" }, { name: "ruby", description: "" } ].to_json)

      expect(profile.hobbies.pluck(:name)).to match_array(%w[rails ruby])
      ph = profile.profile_hobbies.joins(:hobby).find_by(hobbies: { name: "rails" })
      expect(ph.description).to eq("好き")
    end

    it "空JSONなら hobbies を空にする（全削除）" do
      profile = create(:profile)
      create(:profile_hobby, profile:, hobby: create(:hobby, name: "rails"))

      profile.update_hobbies_from_json([].to_json)

      expect(profile.hobbies).to be_empty
    end

    it "既存の Hobby は再利用する（件数が増えすぎない）" do
      profile = create(:profile)
      create(:hobby, name: "rails")

      expect { profile.update_hobbies_from_json([ { name: "rails", description: "" } ].to_json) }
        .not_to change(Hobby, :count)

      expect(profile.hobbies.pluck(:name)).to eq([ "rails" ])
    end
  end
end
