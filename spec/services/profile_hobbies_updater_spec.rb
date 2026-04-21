require "rails_helper"

RSpec.describe ProfileHobbiesUpdater do
  describe ".call" do
    let(:profile) { create(:profile) }

    it "新規タグを追加しdescriptionを保存する" do
      described_class.call(profile, [ { name: "ruby", description: "3年やってます" } ])

      ph = profile.profile_hobbies.joins(:hobby).find_by(hobbies: { name: "ruby" })
      expect(ph).not_to be_nil
      expect(ph.description).to eq("3年やってます")
    end

    it "既存タグのdescriptionを更新する" do
      hobby = create(:hobby, name: "ruby")
      create(:profile_hobby, profile:, hobby:, description: "古い説明")

      described_class.call(profile, [ { name: "ruby", description: "新しい説明" } ])

      ph = profile.profile_hobbies.joins(:hobby).find_by(hobbies: { name: "ruby" })
      expect(ph.description).to eq("新しい説明")
    end

    it "削除されたタグのprofile_hobbyを削除する" do
      hobby = create(:hobby, name: "rails")
      create(:profile_hobby, profile:, hobby:)

      described_class.call(profile, [ { name: "ruby", description: "" } ])

      expect(profile.hobbies.pluck(:name)).to match_array([ "ruby" ])
    end

    it "既存Hobbyを再利用する（Hobby件数が増えない）" do
      create(:hobby, name: "ruby")

      expect { described_class.call(profile, [ { name: "ruby", description: "" } ]) }
        .not_to change(Hobby, :count)
    end

    it "タグ名をdowncaseで正規化して保存する" do
      described_class.call(profile, [ { name: "Ruby", description: "" } ])

      expect(profile.hobbies.pluck(:name)).to include("ruby")
    end

    it "重複タグは1件のみ保存する" do
      described_class.call(profile, [
        { name: "ruby", description: "最初" },
        { name: "ruby", description: "2回目" }
      ])

      expect(profile.profile_hobbies.joins(:hobby).where(hobbies: { name: "ruby" }).count).to eq(1)
    end

    it "空のタグデータで全削除される" do
      hobby = create(:hobby, name: "ruby")
      create(:profile_hobby, profile:, hobby:)

      described_class.call(profile, [])

      expect(profile.hobbies).to be_empty
    end

    it "全角英字を半角に正規化して既存hobbyを再利用する" do
      hobby = create(:hobby, name: "rails")

      described_class.call(profile, [ { name: "Ｒａｉｌｓ", description: "" } ])

      expect(profile.hobbies).to include(hobby)
      expect(Hobby.count).to eq(1)
    end

    it "normalized_name が nil の既存 hobby も再利用する" do
      hobby = create(:hobby, name: "ゲーム")
      hobby.update_columns(normalized_name: nil)

      expect {
        described_class.call(profile, [ { name: "ゲーム", description: "対戦が好き" } ])
      }.not_to raise_error

      ph = profile.profile_hobbies.joins(:hobby).find_by(hobbies: { id: hobby.id })
      expect(ph.description).to eq("対戦が好き")
      expect(Hobby.where(name: "ゲーム").count).to eq(1)
    end

    context "新規 hobby の parent_tags" do
      it "辞書にない新規タグは hobby_parent_tags を持たない（未分類）" do
        described_class.call(profile, [ { name: "brandnewtag", description: "" } ])

        hobby = Hobby.find_by(normalized_name: "brandnewtag")
        expect(hobby).not_to be_nil
        expect(hobby.hobby_parent_tags).to be_empty
      end

      it "normalized_name で削除対象を判定する" do
        hobby_rails = create(:hobby, name: "rails")
        hobby_ruby = create(:hobby, name: "ruby")
        create(:profile_hobby, profile:, hobby: hobby_rails)
        create(:profile_hobby, profile:, hobby: hobby_ruby)

        described_class.call(profile, [ { name: "rails", description: "" } ])

        expect(profile.hobbies.pluck(:name)).to eq([ "rails" ])
      end
    end

    context "既存 hobby の分類は維持する" do
      it "既存の hobby_parent_tags は変更しない" do
        programming = ParentTag.find_or_create_by!(slug: "programming", room_type: 1) { |pt| pt.name = "プログラミング"; pt.position = 0 }
        hobby = create(:hobby, name: "rails")
        create(:hobby_parent_tag, hobby:, parent_tag: programming)

        described_class.call(profile, [ { name: "rails", description: "" } ])

        expect(hobby.reload.hobby_parent_tags.find_by(room_type: :study)&.parent_tag).to eq(programming)
      end
    end

    context "parent_tag_id の処理" do
      let(:programming) do
        create(:parent_tag, name: "プログラミング", slug: "programming", room_type: :study)
      end

      it "新規タグ + 有効な parent_tag_id では HobbyParentTag が作成される" do
        described_class.call(profile, [ { name: "newlang", description: "", parent_tag_id: programming.id } ])

        hobby = Hobby.find_by(normalized_name: "newlang")
        expect(hobby.hobby_parent_tags.find_by(room_type: :study)&.parent_tag).to eq(programming)
      end

      it "既存の未分類タグに parent_tag_id を渡しても HobbyParentTag は作成されない" do
        create(:hobby, name: "existingtag")

        described_class.call(profile, [ { name: "existingtag", description: "", parent_tag_id: programming.id } ])

        hobby = Hobby.find_by(normalized_name: "existingtag")
        expect(hobby.hobby_parent_tags).to be_empty
      end

      it "既存の分類済みタグに別の parent_tag_id を渡しても分類は変更されない" do
        game_tag = create(:parent_tag, name: "FPS", slug: "fps", room_type: :game)
        hobby = create(:hobby, name: "apex")
        create(:hobby_parent_tag, hobby:, parent_tag: game_tag)

        described_class.call(profile, [ { name: "apex", description: "", parent_tag_id: programming.id } ])

        expect(hobby.reload.hobby_parent_tags.find_by(room_type: :game)&.parent_tag).to eq(game_tag)
        expect(hobby.hobby_parent_tags.find_by(room_type: :study)).to be_nil
      end

      it "不正な parent_tag_id でも保存は成功する" do
        expect {
          described_class.call(profile, [ { name: "sometag", description: "", parent_tag_id: 99_999 } ])
        }.not_to raise_error

        hobby = Hobby.find_by(normalized_name: "sometag")
        expect(hobby).not_to be_nil
        expect(hobby.hobby_parent_tags).to be_empty
      end

      it "parent_tag_id が nil のときは HobbyParentTag を作成しない" do
        described_class.call(profile, [ { name: "unknowntag", description: "", parent_tag_id: nil } ])

        hobby = Hobby.find_by(normalized_name: "unknowntag")
        expect(hobby.hobby_parent_tags).to be_empty
      end
    end

    context "削除対象の判定" do
      it "normalized_name で削除対象を判定する" do
        hobby_rails = create(:hobby, name: "rails")
        hobby_ruby  = create(:hobby, name: "ruby")
        create(:profile_hobby, profile:, hobby: hobby_rails)
        create(:profile_hobby, profile:, hobby: hobby_ruby)

        described_class.call(profile, [ { name: "rails", description: "" } ])

        expect(profile.hobbies.pluck(:name)).to eq([ "rails" ])
      end
    end
  end
end
