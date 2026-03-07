require "rails_helper"

RSpec.describe ProfileSearchQuery do
  let(:user_taro)  { create(:user, nickname: "たろう") }
  let(:user_hanako) { create(:user, nickname: "はなこ") }
  let(:user_jiro)  { create(:user, nickname: "じろう") }

  let(:profile_taro)   { create(:profile, user: user_taro) }
  let(:profile_hanako) { create(:profile, user: user_hanako) }
  let(:profile_jiro)   { create(:profile, user: user_jiro) }

  let(:hobby_game)    { create(:hobby, name: "ゲーム") }
  let(:hobby_fishing) { create(:hobby, name: "釣り") }
  let(:hobby_reading) { create(:hobby, name: "読書") }

  before do
    # たろう：ゲーム・釣り
    create(:profile_hobby, profile: profile_taro, hobby: hobby_game)
    create(:profile_hobby, profile: profile_taro, hobby: hobby_fishing)

    # はなこ：ゲーム・読書
    create(:profile_hobby, profile: profile_hanako, hobby: hobby_game)
    create(:profile_hobby, profile: profile_hanako, hobby: hobby_reading)

    # じろう：釣り
    create(:profile_hobby, profile: profile_jiro, hobby: hobby_fishing)
  end

  describe ".call" do
    subject(:result) { described_class.call(params) }

    context "条件が空の場合" do
      let(:params) { { q: "", mode: "and" } }

      it "全プロフィールを返す" do
        expect(result).to match_array([ profile_taro, profile_hanako, profile_jiro ])
      end
    end

    context "趣味タグ1件でAND検索の場合" do
      let(:params) { { q: "ゲーム", mode: "and" } }

      it "ゲームを持つプロフィールを返す" do
        expect(result).to match_array([ profile_taro, profile_hanako ])
      end
    end

    context "趣味タグ複数件でAND検索の場合" do
      let(:params) { { q: "ゲーム,釣り", mode: "and" } }

      it "ゲームと釣りを両方持つプロフィールを返す" do
        expect(result).to match_array([ profile_taro ])
      end
    end

    context "趣味タグ複数件でOR検索の場合" do
      let(:params) { { q: "ゲーム,釣り", mode: "or" } }

      it "ゲームまたは釣りを持つプロフィールを返す" do
        expect(result).to match_array([ profile_taro, profile_hanako, profile_jiro ])
      end
    end

    context "nicknameのみでAND検索の場合" do
      let(:params) { { q: "たろう", mode: "and" } }

      it "nicknameが部分一致するプロフィールを返す" do
        expect(result).to match_array([ profile_taro ])
      end
    end

    context "趣味タグとnicknameでAND検索の場合" do
      let(:params) { { q: "ゲーム,たろう", mode: "and" } }

      it "ゲームを持ちかつnicknameが一致するプロフィールを返す" do
        expect(result).to match_array([ profile_taro ])
      end
    end

    context "趣味タグとnicknameでOR検索の場合" do
      let(:params) { { q: "読書,たろう", mode: "or" } }

      it "読書を持つまたはnicknameが一致するプロフィールを返す" do
        expect(result).to match_array([ profile_taro, profile_hanako ])
      end
    end

    context "一致するプロフィールが存在しない場合" do
      let(:params) { { q: "存在しない趣味", mode: "and" } }

      it "空のコレクションを返す" do
        expect(result).to be_empty
      end
    end
  end
end
