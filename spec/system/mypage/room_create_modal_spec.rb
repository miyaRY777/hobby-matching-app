require "rails_helper"

RSpec.describe "mypage/rooms 作成モーダル", type: :system, js: true do
  # セットアップ：プロフィール済みユーザーでログイン
  let(:current_user) { create(:user) }
  let!(:current_profile) { create(:profile, user: current_user) }

  before do
    # ログインして部屋管理ページへ
    login_as(current_user, scope: :user)
    visit mypage_rooms_path
  end

  it "「+ 新規作成」ボタンが表示されている" do
    # モーダルトリガーボタンが存在すること
    expect(page).to have_button("+ 新規作成")
  end

  it "ボタンをクリックするとモーダルが開く" do
    # ボタンをクリック
    click_button "+ 新規作成"

    # モーダルパネルが visible になること
    expect(page).to have_css("[data-testid='room-create-modal']", visible: true)
  end

  it "× ボタンをクリックするとモーダルが閉じる" do
    # モーダルを開く
    click_button "+ 新規作成"

    # × ボタンをクリック
    find("[data-testid='room-create-modal-close']").click

    # モーダルが非表示になること
    expect(page).to have_css("[data-testid='room-create-modal']", visible: false)
  end

  it "ESC キーでモーダルが閉じる" do
    # モーダルを開く
    click_button "+ 新規作成"

    # ESC キーを押す
    find("body").send_keys(:escape)

    # モーダルが非表示になること
    expect(page).to have_css("[data-testid='room-create-modal']", visible: false)
  end

  it "オーバーレイクリックでモーダルが閉じる" do
    # モーダルを開く
    click_button "+ 新規作成"

    # オーバーレイをJSで直接クリック
    find("[data-testid='room-create-modal-backdrop']").execute_script("this.click()")

    # モーダルが非表示になること
    expect(page).to have_css("[data-testid='room-create-modal']", visible: false)
  end

  it "バリデーションエラー時はモーダルが開いたままエラーが表示される" do
    # モーダルを開く
    click_button "+ 新規作成"

    # 部屋名を空にして送信（バリデーションエラーを発生させる）
    within("[data-testid='room-create-modal']") do
      fill_in "room[label]", with: ""
      click_button "部屋を作成"
    end

    # モーダルが開いたままエラーメッセージが表示されること
    expect(page).to have_css("[data-testid='room-create-modal']", visible: true)
    expect(page).to have_text("部屋名")
  end

  it "作成成功後にモーダルが閉じてテーブルに新行が追加される" do
    # 初期状態でテーブルに行がないこと
    expect(page).not_to have_css("table td", text: "テストルーム")

    # モーダルを開いてフォームに入力
    click_button "+ 新規作成"
    within("[data-testid='room-create-modal']") do
      fill_in "room[label]", with: "テストルーム"
      click_button "部屋を作成"
    end

    # モーダルが閉じること
    expect(page).to have_css("[data-testid='room-create-modal']", visible: false)

    # テーブルに新しい部屋が追加されること
    expect(page).to have_css("table td", text: "テストルーム")
  end
end
