require "rails_helper"

RSpec.describe "Loading states", type: :system, js: true do
  let(:user) { create(:user) }

  before do
    login_as(user, scope: :user)
    visit profiles_path
  end

  it "検索結果フレームの更新イベントに応じて部分ローディングを表示・解除する" do
    expect(hidden?("[data-testid='profile-list-loading']")).to be(true)

    page.execute_script(<<~JS)
      const form = document.querySelector("form[data-controller='profile-search']")
      const controller = window.Stimulus.getControllerForElementAndIdentifier(form, "profile-search")
      controller.showLoading()
    JS

    expect(hidden?("[data-testid='profile-list-loading']")).to be(false)

    page.execute_script(<<~JS)
      const form = document.querySelector("form[data-controller='profile-search']")
      const controller = window.Stimulus.getControllerForElementAndIdentifier(form, "profile-search")
      controller.hideLoading()
    JS

    expect(hidden?("[data-testid='profile-list-loading']")).to be(true)
  end

  def hidden?(selector)
    page.evaluate_script(<<~JS)
      (() => {
        const element = document.querySelector(#{selector.to_json})
        return element.hidden
      })()
    JS
  end
end
