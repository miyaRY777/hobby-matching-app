require "rails_helper"

RSpec.describe "mypage/rooms 3点メニュー", type: :system, js: true do
  # セットアップ：管理中の部屋が1件だけ（メニューが枠からはみ出す条件）
  let(:current_user) { create(:user) }
  let!(:current_profile) { create(:profile, user: current_user) }
  let!(:own_room) { create(:room, issuer_profile: current_profile, label: "管理中の部屋", locked:) }

  before do
    create(:room_membership, room: own_room, profile: current_profile)
    # 招待リンクを有効にする（factory の期限は過去日付）
    create(:share_link, room: own_room, expires_at: 1.year.from_now)
    login_as(current_user, scope: :user)
    visit mypage_rooms_path
  end

  def open_room_menu
    within("tr##{ActionView::RecordIdentifier.dom_id(own_room)}") do
      find("button[aria-label='その他の操作']").click
    end
  end

  def table_wrapper_creates_vertical_scrollbar?
    page.evaluate_script(<<~JS)
      (() => {
        const wrapper = document.querySelector("#rooms_tbody").closest("div");
        const overflowY = window.getComputedStyle(wrapper).overflowY;
        return overflowY === "auto" || overflowY === "scroll";
      })()
    JS
  end

  context "公開中の部屋" do
    let(:locked) { false }

    it "3点をクリックすると非公開にすると削除が見え、テーブルに縦スクロールが出ない" do
      # 3点メニューを開く
      open_room_menu

      # メニュー項目が見えること
      expect(page).to have_link("非公開にする")
      expect(page).to have_link("削除")
      # テーブル枠が縦スクロール用の overflow になっていないこと
      expect(table_wrapper_creates_vertical_scrollbar?).to be(false)
    end
  end

  context "非公開の部屋" do
    let(:locked) { true }

    it "3点をクリックすると公開すると削除が見える" do
      # 3点メニューを開く
      open_room_menu

      # 非公開の部屋では「公開する」が出ること
      expect(page).to have_link("公開する")
      expect(page).to have_link("削除")
    end
  end
end
