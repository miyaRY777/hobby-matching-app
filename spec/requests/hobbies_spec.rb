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
        expect(JSON.parse(response.body)).to eq([ "アニメ" ])
      end

      it "最大10件まで返す" do
        11.times { |i| create(:hobby, name: "アニメ#{i.to_s.rjust(2, '0')}") }
        get autocomplete_hobbies_path, params: { q: "アニメ" }
        expect(JSON.parse(response.body).size).to eq(10)
      end

      it "一致しないqは空配列を返す" do
        create(:hobby, name: "アニメ")
        get autocomplete_hobbies_path, params: { q: "ゲーム" }
        expect(JSON.parse(response.body)).to eq([])
      end
    end
  end
end
