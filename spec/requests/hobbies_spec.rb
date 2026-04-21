require "rails_helper"

RSpec.describe "Hobbies", type: :request do
  let(:user) { create(:user) }

  describe "GET /hobbies/autocomplete" do
    context "未ログイン" do
      it "ログインページへリダイレクトする" do
        get autocomplete_hobbies_path, params: { q: "ア" }
        expect(response).to have_http_status(:found)
      end
    end

    context "ログイン済み" do
      before { sign_in user }

      it "qが2文字未満のとき空配列を返す" do
        create(:hobby, name: "アニメ")
        get autocomplete_hobbies_path, params: { q: "ア" }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq([])
      end

      it "qが空のとき空配列を返す" do
        get autocomplete_hobbies_path, params: { q: "" }
        expect(JSON.parse(response.body)).to eq([])
      end

      it "前方一致する候補を返す" do
        create(:hobby, name: "アニメ")
        create(:hobby, name: "アウトドア")
        create(:hobby, name: "野球")
        get autocomplete_hobbies_path, params: { q: "アニ" }
        expect(JSON.parse(response.body)).to eq([
          { "name" => "アニメ", "parent_tag_name" => nil, "room_type" => nil }
        ])
      end

      it "最大10件まで返す" do
        11.times { |i| create(:hobby, name: "アニメ#{i.to_s.rjust(2, '0')}") }
        get autocomplete_hobbies_path, params: { q: "アニメ" }
        expect(JSON.parse(response.body).size).to eq(10)
      end

      it "親タグが紐づいている hobby は parent_tag_name と room_type を返す" do
        programming = create(:parent_tag, name: "プログラミング", slug: "programming", room_type: :study)
        rails_hobby = create(:hobby, name: "Rails")
        create(:hobby_parent_tag, hobby: rails_hobby, parent_tag: programming)

        get autocomplete_hobbies_path, params: { q: "Rai" }

        expect(JSON.parse(response.body)).to eq([
          { "name" => "Rails", "parent_tag_name" => "プログラミング", "room_type" => "study" }
        ])
      end

      it "大文字で入力しても normalized_name で前方一致する" do
        create(:hobby, name: "Rails")

        get autocomplete_hobbies_path, params: { q: "RAIL" }

        expect(JSON.parse(response.body).map { |hobby| hobby["name"] }).to include("Rails")
      end

      it "一致しないqは空配列を返す" do
        create(:hobby, name: "アニメ")
        get autocomplete_hobbies_path, params: { q: "ゲーム" }
        expect(JSON.parse(response.body)).to eq([])
      end
    end
  end
end
