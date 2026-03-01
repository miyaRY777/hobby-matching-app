require "rails_helper"

RSpec.describe "Profiles index overflow", type: :system, js: true do
  it "長い改行なし文字列によって横方向のはみ出し（横スクロール）が発生しないこと" do
    long = "https://example.com/" + ("a" * 500)

    # プロフィール作成し、一覧ページに移行
    url = "https://example.com/"
    long = url + ("a" * (500 - url.length))

    create(:profile, bio: long)
    visit profiles_path

    # 画面幅によるブレを減らしたい場合（任意）
    page.driver.browser.manage.window.resize_to(1400, 900)

    overflow = page.evaluate_script(<<~JS)
      document.documentElement.scrollWidth > document.documentElement.clientWidth
    JS

    expect(overflow).to be(false)
  end
end
